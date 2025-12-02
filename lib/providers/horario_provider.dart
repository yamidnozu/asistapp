import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pagination_types.dart';
import '../services/academic/horario_service.dart';
import '../models/horario.dart';
import 'paginated_data_mixin.dart';
import '../models/clase_del_dia.dart';
import '../models/user.dart'; // Para PaginationInfo
import '../models/conflict_error.dart';

// HorarioState removed; rely on PaginatedDataMixin's isLoading/hasError/isLoaded

class HorarioProvider extends ChangeNotifier with PaginatedDataMixin<Horario> {
  final HorarioService _horarioService;

  HorarioProvider({HorarioService? horarioService})
      : _horarioService = horarioService ?? HorarioService();

  // error and errorMessage delegated to PaginatedDataProvider
  ConflictError? _conflictError;
  // Horarios list is stored in PaginatedDataProvider.items (base class)
  List<ClaseDelDia> _clasesDelDia = [];
  List<ClaseDelDia> _horarioSemanal = [];
  Horario? _selectedHorario;
  String? _selectedGrupoId;
  String? _selectedPeriodoId;
  // pagination handled by PaginatedDataProvider for paginated endpoints
  // pagination handled by PaginatedDataProvider for paginated endpoints
  // For endpoints that return all results (no pagination) we will use
  // the base provider helpers setHasMoreData / setPaginationInfo.

  // Getters
  // Use PaginatedDataProvider's errorMessage
  ConflictError? get conflictError => _conflictError;
  List<Horario> get horarios => items;
  List<ClaseDelDia> get clasesDelDia => _clasesDelDia;
  List<ClaseDelDia> get horarioSemanal => _horarioSemanal;
  Horario? get selectedHorario => _selectedHorario;
  String? get selectedGrupoId => _selectedGrupoId;
  String? get selectedPeriodoId => _selectedPeriodoId;
  // Use base paginationInfo

  // Delegated to PaginatedDataProvider - use base implementation
  // Use base isLoadingMore / hasMoreData

  // Computed properties
  List<Horario> get horariosActivos => items.where((horario) => horario.periodoAcademico.activo).toList();

  /// 🔧 NUEVO: Devuelve SOLO los horarios del grupo seleccionado
  /// Utilizado para renderizar la grilla (grid de horarios)
  /// Mientras que _horarios contiene TODOS los horarios del período (para detectar conflictos)
  List<Horario> get horariosDelGrupoSeleccionado {
  if (_selectedGrupoId == null) return [];
  return items.where((h) => h.grupo.id == _selectedGrupoId).toList();
  }

  // Número de horarios actualmente cargados en memoria (página actual)
  int get loadedHorariosCount => items.length;
  int get clasesDelDiaCount => _clasesDelDia.length;
  int get horarioSemanalCount => _horarioSemanal.length;

  /// Número total de horarios reportado por la paginación del backend
  int get totalHorariosFromPagination => paginationInfo?.total ?? 0;

  // Legacy state removed: rely on base isLoading/hasError/isLoaded

  /// Carga todos los horarios con paginación y filtros
  Future<void> loadHorarios(String accessToken, {int? page, int? limit, String? grupoId, String? periodoId}) async {
  if (isLoading) return;
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('HorarioProvider: Iniciando carga de horarios...');
      await loadItems(accessToken, page: page ?? 1, limit: limit, filters: {
        if (grupoId != null) 'grupoId': grupoId,
        if (periodoId != null) 'periodoId': periodoId,
      });
      if (hasError) {
        setError(errorMessage ?? 'Error al cargar horarios');
      } else {
        debugPrint('HorarioProvider: Recibidos ${items.length} horarios');
        notifyListeners();
        debugPrint('HorarioProvider: Estado cambiado a loaded');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading horarios: $e');
  setError(e.toString());
    }
  }

  @override
  Future<PaginatedResponse<Horario>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final grupoId = filters?['grupoId'];
    final periodoId = filters?['periodoId'];

    final response = await _horarioService.getHorarios(accessToken, page: page, limit: limit, grupoId: grupoId, periodoId: periodoId);
    if (response == null) return null;
    return PaginatedResponse(items: response.horarios, pagination: response.pagination);
  }

  @override
  Future<Horario?> createItemApi(String accessToken, dynamic data) async {
    final created = await _horarioService.createHorario(accessToken, data as CreateHorarioRequest);
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _horarioService.deleteHorario(accessToken, id);
  }

  @override
  Future<Horario?> updateItemApi(String accessToken, String id, dynamic data) async {
    final updated = await _horarioService.updateHorario(accessToken, id, data as UpdateHorarioRequest);
    return updated;
  }

  /// Carga horarios por grupo específico
  Future<void> loadHorariosByGrupo(String accessToken, String grupoId) async {
  if (isLoading) return;
    _selectedGrupoId = grupoId;

    try {
      debugPrint('HorarioProvider: Iniciando carga de horarios por grupo $grupoId...');
      final horarios = await _horarioService.getHorariosPorGrupo(accessToken, grupoId);
      if (horarios != null) {
      debugPrint('HorarioProvider: Recibidos ${horarios.length} horarios del grupo $grupoId');
  clearItems();
  items.addAll(horarios);
      // No hay paginación para este endpoint específico: señalamos
      // al proveedor base que no hay más datos.
      setHasMoreData(false);
  notifyListeners();
      } else {
  setError('Error al cargar horarios del grupo');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading horarios by grupo: $e');
  setError(e.toString());
    }
  }

  /// Carga horarios del grupo Y TODOS los horarios del período (para detectar conflictos)
  /// Sin sobrescribirse entre sí
  Future<void> loadHorariosForGrupoWithConflictDetection(
    String accessToken,
    String grupoId,
    String periodoId,
  ) async {
  if (isLoading) return;
    _selectedGrupoId = grupoId;
    _selectedPeriodoId = periodoId;

    try {
      debugPrint('HorarioProvider: Cargando horarios para grupo $grupoId y período $periodoId...');

      // Cargar ambas solicitudes en paralelo
      final grupoHorariosTask = _horarioService.getHorariosPorGrupo(accessToken, grupoId);
      final periodHorariosTask = _horarioService.getHorarios(
        accessToken,
        page: 1,
        limit: 100, // 🔧 Máximo permitido por el backend
        periodoId: periodoId,
      );

      final grupoHorarios = await grupoHorariosTask;
      final periodResponse = await periodHorariosTask;

  if (periodResponse != null) {
    debugPrint('HorarioProvider: Recibidos ${grupoHorarios?.length ?? 0} horarios del grupo');
        debugPrint('HorarioProvider: Recibidos ${periodResponse.horarios.length} horarios del período');

        // IMPORTANTE: Usar TODOS los horarios del período para detectar conflictos
        // Pero mantener una referencia al grupo para la pantalla
    // Importante: mantener la paginación del período en el base provider
    clearItems();
    items.addAll(periodResponse.horarios);
    setPaginationInfo(periodResponse.pagination);
        _selectedGrupoId = grupoId; // Guardar el grupo seleccionado
  // pagination info is set by loadItems() above when we loaded the period page
  notifyListeners();

  debugPrint('HorarioProvider: Total horarios en memoria: ${items.length}');
      } else {
  setError('Error al cargar horarios');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading horarios with conflict detection: $e');
  setError(e.toString());
    }
  }

  /// Carga un horario específico por ID
  Future<void> loadHorarioById(String accessToken, String horarioId) async {
  if (isLoading) return;

    try {
      final horario = await _horarioService.getHorarioById(accessToken, horarioId);
      if (horario != null) {
        _selectedHorario = horario;
  notifyListeners();
      } else {
  setError('Horario no encontrado');
      }
    } catch (e) {
      debugPrint('Error loading horario: $e');
  setError(e.toString());
    }
  }

  /// Crea un nuevo horario
  Future<bool> createHorario(String accessToken, CreateHorarioRequest horarioData) async {
  if (isLoading) return false;

    try {
      final newHorario = await _horarioService.createHorario(accessToken, horarioData);
      if (newHorario != null) {
        // Agregar el nuevo horario a la lista
  items.insert(0, newHorario);
  notifyListeners();
        return true;
      } else {
  // Intentar recargar los horarios del grupo para mantener consistencia en UI
  try {
    if (horarioData.grupoId != null) {
      await loadHorariosByGrupo(accessToken, horarioData.grupoId);
    }
  } catch (_) {}
  setError('Error al crear horario');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating horario: $e');
      final errorString = e.toString();

      // Verificar si es un error de conflicto (HTTP 409)
      if (errorString.contains('409') || errorString.contains('Conflict')) {
  _conflictError = ConflictError.fromBackendError(errorString);
  setError(_conflictError!.userFriendlyMessage);
      } else {
  setError(errorString);
      }
      return false;
    }
  }

  /// Actualiza un horario existente
  Future<bool> updateHorario(String accessToken, String horarioId, UpdateHorarioRequest horarioData) async {
  if (isLoading) return false;

    try {
      final updatedHorario = await _horarioService.updateHorario(accessToken, horarioId, horarioData);
      if (updatedHorario != null) {
        // Actualizar el horario en la lista
  final index = items.indexWhere((horario) => horario.id == horarioId);
        if (index != -1) {
          items[index] = updatedHorario;
        }

        // Actualizar el horario seleccionado si es el mismo
        if (_selectedHorario?.id == horarioId) {
          _selectedHorario = updatedHorario;
        }

  notifyListeners();
        return true;
      } else {
  setError('Error al actualizar horario');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating horario: $e');
      final errorString = e.toString();

      // Verificar si es un error de conflicto (HTTP 409)
      if (errorString.contains('409') || errorString.contains('Conflict')) {
        _conflictError = ConflictError.fromBackendError(errorString);
        setError(_conflictError!.userFriendlyMessage);
      } else {
        setError(errorString);
      }
      return false;
    }
  }

  /// Elimina un horario
  Future<bool> deleteHorario(String accessToken, String horarioId) async {
    // Este método ya no gestionará el estado de la lista.
    // La pantalla se encargará de solicitar la recarga, que sí gestiona el estado.
    try {
      final success = await _horarioService.deleteHorario(accessToken, horarioId);

      if (!success) {
        // Guardamos el mensaje de error para que la UI pueda mostrarlo.
    setError('Error al eliminar el horario desde el servicio.');
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting horario: $e');
  setError(e.toString());
      return false;
    }
  }

  /// MÉTODO CLAVE: Carga las clases del día actual para el profesor
  Future<void> cargarClasesDelDia(String accessToken) async {
  if (isLoading) return;

    try {
      debugPrint('HorarioProvider: Cargando clases del día para el profesor...');
      final clases = await _horarioService.getMisClasesDelDia(accessToken);
      if (clases != null) {
        debugPrint('HorarioProvider: Recibidas ${clases.length} clases del día');
        _clasesDelDia = clases;
  notifyListeners();
      } else {
  setError('Error al cargar clases del día');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading clases del dia: $e');
  setError(e.toString());
    }
  }

  /// Carga las clases de un día específico para el profesor
  Future<void> cargarClasesPorDia(String accessToken, int diaSemana) async {
  if (isLoading) return;

    try {
      debugPrint('HorarioProvider: Cargando clases del día $diaSemana para el profesor...');
      final clases = await _horarioService.getMisClasesPorDia(accessToken, diaSemana);
      if (clases != null) {
        debugPrint('HorarioProvider: Recibidas ${clases.length} clases del día $diaSemana');
        _clasesDelDia = clases;
  notifyListeners();
      } else {
  setError('Error al cargar clases del día específico');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading clases por dia: $e');
  setError(e.toString());
    }
  }

  /// Carga el horario semanal completo del profesor
  Future<void> cargarHorarioSemanal(String accessToken) async {
  if (isLoading) return;

    try {
      debugPrint('HorarioProvider: Cargando horario semanal para el profesor...');
      final horario = await _horarioService.getMiHorarioSemanal(accessToken);
      if (horario != null) {
        debugPrint('HorarioProvider: Recibido horario semanal con ${horario.length} clases');
        _horarioSemanal = horario;
  notifyListeners();
      } else {
    setError('Error al cargar horario semanal');
      }
    } catch (e) {
      debugPrint('HorarioProvider: Error loading horario semanal: $e');
  setError(e.toString());
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
  clearItems();
    _clasesDelDia = [];
    _horarioSemanal = [];
    _selectedHorario = null;
    _selectedGrupoId = null;
    _selectedPeriodoId = null;
  // clearItems() resets paginationInfo in base class
  clearError();
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
  if (query.isEmpty) return items;

    final lowercaseQuery = query.toLowerCase();
  return items.where((horario) {
      return horario.materia.nombre.toLowerCase().contains(lowercaseQuery) ||
             horario.grupo.nombre.toLowerCase().contains(lowercaseQuery) ||
             horario.descripcion.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Filtra horarios por día de la semana
  List<Horario> filterHorariosByDia(int diaSemana) {
  return items.where((horario) => horario.diaSemana == diaSemana).toList();
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
  @override
  Future<void> loadNextPage(String accessToken, {Map<String, String>? filters}) async {
  if (paginationInfo == null || !paginationInfo!.hasNext || isLoading) return;

  final nextPage = paginationInfo!.page + 1;
    if (_selectedGrupoId != null) {
      await loadHorariosByGrupo(accessToken, _selectedGrupoId!);
    } else {
  await loadHorarios(accessToken, page: nextPage, limit: paginationInfo!.limit);
    }
  }

  /// Carga la página anterior de horarios
  Future<void> loadPreviousPage(String accessToken) async {
  if (paginationInfo == null || !paginationInfo!.hasPrev || isLoading) return;

  final prevPage = paginationInfo!.page - 1;
  await loadHorarios(accessToken, page: prevPage, limit: paginationInfo!.limit);
  }

  /// Carga una página específica
  Future<void> loadPage(String accessToken, int page) async {
  if (isLoading) return;

  await loadHorarios(accessToken, page: page, limit: paginationInfo?.limit ?? 10);
  }

  /// Obtiene estadísticas de horarios
  Map<String, int> getHorariosStatistics() {
    return {
  'total': paginationInfo?.total ?? 0,
      'activos': horariosActivos.length,
      'clases_hoy': _clasesDelDia.length,
      'horario_semanal': _horarioSemanal.length,
    };
  }

  /// Carga más horarios para scroll infinito (append)
  Future<void> loadMoreHorarios(String accessToken, {String? grupoId, String? periodoId}) async {
    if (isLoadingMore || !hasMoreData || paginationInfo == null) return;

    // Set filters
    if (grupoId != null) {
      setFilter('grupoId', grupoId);
    }
    if (periodoId != null) {
      setFilter('periodoId', periodoId);
    }

    await super.loadNextPage(accessToken);
  }

  /// Reinicia la paginación para scroll infinito
  @override
  void resetPagination() {
    super.resetPagination();
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
  for (final horario in items) {
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