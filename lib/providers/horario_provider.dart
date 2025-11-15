import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/academic_service.dart' as academic_service;
import '../models/horario.dart';
import '../models/clase_del_dia.dart';
import '../models/user.dart'; // Para PaginationInfo
import '../models/conflict_error.dart';

enum HorarioState {
  initial,
  loading,
  loaded,
  error,
}

class HorarioProvider with ChangeNotifier {
  final academic_service.AcademicService _academicService = academic_service.AcademicService();

  HorarioState _state = HorarioState.initial;
  String? _errorMessage;
  ConflictError? _conflictError;
  List<Horario> _horarios = [];
  List<ClaseDelDia> _clasesDelDia = [];
  List<ClaseDelDia> _horarioSemanal = [];
  Horario? _selectedHorario;
  String? _selectedGrupoId;
  String? _selectedPeriodoId;
  PaginationInfo? _paginationInfo;

  // Scroll infinito
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  // Getters
  HorarioState get state => _state;
  String? get errorMessage => _errorMessage;
  ConflictError? get conflictError => _conflictError;
  List<Horario> get horarios => _horarios;
  List<ClaseDelDia> get clasesDelDia => _clasesDelDia;
  List<ClaseDelDia> get horarioSemanal => _horarioSemanal;
  Horario? get selectedHorario => _selectedHorario;
  String? get selectedGrupoId => _selectedGrupoId;
  String? get selectedPeriodoId => _selectedPeriodoId;
  PaginationInfo? get paginationInfo => _paginationInfo;

  bool get isLoading => _state == HorarioState.loading;
  bool get hasError => _state == HorarioState.error;
  bool get isLoaded => _state == HorarioState.loaded;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;

  // Computed properties
  List<Horario> get horariosActivos => _horarios.where((horario) => horario.periodoAcademico.activo).toList();

  /// 🔧 NUEVO: Devuelve SOLO los horarios del grupo seleccionado
  /// Utilizado para renderizar la grilla (grid de horarios)
  /// Mientras que _horarios contiene TODOS los horarios del período (para detectar conflictos)
  List<Horario> get horariosDelGrupoSeleccionado {
    if (_selectedGrupoId == null) return [];
    return _horarios.where((h) => h.grupo.id == _selectedGrupoId).toList();
  }

  // Número de horarios actualmente cargados en memoria (página actual)
  int get loadedHorariosCount => _horarios.length;
  int get clasesDelDiaCount => _clasesDelDia.length;
  int get horarioSemanalCount => _horarioSemanal.length;

  /// Número total de horarios reportado por la paginación del backend
  int get totalHorariosFromPagination => _paginationInfo?.total ?? 0;

  void _setState(HorarioState newState, [String? error]) {
    _state = newState;
    _errorMessage = error;
    // Limpiar el error de conflicto cuando cambie el estado
    if (newState != HorarioState.error) {
      _conflictError = null;
    }
    notifyListeners();
  }

  /// Carga todos los horarios con paginación y filtros
  Future<void> loadHorarios(String accessToken, {int? page, int? limit, String? grupoId, String? periodoId}) async {
    if (_state == HorarioState.loading) return;

    _setState(HorarioState.loading);
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('HorarioProvider: Iniciando carga de horarios...');
      final response = await _academicService.getHorarios(
        accessToken,
        page: page ?? 1,
        limit: limit,
        grupoId: grupoId,
        periodoId: periodoId,
      );
      if (response != null) {
        debugPrint('HorarioProvider: Recibidos ${response.horarios.length} horarios');
        _horarios = response.horarios;
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        _setState(HorarioState.loaded);
        debugPrint('HorarioProvider: Estado cambiado a loaded');
      } else {
        _setState(HorarioState.error, 'Error al cargar horarios');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading horarios: $e');
      _setState(HorarioState.error, e.toString());
    }
  }

  /// Carga horarios por grupo específico
  Future<void> loadHorariosByGrupo(String accessToken, String grupoId) async {
    if (_state == HorarioState.loading) return;

    _setState(HorarioState.loading);
    _selectedGrupoId = grupoId;

    try {
      debugPrint('HorarioProvider: Iniciando carga de horarios por grupo $grupoId...');
      final horarios = await _academicService.getHorariosPorGrupo(accessToken, grupoId);
      if (horarios != null) {
        debugPrint('HorarioProvider: Recibidos ${horarios.length} horarios del grupo $grupoId');
        _horarios = horarios;
        _hasMoreData = false; // No hay paginación para este endpoint específico
        _setState(HorarioState.loaded);
      } else {
        _setState(HorarioState.error, 'Error al cargar horarios del grupo');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading horarios by grupo: $e');
      _setState(HorarioState.error, e.toString());
    }
  }

  /// Carga horarios del grupo Y TODOS los horarios del período (para detectar conflictos)
  /// Sin sobrescribirse entre sí
  Future<void> loadHorariosForGrupoWithConflictDetection(
    String accessToken,
    String grupoId,
    String periodoId,
  ) async {
    if (_state == HorarioState.loading) return;

    _setState(HorarioState.loading);
    _selectedGrupoId = grupoId;
    _selectedPeriodoId = periodoId;

    try {
      debugPrint('HorarioProvider: Cargando horarios para grupo $grupoId y período $periodoId...');

      // Cargar ambas solicitudes en paralelo
      final grupoHorariosTask = _academicService.getHorariosPorGrupo(accessToken, grupoId);
      final periodHorariosTask = _academicService.getHorarios(
        accessToken,
        page: 1,
        limit: 100, // 🔧 Máximo permitido por el backend
        periodoId: periodoId,
      );

      final grupoHorarios = await grupoHorariosTask;
      final periodResponse = await periodHorariosTask;

      if (grupoHorarios != null && periodResponse != null) {
        debugPrint('HorarioProvider: Recibidos ${grupoHorarios.length} horarios del grupo');
        debugPrint('HorarioProvider: Recibidos ${periodResponse.horarios.length} horarios del período');

        // IMPORTANTE: Usar TODOS los horarios del período para detectar conflictos
        // Pero mantener una referencia al grupo para la pantalla
        _horarios = periodResponse.horarios;
        _selectedGrupoId = grupoId; // Guardar el grupo seleccionado
        _paginationInfo = periodResponse.pagination;
        _hasMoreData = false;
        _setState(HorarioState.loaded);

        debugPrint('HorarioProvider: Total horarios en memoria: ${_horarios.length}');
      } else {
        _setState(HorarioState.error, 'Error al cargar horarios');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading horarios with conflict detection: $e');
      _setState(HorarioState.error, e.toString());
    }
  }

  /// Carga un horario específico por ID
  Future<void> loadHorarioById(String accessToken, String horarioId) async {
    _setState(HorarioState.loading);

    try {
      final horario = await _academicService.getHorarioById(accessToken, horarioId);
      if (horario != null) {
        _selectedHorario = horario;
        _setState(HorarioState.loaded);
      } else {
        _setState(HorarioState.error, 'Horario no encontrado');
      }
    } catch (e) {
      debugPrint('Error loading horario: $e');
      _setState(HorarioState.error, e.toString());
    }
  }

  /// Crea un nuevo horario
  Future<bool> createHorario(String accessToken, academic_service.CreateHorarioRequest horarioData) async {
    _setState(HorarioState.loading);

    try {
      final newHorario = await _academicService.createHorario(accessToken, horarioData);
      if (newHorario != null) {
        // Agregar el nuevo horario a la lista
        _horarios.insert(0, newHorario);
        _setState(HorarioState.loaded);
        return true;
      } else {
        _setState(HorarioState.error, 'Error al crear horario');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating horario: $e');
      final errorString = e.toString();

      // Verificar si es un error de conflicto (HTTP 409)
      if (errorString.contains('409') || errorString.contains('Conflict')) {
        _conflictError = ConflictError.fromBackendError(errorString);
        _setState(HorarioState.error, _conflictError!.userFriendlyMessage);
      } else {
        _setState(HorarioState.error, errorString);
      }
      return false;
    }
  }

  /// Actualiza un horario existente
  Future<bool> updateHorario(String accessToken, String horarioId, academic_service.UpdateHorarioRequest horarioData) async {
    _setState(HorarioState.loading);

    try {
      final updatedHorario = await _academicService.updateHorario(accessToken, horarioId, horarioData);
      if (updatedHorario != null) {
        // Actualizar el horario en la lista
        final index = _horarios.indexWhere((horario) => horario.id == horarioId);
        if (index != -1) {
          _horarios[index] = updatedHorario;
        }

        // Actualizar el horario seleccionado si es el mismo
        if (_selectedHorario?.id == horarioId) {
          _selectedHorario = updatedHorario;
        }

        _setState(HorarioState.loaded);
        return true;
      } else {
        _setState(HorarioState.error, 'Error al actualizar horario');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating horario: $e');
      final errorString = e.toString();

      // Verificar si es un error de conflicto (HTTP 409)
      if (errorString.contains('409') || errorString.contains('Conflict')) {
        _conflictError = ConflictError.fromBackendError(errorString);
        _setState(HorarioState.error, _conflictError!.userFriendlyMessage);
      } else {
        _setState(HorarioState.error, errorString);
      }
      return false;
    }
  }

  /// Elimina un horario
  Future<bool> deleteHorario(String accessToken, String horarioId) async {
    // Este método ya no gestionará el estado de la lista.
    // La pantalla se encargará de solicitar la recarga, que sí gestiona el estado.
    try {
      final success = await _academicService.deleteHorario(accessToken, horarioId);

      if (!success) {
        // Guardamos el mensaje de error para que la UI pueda mostrarlo.
        _errorMessage = 'Error al eliminar el horario desde el servicio.';
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting horario: $e');
      _errorMessage = e.toString();
      return false;
    }
  }

  /// MÉTODO CLAVE: Carga las clases del día actual para el profesor
  Future<void> cargarClasesDelDia(String accessToken) async {
    _setState(HorarioState.loading);

    try {
      debugPrint('HorarioProvider: Cargando clases del día para el profesor...');
      final clases = await _academicService.getMisClasesDelDia(accessToken);
      if (clases != null) {
        debugPrint('HorarioProvider: Recibidas ${clases.length} clases del día');
        _clasesDelDia = clases;
        _setState(HorarioState.loaded);
      } else {
        _setState(HorarioState.error, 'Error al cargar clases del día');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading clases del dia: $e');
      _setState(HorarioState.error, e.toString());
    }
  }

  /// Carga las clases de un día específico para el profesor
  Future<void> cargarClasesPorDia(String accessToken, int diaSemana) async {
    _setState(HorarioState.loading);

    try {
      debugPrint('HorarioProvider: Cargando clases del día $diaSemana para el profesor...');
      final clases = await _academicService.getMisClasesPorDia(accessToken, diaSemana);
      if (clases != null) {
        debugPrint('HorarioProvider: Recibidas ${clases.length} clases del día $diaSemana');
        _clasesDelDia = clases;
        _setState(HorarioState.loaded);
      } else {
        _setState(HorarioState.error, 'Error al cargar clases del día específico');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading clases por dia: $e');
      _setState(HorarioState.error, e.toString());
    }
  }

  /// Carga el horario semanal completo del profesor
  Future<void> cargarHorarioSemanal(String accessToken) async {
    _setState(HorarioState.loading);

    try {
      debugPrint('HorarioProvider: Cargando horario semanal para el profesor...');
      final horario = await _academicService.getMiHorarioSemanal(accessToken);
      if (horario != null) {
        debugPrint('HorarioProvider: Recibido horario semanal con ${horario.length} clases');
        _horarioSemanal = horario;
        _setState(HorarioState.loaded);
      } else {
        _setState(HorarioState.error, 'Error al cargar horario semanal');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading horario semanal: $e');
      _setState(HorarioState.error, e.toString());
    }
  }

  /// Selecciona un horario para edición
  void selectHorario(Horario horario) {
    _selectedHorario = horario;
    notifyListeners();
  }

  /// Limpia el horario seleccionado
  void clearSelectedHorario() {
    _selectedHorario = null;
    notifyListeners();
  }

  /// Limpia todos los datos
  void clearData() {
    _horarios = [];
    _clasesDelDia = [];
    _horarioSemanal = [];
    _selectedHorario = null;
    _selectedGrupoId = null;
    _selectedPeriodoId = null;
    _paginationInfo = null;
    _setState(HorarioState.initial);
  }

  /// Recarga los datos (útil después de operaciones)
  Future<void> refreshData(String accessToken) async {
    if (_selectedGrupoId != null) {
      await loadHorariosByGrupo(accessToken, _selectedGrupoId!);
    } else {
      await loadHorarios(accessToken);
    }
  }

  /// Busca horarios por materia o grupo
  List<Horario> searchHorarios(String query) {
    if (query.isEmpty) return _horarios;

    final lowercaseQuery = query.toLowerCase();
    return _horarios.where((horario) {
      return horario.materia.nombre.toLowerCase().contains(lowercaseQuery) ||
             horario.grupo.nombre.toLowerCase().contains(lowercaseQuery) ||
             horario.descripcion.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Filtra horarios por día de la semana
  List<Horario> filterHorariosByDia(int diaSemana) {
    return _horarios.where((horario) => horario.diaSemana == diaSemana).toList();
  }

  /// Filtra clases del día por hora
  List<ClaseDelDia> getClasesDelDiaOrdenadas() {
    return _clasesDelDia..sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
  }

  /// Filtra horario semanal por día
  List<ClaseDelDia> getHorarioPorDia(int diaSemana) {
    return _horarioSemanal.where((clase) => clase.diaSemana == diaSemana).toList()
      ..sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
  }

  /// Carga la siguiente página de horarios
  Future<void> loadNextPage(String accessToken) async {
    if (_paginationInfo == null || !_paginationInfo!.hasNext || _state == HorarioState.loading) return;

    final nextPage = _paginationInfo!.page + 1;
    if (_selectedGrupoId != null) {
      await loadHorariosByGrupo(accessToken, _selectedGrupoId!);
    } else {
      await loadHorarios(accessToken, page: nextPage, limit: _paginationInfo!.limit);
    }
  }

  /// Carga la página anterior de horarios
  Future<void> loadPreviousPage(String accessToken) async {
    if (_paginationInfo == null || !_paginationInfo!.hasPrev || _state == HorarioState.loading) return;

    final prevPage = _paginationInfo!.page - 1;
    await loadHorarios(accessToken, page: prevPage, limit: _paginationInfo!.limit);
  }

  /// Carga una página específica
  Future<void> loadPage(String accessToken, int page) async {
    if (_state == HorarioState.loading) return;

    await loadHorarios(accessToken, page: page, limit: _paginationInfo?.limit ?? 10);
  }

  /// Obtiene estadísticas de horarios
  Map<String, int> getHorariosStatistics() {
    return {
      'total': _paginationInfo?.total ?? 0,
      'activos': horariosActivos.length,
      'clases_hoy': _clasesDelDia.length,
      'horario_semanal': _horarioSemanal.length,
    };
  }

  /// Carga más horarios para scroll infinito (append)
  Future<void> loadMoreHorarios(String accessToken, {String? grupoId, String? periodoId}) async {
    if (_isLoadingMore || !_hasMoreData || _paginationInfo == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _paginationInfo!.page + 1;

      final response = await _academicService.getHorarios(
        accessToken,
        page: nextPage,
        limit: _paginationInfo!.limit,
        grupoId: grupoId,
        periodoId: periodoId,
      );

      if (response != null) {
        _horarios.addAll(response.horarios); // Agregar al final de la lista
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        debugPrint('HorarioProvider: Cargados ${response.horarios.length} horarios más. Total ahora: ${_horarios.length}');
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading more horarios: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Reinicia la paginación para scroll infinito
  void resetPagination() {
    _hasMoreData = true;
    _isLoadingMore = false;
  }

  /// Obtiene profesores disponibles para un horario específico
  /// Sin conflictos en ese día y hora
  List<User> getProfesoresDisponibles(
    List<User> allProfesors,
    int diaSemana,
    String horaInicio,
    String horaFin,
  ) {
    final profesoresConConflicto = <String>{};

    // Convertir horas a minutos
    final inicioMinutos = _timeToMinutes(horaInicio);
    final finMinutos = _timeToMinutes(horaFin);

    // Encontrar profesores con conflictos
    for (final horario in _horarios) {
      if (horario.diaSemana == diaSemana && horario.profesor != null) {
        final hInicio = _timeToMinutes(horario.horaInicio);
        final hFin = _timeToMinutes(horario.horaFin);

        // Hay conflicto si se solapan los horarios
        if (inicioMinutos < hFin && finMinutos > hInicio) {
          profesoresConConflicto.add(horario.profesor!.id);
        }
      }
    }

    // Retornar solo los profesores sin conflictos
    return allProfesors.where((profesor) => !profesoresConConflicto.contains(profesor.id)).toList();
  }

  /// Convierte una hora en formato HH:MM a minutos
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

}