import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pagination_types.dart';
import '../services/academic/materia_service.dart';
import '../models/materia.dart';
import 'paginated_data_mixin.dart';

// MateriaState removed: rely on PaginatedDataMixin state

class MateriaProvider extends ChangeNotifier with PaginatedDataMixin<Materia> {
  final MateriaService _materiaService;

  MateriaProvider({MateriaService? materiaService})
      : _materiaService = materiaService ?? MateriaService();

  // Error message delegated to PaginatedDataProvider
  Materia? _selectedMateria;


  // Getters
  // Use PaginatedDataProvider's errorMessage
  List<Materia> get materias => items;
  Materia? get selectedMateria => _selectedMateria;
  // Delegated to PaginatedDataProvider - use base implementation
  // Use PaginatedDataProvider's isLoadingMore implementation

  int get loadedMateriasCount => items.length;

  int get totalMateriasFromPagination => paginationInfo?.total ?? 0;

  // Legacy state helper removed; rely on base provider for loading/errors

  @override
  Future<PaginatedResponse<Materia>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    // Leer filtros del provider (this.filters) en lugar de solo los parámetros
    final searchFromFilters = this.filters['search']?.toString() ?? search;
    debugPrint('MateriaProvider.fetchPage - search: $searchFromFilters');
    final response = await _materiaService.getMaterias(accessToken, page: page, limit: limit, search: searchFromFilters);
    if (response == null) return null;
    return PaginatedResponse(items: response.materias, pagination: response.pagination);
  }

  @override
  Future<Materia?> createItemApi(String accessToken, dynamic data) async {
    final created = await _materiaService.createMateria(accessToken, data as CreateMateriaRequest);
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _materiaService.deleteMateria(accessToken, id);
  }

  @override
  Future<Materia?> updateItemApi(String accessToken, String id, dynamic data) async {
    final updated = await _materiaService.updateMateria(accessToken, id, data as UpdateMateriaRequest);
    return updated;
  }

  /// Carga todas las materias con paginación.
  /// Los filtros se deben establecer previamente con filters[] antes de llamar a este método.
  Future<void> loadMaterias(String accessToken, {int? page, int? limit, String? search}) async {
    if (isLoading) return;
    resetPagination();
    
    // Solo actualizar el filtro de búsqueda si se proporciona explícitamente
    if (search != null) {
      if (search.isNotEmpty) {
        filters['search'] = search;
      } else {
        filters.remove('search');
      }
    }
    // NOTA: No removemos filtros si los parámetros son null - los filtros existentes se mantienen

    try {
      debugPrint('MateriaProvider: Iniciando carga de materias con filtros: $filters');
      final effectiveSearch = filters['search']?.toString();
      await loadItems(accessToken, page: page ?? 1, limit: limit, search: effectiveSearch);
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> loadMateriaById(String accessToken, String materiaId) async {
  if (isLoading) return;
    try {
      final materia = await _materiaService.getMateriaById(accessToken, materiaId);
      if (materia != null) {
        _selectedMateria = materia;
  notifyListeners();
      } else {
  setError('Materia no encontrada');
      }
    } catch (e) {
  setError(e.toString());
    }
  }

  Future<bool> createMateria(String accessToken, CreateMateriaRequest materiaData) async {
  if (isLoading) return false;
    try {
      final success = await createItem(accessToken, materiaData);
      if (success) {
  notifyListeners();
        return true;
      }
  setError(errorMessage ?? '');
      return false;
    } catch (e) {
  setError(e.toString());
      return false;
    }
  }

  Future<bool> updateMateria(String accessToken, String materiaId, UpdateMateriaRequest materiaData) async {
  if (isLoading) return false;
    try {
      final success = await updateItem(accessToken, materiaId, materiaData);
      if (success) {
        // update selected if needed
        final updated = items.firstWhere((m) => m.id == materiaId, orElse: () => _selectedMateria!);
        if (_selectedMateria?.id == materiaId) _selectedMateria = updated;
  notifyListeners();
        return true;
      }
  setError(errorMessage ?? '');
      return false;
    } catch (e) {
  setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteMateria(String accessToken, String materiaId) async {
    try {
      final success = await deleteItem(accessToken, materiaId);
      if (!success) {
        setError('Error al eliminar la materia desde el servicio.');
      }
      return success;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  void selectMateria(Materia materia) {
    _selectedMateria = materia;
    notifyListeners();
  }

  void clearSelectedMateria() {
    _selectedMateria = null;
    notifyListeners();
  }

  void clearData() {
    clearItems();
    _selectedMateria = null;
  clearError();
  }

  Future<void> refreshData(String accessToken) async {
    await loadMaterias(accessToken);
  }

  List<Materia> searchMaterias(String query) {
    if (query.isEmpty) return items;
    final lowercaseQuery = query.toLowerCase();
    return items.where((materia) {
      return materia.nombre.toLowerCase().contains(lowercaseQuery) || (materia.codigo?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  @override
  Future<void> loadNextPage(String accessToken) async {
    await super.loadNextPage(accessToken);
  }

  Future<void> loadPreviousPage(String accessToken) async {
  if (paginationInfo == null || !paginationInfo!.hasPrev || isLoading) return;
    final prevPage = paginationInfo!.page - 1;
    await loadMaterias(accessToken, page: prevPage, limit: paginationInfo!.limit);
  }

  Future<void> loadPage(String accessToken, int page) async {
  if (isLoading) return;
    await loadMaterias(accessToken, page: page, limit: paginationInfo?.limit ?? 10);
  }

  Map<String, int> getMateriasStatistics() {
    return {
      'total': paginationInfo?.total ?? 0,
      'con_codigo': items.where((m) => m.codigo != null).length,
      'sin_codigo': items.where((m) => m.codigo == null).length,
    };
  }

  Future<void> loadMoreMaterias(String accessToken, {String? search}) async {
    if (isLoadingMore || !hasMoreData || paginationInfo == null) return;
    
    // Solo actualizar el filtro si se proporciona explícitamente
    if (search != null) {
      filters['search'] = search;
    }
    
    await super.loadNextPage(accessToken);
  }

  Future<List<Materia>?> searchMateriasRemote(String accessToken, {String? search, int limit = 10}) async {
    try {
      final response = await _materiaService.getMaterias(accessToken, page: 1, limit: limit, search: search);
      return response?.materias;
    } catch (e) {
      debugPrint('Error searchMateriasRemote: $e');
      return null;
    }
  }

  // Use the base class implementation for `resetPagination`
}