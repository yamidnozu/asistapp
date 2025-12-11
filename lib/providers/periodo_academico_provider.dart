import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pagination_types.dart';
import '../services/academic/periodo_service.dart';
import '../models/grupo.dart'; // Para PeriodoAcademico
import 'paginated_data_mixin.dart';

// PeriodoAcademicoState removed: rely on PaginatedDataMixin state

class PeriodoAcademicoProvider extends ChangeNotifier
    with PaginatedDataMixin<PeriodoAcademico> {
  final PeriodoService _periodoService;

  PeriodoAcademicoProvider({PeriodoService? periodoService})
      : _periodoService = periodoService ?? PeriodoService();

  // Error handling delegated to PaginatedDataProvider

  // Items are stored in PaginatedDataProvider._items
  PeriodoAcademico? _selectedPeriodo;

  // Getters
  // Use PaginatedDataProvider's errorMessage
  List<PeriodoAcademico> get periodosAcademicos => items;
  PeriodoAcademico? get selectedPeriodo => _selectedPeriodo;
  // Use base paginationInfo from PaginatedDataProvider

  // Delegated to PaginatedDataProvider - use base implementation

  // Computed properties
  List<PeriodoAcademico> get periodosActivos =>
      items.where((periodo) => periodo.activo).toList();
  List<PeriodoAcademico> get periodosInactivos =>
      items.where((periodo) => !periodo.activo).toList();

  /// Número de períodos actualmente cargados en memoria
  int get loadedPeriodosCount => items.length;
  int get periodosActivosCount => periodosActivos.length;
  int get periodosInactivosCount => periodosInactivos.length;

  /// Número total de períodos reportado por la paginación del backend
  int get totalPeriodosFromPagination => paginationInfo?.total ?? 0;

  // _setState removed; use base provider setError/notifyListeners

  /// Carga todos los períodos académicos con paginación
  Future<void> loadPeriodosAcademicos(String accessToken,
      {int? page, int? limit, String? search}) async {
    if (isLoading) return;

    try {
      debugPrint(
          'PeriodoAcademicoProvider: Iniciando carga de períodos académicos...');
      await loadItems(accessToken,
          page: page ?? 1, limit: limit, search: search);
      notifyListeners();
    } catch (e) {
      debugPrint(
          'PeriodoAcademicoProvider: Error loading períodos académicos: $e');
      setError(e.toString());
    }
  }

  /// Carga períodos académicos activos
  Future<void> loadPeriodosActivos(String accessToken) async {
    if (isLoading) return;

    try {
      debugPrint(
          'PeriodoAcademicoProvider: Iniciando carga de períodos activos...');
      final periodos = await _periodoService.getPeriodosActivos(accessToken);
      if (periodos != null) {
        debugPrint(
            'PeriodoAcademicoProvider: Recibidos ${periodos.length} períodos activos');
        clearItems();
        items.addAll(periodos);
        notifyListeners();
      } else {
        setError('Error al cargar períodos activos');
      }
    } catch (e) {
      debugPrint(
          'PeriodoAcademicoProvider: Error loading períodos activos: $e');
      setError(e.toString());
    }
  }

  /// Carga un período académico específico por ID
  Future<void> loadPeriodoById(String accessToken, String periodoId) async {
    if (isLoading) return;

    try {
      final periodo =
          await _periodoService.getPeriodoAcademicoById(accessToken, periodoId);
      if (periodo != null) {
        _selectedPeriodo = periodo;
        notifyListeners();
      } else {
        setError('Período académico no encontrado');
      }
    } catch (e) {
      debugPrint('Error loading período académico: $e');
      setError(e.toString());
    }
  }

  /// Crea un nuevo período académico
  Future<bool> createPeriodoAcademico(
      String accessToken, CreatePeriodoAcademicoRequest periodoData) async {
    if (isLoading) return false;

    try {
      final newPeriodo = await _periodoService.createPeriodoAcademico(
          accessToken, periodoData);
      if (newPeriodo != null) {
        // Agregar el nuevo período a la lista
        items.insert(0, newPeriodo);
        notifyListeners();
        return true;
      } else {
        setError('Error al crear período académico');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating período académico: $e');
      setError(e.toString());
      return false;
    }
  }

  /// Actualiza un período académico existente
  Future<bool> updatePeriodoAcademico(String accessToken, String periodoId,
      UpdatePeriodoAcademicoRequest periodoData) async {
    if (isLoading) return false;

    try {
      final updatedPeriodo = await _periodoService.updatePeriodoAcademico(
          accessToken, periodoId, periodoData);
      if (updatedPeriodo != null) {
        // Actualizar el período en la lista
        final index = items.indexWhere((periodo) => periodo.id == periodoId);
        if (index != -1) {
          items[index] = updatedPeriodo;
        }

        // Actualizar el período seleccionado si es el mismo
        if (_selectedPeriodo?.id == periodoId) {
          _selectedPeriodo = updatedPeriodo;
        }

        notifyListeners();
        return true;
      } else {
        setError('Error al actualizar período académico');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating período académico: $e');
      setError(e.toString());
      return false;
    }
  }

  /// Elimina un período académico
  Future<bool> deletePeriodoAcademico(
      String accessToken, String periodoId) async {
    try {
      final success =
          await _periodoService.deletePeriodoAcademico(accessToken, periodoId);

      if (!success) {
        setError('Error al eliminar el período académico desde el servicio.');
      } else {
        // Remover el período de la lista
        items.removeWhere((periodo) => periodo.id == periodoId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting período académico: $e');
      setError(e.toString());
      return false;
    }
  }

  /// Activa/desactiva un período académico
  Future<bool> togglePeriodoStatus(String accessToken, String periodoId) async {
    try {
      final updatedPeriodo =
          await _periodoService.togglePeriodoStatus(accessToken, periodoId);

      if (updatedPeriodo != null) {
        // Actualizar el período en la lista
        final index = items.indexWhere((periodo) => periodo.id == periodoId);
        if (index != -1) {
          items[index] = updatedPeriodo;
        }

        // Actualizar el período seleccionado si es el mismo
        if (_selectedPeriodo?.id == periodoId) {
          _selectedPeriodo = updatedPeriodo;
        }

        notifyListeners();
        return true;
      } else {
        setError('Error al cambiar el status del período académico');
        return false;
      }
    } catch (e) {
      debugPrint('Error toggling período status: $e');
      setError(e.toString());
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
    clearItems();
    _selectedPeriodo = null;
    // clearItems() above resets paginationInfo in base class
    clearError();
  }

  /// Recarga los datos (útil después de operaciones)
  Future<void> refreshData(String accessToken) async {
    await loadPeriodosAcademicos(accessToken);
  }

  /// Busca períodos académicos por nombre
  List<PeriodoAcademico> searchPeriodos(String query) {
    if (query.isEmpty) return items;

    final lowercaseQuery = query.toLowerCase();
    return items.where((periodo) {
      return periodo.nombre.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Filtra períodos por estado (activo/inactivo)
  List<PeriodoAcademico> filterPeriodosByStatus({bool? activo}) {
    if (activo == null) return items;
    return items.where((periodo) => periodo.activo == activo).toList();
  }

  /// Carga la siguiente página de períodos
  @override
  Future<void> loadNextPage(String accessToken,
      {Map<String, String>? filters}) async {
    if (paginationInfo == null || !paginationInfo!.hasNext || isLoading) return;

    final nextPage = paginationInfo!.page + 1;
    await loadPeriodosAcademicos(accessToken,
        page: nextPage, limit: paginationInfo!.limit);
  }

  /// Carga la página anterior de períodos
  Future<void> loadPreviousPage(String accessToken) async {
    if (paginationInfo == null || !paginationInfo!.hasPrev || isLoading) return;

    final prevPage = paginationInfo!.page - 1;
    await loadPeriodosAcademicos(accessToken,
        page: prevPage, limit: paginationInfo!.limit);
  }

  /// Carga una página específica
  Future<void> loadPage(String accessToken, int page) async {
    if (isLoading) return;

    await loadPeriodosAcademicos(accessToken,
        page: page, limit: paginationInfo?.limit ?? 10);
  }

  @override
  Future<PaginatedResponse<PeriodoAcademico>?> fetchPage(String accessToken,
      {int page = 1,
      int? limit,
      String? search,
      Map<String, String>? filters}) async {
    final response = await _periodoService.getPeriodosAcademicos(accessToken,
        page: page, limit: limit, search: search);
    if (response == null) return null;
    return PaginatedResponse(
        items: response.periodosAcademicos, pagination: response.pagination);
  }

  @override
  Future<PeriodoAcademico?> createItemApi(
      String accessToken, dynamic data) async {
    final created = await _periodoService.createPeriodoAcademico(
        accessToken, data as CreatePeriodoAcademicoRequest);
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _periodoService.deletePeriodoAcademico(accessToken, id);
  }

  @override
  Future<PeriodoAcademico?> updateItemApi(
      String accessToken, String id, dynamic data) async {
    final updated = await _periodoService.updatePeriodoAcademico(
        accessToken, id, data as UpdatePeriodoAcademicoRequest);
    return updated;
  }

  /// Obtiene estadísticas de períodos
  Map<String, int> getPeriodosStatistics() {
    return {
      'total': paginationInfo?.total ?? 0,
      'activos': periodosActivosCount,
      'inactivos': periodosInactivosCount,
    };
  }
}
