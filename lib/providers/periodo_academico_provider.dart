import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/academic_service.dart' as academic_service;
import '../models/grupo.dart'; // Para PeriodoAcademico
import '../models/user.dart'; // Para PaginationInfo

enum PeriodoAcademicoState {
  initial,
  loading,
  loaded,
  error,
}

class PeriodoAcademicoProvider with ChangeNotifier {
  final academic_service.AcademicService _academicService = academic_service.AcademicService();

  PeriodoAcademicoState _state = PeriodoAcademicoState.initial;
  String? _errorMessage;
  List<PeriodoAcademico> _periodosAcademicos = [];
  PeriodoAcademico? _selectedPeriodo;
  PaginationInfo? _paginationInfo;

  // Getters
  PeriodoAcademicoState get state => _state;
  String? get errorMessage => _errorMessage;
  List<PeriodoAcademico> get periodosAcademicos => _periodosAcademicos;
  PeriodoAcademico? get selectedPeriodo => _selectedPeriodo;
  PaginationInfo? get paginationInfo => _paginationInfo;

  bool get isLoading => _state == PeriodoAcademicoState.loading;
  bool get hasError => _state == PeriodoAcademicoState.error;
  bool get isLoaded => _state == PeriodoAcademicoState.loaded;

  // Computed properties
  List<PeriodoAcademico> get periodosActivos => _periodosAcademicos.where((periodo) => periodo.activo).toList();
  List<PeriodoAcademico> get periodosInactivos => _periodosAcademicos.where((periodo) => !periodo.activo).toList();

  /// Número de períodos actualmente cargados en memoria
  int get loadedPeriodosCount => _periodosAcademicos.length;
  int get periodosActivosCount => periodosActivos.length;
  int get periodosInactivosCount => periodosInactivos.length;

  /// Número total de períodos reportado por la paginación del backend
  int get totalPeriodosFromPagination => _paginationInfo?.total ?? 0;

  void _setState(PeriodoAcademicoState newState, [String? error]) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  /// Carga todos los períodos académicos con paginación
  Future<void> loadPeriodosAcademicos(String accessToken, {int? page, int? limit}) async {
    if (_state == PeriodoAcademicoState.loading) return;

    _setState(PeriodoAcademicoState.loading);

    try {
      debugPrint('PeriodoAcademicoProvider: Iniciando carga de períodos académicos...');
      final response = await _academicService.getPeriodosAcademicos(
        accessToken,
        page: page ?? 1,
        limit: limit,
      );
      if (response != null) {
        debugPrint('PeriodoAcademicoProvider: Recibidos ${response.periodosAcademicos.length} períodos');
        _periodosAcademicos = response.periodosAcademicos;
        _paginationInfo = response.pagination;
        _setState(PeriodoAcademicoState.loaded);
        debugPrint('PeriodoAcademicoProvider: Estado cambiado a loaded');
      } else {
        _setState(PeriodoAcademicoState.error, 'Error al cargar períodos académicos');
      }
    } catch (e) {
      debugPrint('PeriodoAcademicoProvider: Error loading períodos académicos: $e');
      _setState(PeriodoAcademicoState.error, e.toString());
    }
  }

  /// Carga períodos académicos activos
  Future<void> loadPeriodosActivos(String accessToken) async {
    _setState(PeriodoAcademicoState.loading);

    try {
      debugPrint('PeriodoAcademicoProvider: Iniciando carga de períodos activos...');
      final periodos = await _academicService.getPeriodosActivos(accessToken);
      if (periodos != null) {
        debugPrint('PeriodoAcademicoProvider: Recibidos ${periodos.length} períodos activos');
        _periodosAcademicos = periodos;
        _setState(PeriodoAcademicoState.loaded);
      } else {
        _setState(PeriodoAcademicoState.error, 'Error al cargar períodos activos');
      }
    } catch (e) {
      debugPrint('PeriodoAcademicoProvider: Error loading períodos activos: $e');
      _setState(PeriodoAcademicoState.error, e.toString());
    }
  }

  /// Carga un período académico específico por ID
  Future<void> loadPeriodoById(String accessToken, String periodoId) async {
    _setState(PeriodoAcademicoState.loading);

    try {
      final periodo = await _academicService.getPeriodoAcademicoById(accessToken, periodoId);
      if (periodo != null) {
        _selectedPeriodo = periodo;
        _setState(PeriodoAcademicoState.loaded);
      } else {
        _setState(PeriodoAcademicoState.error, 'Período académico no encontrado');
      }
    } catch (e) {
      debugPrint('Error loading período académico: $e');
      _setState(PeriodoAcademicoState.error, e.toString());
    }
  }

  /// Crea un nuevo período académico
  Future<bool> createPeriodoAcademico(String accessToken, academic_service.CreatePeriodoAcademicoRequest periodoData) async {
    _setState(PeriodoAcademicoState.loading);

    try {
      final newPeriodo = await _academicService.createPeriodoAcademico(accessToken, periodoData);
      if (newPeriodo != null) {
        // Agregar el nuevo período a la lista
        _periodosAcademicos.insert(0, newPeriodo);
        _setState(PeriodoAcademicoState.loaded);
        return true;
      } else {
        _setState(PeriodoAcademicoState.error, 'Error al crear período académico');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating período académico: $e');
      _setState(PeriodoAcademicoState.error, e.toString());
      return false;
    }
  }

  /// Actualiza un período académico existente
  Future<bool> updatePeriodoAcademico(String accessToken, String periodoId, academic_service.UpdatePeriodoAcademicoRequest periodoData) async {
    _setState(PeriodoAcademicoState.loading);

    try {
      final updatedPeriodo = await _academicService.updatePeriodoAcademico(accessToken, periodoId, periodoData);
      if (updatedPeriodo != null) {
        // Actualizar el período en la lista
        final index = _periodosAcademicos.indexWhere((periodo) => periodo.id == periodoId);
        if (index != -1) {
          _periodosAcademicos[index] = updatedPeriodo;
        }

        // Actualizar el período seleccionado si es el mismo
        if (_selectedPeriodo?.id == periodoId) {
          _selectedPeriodo = updatedPeriodo;
        }

        _setState(PeriodoAcademicoState.loaded);
        return true;
      } else {
        _setState(PeriodoAcademicoState.error, 'Error al actualizar período académico');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating período académico: $e');
      _setState(PeriodoAcademicoState.error, e.toString());
      return false;
    }
  }

  /// Elimina un período académico
  Future<bool> deletePeriodoAcademico(String accessToken, String periodoId) async {
    try {
      final success = await _academicService.deletePeriodoAcademico(accessToken, periodoId);

      if (!success) {
        _errorMessage = 'Error al eliminar el período académico desde el servicio.';
      } else {
        // Remover el período de la lista
        _periodosAcademicos.removeWhere((periodo) => periodo.id == periodoId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting período académico: $e');
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Activa/desactiva un período académico
  Future<bool> togglePeriodoStatus(String accessToken, String periodoId) async {
    try {
      final updatedPeriodo = await _academicService.togglePeriodoStatus(accessToken, periodoId);

      if (updatedPeriodo != null) {
        // Actualizar el período en la lista
        final index = _periodosAcademicos.indexWhere((periodo) => periodo.id == periodoId);
        if (index != -1) {
          _periodosAcademicos[index] = updatedPeriodo;
        }

        // Actualizar el período seleccionado si es el mismo
        if (_selectedPeriodo?.id == periodoId) {
          _selectedPeriodo = updatedPeriodo;
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Error al cambiar el status del período académico';
        return false;
      }
    } catch (e) {
      debugPrint('Error toggling período status: $e');
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Selecciona un período para edición
  void selectPeriodo(PeriodoAcademico periodo) {
    _selectedPeriodo = periodo;
    notifyListeners();
  }

  /// Limpia el período seleccionado
  void clearSelectedPeriodo() {
    _selectedPeriodo = null;
    notifyListeners();
  }

  /// Limpia todos los datos
  void clearData() {
    _periodosAcademicos = [];
    _selectedPeriodo = null;
    _paginationInfo = null;
    _setState(PeriodoAcademicoState.initial);
  }

  /// Recarga los datos (útil después de operaciones)
  Future<void> refreshData(String accessToken) async {
    await loadPeriodosAcademicos(accessToken);
  }

  /// Busca períodos académicos por nombre
  List<PeriodoAcademico> searchPeriodos(String query) {
    if (query.isEmpty) return _periodosAcademicos;

    final lowercaseQuery = query.toLowerCase();
    return _periodosAcademicos.where((periodo) {
      return periodo.nombre.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Filtra períodos por estado (activo/inactivo)
  List<PeriodoAcademico> filterPeriodosByStatus({bool? activo}) {
    if (activo == null) return _periodosAcademicos;
    return _periodosAcademicos.where((periodo) => periodo.activo == activo).toList();
  }

  /// Carga la siguiente página de períodos
  Future<void> loadNextPage(String accessToken) async {
    if (_paginationInfo == null || !_paginationInfo!.hasNext || _state == PeriodoAcademicoState.loading) return;

    final nextPage = _paginationInfo!.page + 1;
    await loadPeriodosAcademicos(accessToken, page: nextPage, limit: _paginationInfo!.limit);
  }

  /// Carga la página anterior de períodos
  Future<void> loadPreviousPage(String accessToken) async {
    if (_paginationInfo == null || !_paginationInfo!.hasPrev || _state == PeriodoAcademicoState.loading) return;

    final prevPage = _paginationInfo!.page - 1;
    await loadPeriodosAcademicos(accessToken, page: prevPage, limit: _paginationInfo!.limit);
  }

  /// Carga una página específica
  Future<void> loadPage(String accessToken, int page) async {
    if (_state == PeriodoAcademicoState.loading) return;

    await loadPeriodosAcademicos(accessToken, page: page, limit: _paginationInfo?.limit ?? 10);
  }

  /// Obtiene estadísticas de períodos
  Map<String, int> getPeriodosStatistics() {
    return {
      'total': _paginationInfo?.total ?? 0,
      'activos': periodosActivosCount,
      'inactivos': periodosInactivosCount,
    };
  }
}