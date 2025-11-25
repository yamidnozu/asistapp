import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pagination_types.dart';
import '../services/academic/grupo_service.dart';
import '../models/grupo.dart';
import 'paginated_data_mixin.dart';

// GrupoState removed: use PaginatedDataMixin's isLoading/hasError/isLoaded

class GrupoProvider extends ChangeNotifier with PaginatedDataMixin<Grupo> {
  final GrupoService _grupoService;

  GrupoProvider({GrupoService? grupoService})
      : _grupoService = grupoService ?? GrupoService();

  String? _errorMessage;
  Grupo? _selectedGrupo;
  String? _selectedPeriodoId;

  // Pagination is managed by PaginatedDataProvider

  // Estados para estudiantes were moved to paginated providers.

  // Getters
  @override
  String? get errorMessage => _errorMessage;
  List<Grupo> get grupos => items;
  Grupo? get selectedGrupo => _selectedGrupo;
  String? get selectedPeriodoId => _selectedPeriodoId;
  // Use PaginatedDataProvider paginationInfo

  // Students paginated data now exposed via EstudiantesByGrupoPaginatedProvider
  // and EstudiantesSinAsignarPaginatedProvider. Keep GrupoProvider focused on
  // groups.

  // Delegated to PaginatedDataProvider - use super implementation directly where needed
  // Use PaginatedDataProvider's isLoadingMore and hasMoreData

  // Computed properties
  List<Grupo> get gruposActivos => items.where((grupo) => grupo.periodoAcademico.activo).toList();
  List<Grupo> get gruposInactivos => items.where((grupo) => !grupo.periodoAcademico.activo).toList();

  // Número de grupos actualmente cargados en memoria (página actual)
  int get loadedGruposCount => items.length;
  int get gruposActivosCount => gruposActivos.length;
  int get gruposInactivosCount => gruposInactivos.length;

  /// Número total de grupos reportado por la paginación del backend
  // Use base paginationInfo
  int get totalGruposFromPagination => paginationInfo?.total ?? 0;

  // Legacy _setState removed; use base provider methods for loading/errors

  /// Carga todos los grupos con paginación y filtros
  Future<void> loadGrupos(String accessToken, {int? page, int? limit, String? periodoId, String? search}) async {
  if (isLoading) return;
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('GrupoProvider: Iniciando carga de grupos...');
      await loadItems(accessToken, page: page ?? 1, limit: limit, search: search, filters: {
        if (periodoId != null) 'periodoId': periodoId,
      });
  // paginationInfo handled by base provider
  notifyListeners();
      debugPrint('GrupoProvider: Estado cambiado a loaded');
    } catch (e) {
      debugPrint('GrupoProvider: Error loading grupos: $e');
  setError(e.toString());
    }
  }

  /// Carga grupos por periodo académico
  Future<void> loadGruposByPeriodo(String accessToken, String periodoId, {int? page, int limit = 10, String? search}) async {
  if (isLoading) return;
    _selectedPeriodoId = periodoId;
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('GrupoProvider: Iniciando carga de grupos por periodo $periodoId...');
  _selectedPeriodoId = periodoId; // store for filters
      await loadItems(accessToken, page: page ?? 1, limit: limit, search: search, filters: {
        'periodoId': periodoId,
      });
  // paginationInfo handled by base provider
  notifyListeners();
      debugPrint('GrupoProvider: Estado cambiado a loaded');
    } catch (e) {
      debugPrint('GrupoProvider: Error loading grupos by periodo: $e');
  setError(e.toString());
    }
  }

  /// Carga un grupo específico por ID
  Future<void> loadGrupoById(String accessToken, String grupoId) async {
  if (isLoading) return;

    try {
      final grupo = await _grupoService.getGrupoById(accessToken, grupoId);
      if (grupo != null) {
        _selectedGrupo = grupo;
  notifyListeners();
      } else {
  setError('Grupo no encontrado');
      }
    } catch (e) {
      debugPrint('Error loading grupo: $e');
  setError(e.toString());
    }
  }

  /// Crea un nuevo grupo
  Future<bool> createGrupo(String accessToken, CreateGrupoRequest grupoData) async {
    if (isLoading) return false;

    try {
      final newGrupo = await _grupoService.createGrupo(accessToken, grupoData);
      if (newGrupo != null) {
        // Agregar el nuevo grupo a la lista
        items.insert(0, newGrupo);
  notifyListeners();
        return true;
      } else {
  setError('Error al crear grupo');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating grupo: $e');
  setError(e.toString());
      return false;
    }
  }

  /// Actualiza un grupo existente
  Future<bool> updateGrupo(String accessToken, String grupoId, UpdateGrupoRequest grupoData) async {
    if (isLoading) return false;

    try {
      final updatedGrupo = await _grupoService.updateGrupo(accessToken, grupoId, grupoData);
      if (updatedGrupo != null) {
        // Actualizar el grupo en la lista
  final index = items.indexWhere((grupo) => grupo.id == grupoId);
        if (index != -1) {
          items[index] = updatedGrupo;
        }

        // Actualizar el grupo seleccionado si es el mismo
        if (_selectedGrupo?.id == grupoId) {
          _selectedGrupo = updatedGrupo;
        }

  notifyListeners();
        return true;
      } else {
  setError('Error al actualizar grupo');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating grupo: $e');
  setError(e.toString());
      return false;
    }
  }

  /// Elimina un grupo
  Future<bool> deleteGrupo(String accessToken, String grupoId) async {
    // Este método ya no gestionará el estado de la lista.
    // La pantalla se encargará de solicitar la recarga, que sí gestiona el estado.
    try {
      final success = await _grupoService.deleteGrupo(accessToken, grupoId);

      if (!success) {
        // Guardamos el mensaje de error para que la UI pueda mostrarlo.
        setError('Error al eliminar el grupo desde el servicio.');
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting grupo: $e');
      setError(e.toString());
      return false;
    }
  }

  /// Selecciona un grupo para edición
  void selectGrupo(Grupo grupo) {
    _selectedGrupo = grupo;
    notifyListeners();
  }

  /// Limpia el grupo seleccionado
  void clearSelectedGrupo() {
    _selectedGrupo = null;
    notifyListeners();
  }

  /// Limpia todos los datos
  void clearData() {
  clearItems();
    _selectedGrupo = null;
    _selectedPeriodoId = null;
  // pagination info is cleared by clearItems()
  clearError();
  }

  /// Recarga los datos (útil después de operaciones)
  Future<void> refreshData(String accessToken) async {
    if (_selectedPeriodoId != null) {
      await loadGruposByPeriodo(accessToken, _selectedPeriodoId!);
    } else {
      await loadGrupos(accessToken);
    }
  }

  /// Busca grupos por nombre, grado o sección
  List<Grupo> searchGrupos(String query) {
  if (query.isEmpty) return items;

    final lowercaseQuery = query.toLowerCase();
  return items.where((grupo) {
      return grupo.nombre.toLowerCase().contains(lowercaseQuery) ||
             grupo.grado.toLowerCase().contains(lowercaseQuery) ||
             (grupo.seccion?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Filtra grupos por grado
  List<Grupo> filterGruposByGrado(String grado) {
    if (grado.isEmpty) return items;
    return items.where((grupo) => grupo.grado == grado).toList();
  }

  /// Filtra grupos por estado del periodo (activo/inactivo)
  List<Grupo> filterGruposByPeriodoStatus({bool? activo}) {
    if (activo == null) return items;
    return items.where((grupo) => grupo.periodoAcademico.activo == activo).toList();
  }

  /// Carga la siguiente página de grupos
  @override
  Future<void> loadNextPage(String accessToken, {Map<String, String>? filters}) async {
  if (paginationInfo == null || !paginationInfo!.hasNext || isLoading) return;

  final nextPage = paginationInfo!.page + 1;
    if (_selectedPeriodoId != null) {
  await loadGruposByPeriodo(accessToken, _selectedPeriodoId!, page: nextPage, limit: paginationInfo!.limit);
    } else {
  await loadGrupos(accessToken, page: nextPage, limit: paginationInfo!.limit);
    }
  }

  /// Carga la página anterior de grupos
  Future<void> loadPreviousPage(String accessToken) async {
  if (paginationInfo == null || !paginationInfo!.hasPrev || isLoading) return;

  final prevPage = paginationInfo!.page - 1;
    if (_selectedPeriodoId != null) {
  await loadGruposByPeriodo(accessToken, _selectedPeriodoId!, page: prevPage, limit: paginationInfo!.limit);
    } else {
  await loadGrupos(accessToken, page: prevPage, limit: paginationInfo!.limit);
    }
  }

  /// Carga una página específica
  Future<void> loadPage(String accessToken, int page) async {
  if (isLoading) return;

    if (_selectedPeriodoId != null) {
  await loadGruposByPeriodo(accessToken, _selectedPeriodoId!, page: page, limit: paginationInfo?.limit ?? 10);
    } else {
  await loadGrupos(accessToken, page: page, limit: paginationInfo?.limit ?? 10);
    }
  }

  /// Obtiene estadísticas de grupos
  Map<String, int> getGruposStatistics() {
    return {
  'total': paginationInfo?.total ?? 0,
      'activos': gruposActivosCount,
      'inactivos': gruposInactivosCount,
    };
  }

  /// Carga más grupos para scroll infinito (append)
  Future<void> loadMoreGrupos(String accessToken, {String? periodoId, String? search}) async {
    if (isLoadingMore || !hasMoreData || paginationInfo == null) return;

    // Set filters
    if (periodoId != null) {
      setFilter('periodoId', periodoId);
    } else if (_selectedPeriodoId != null) {
      setFilter('periodoId', _selectedPeriodoId);
    }
    if (search != null) {
      setFilter('search', search);
    }

    // Delegate to base implementation which uses fetchPage and updates pagination info
    await super.loadNextPage(accessToken);
  }

  /// Busca grupos en el backend (búsqueda remota)
  Future<List<Grupo>?> searchGruposRemote(String accessToken, {String? search, int limit = 10}) async {
    try {
      final response = await _grupoService.getGrupos(
        accessToken,
        page: 1,
        limit: limit,
        search: search,
      );
      return response?.grupos;
    } catch (e) {
      debugPrint('Error searchGruposRemote: $e');
      return null;
    }
  }

  /// Reinicia la paginación para scroll infinito
  @override
  void resetPagination() {
    super.resetPagination();
  }

  @override
  Future<PaginatedResponse<Grupo>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final periodoId = filters?['periodoId'] ?? _selectedPeriodoId;
    final searchFromFilters = search ?? filters?['search'];
    final response = await _grupoService.getGrupos(
      accessToken,
      page: page,
      limit: limit,
      periodoId: periodoId,
      search: searchFromFilters,
    );
    if (response == null) return null;
    return PaginatedResponse(items: response.grupos, pagination: response.pagination);
  }

  @override
  Future<Grupo?> createItemApi(String accessToken, dynamic data) async {
    final created = await _grupoService.createGrupo(accessToken, data as CreateGrupoRequest);
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _grupoService.deleteGrupo(accessToken, id);
  }

  @override
  Future<Grupo?> updateItemApi(String accessToken, String id, dynamic data) async {
  final updated = await _grupoService.updateGrupo(accessToken, id, data as UpdateGrupoRequest);
    return updated;
  }

  /// Deprecated: students loading is handled by paginated providers.
  /// Keep methods for backward compatibility for a short period.
  /// Prefer using EstudiantesByGrupoPaginatedProvider and EstudiantesSinAsignarPaginatedProvider.
  @Deprecated('Use EstudiantesByGrupoPaginatedProvider instead')
  Future<void> loadEstudiantesByGrupo(String accessToken, String grupoId, {int? page, int? limit}) async {
    debugPrint('loadEstudiantesByGrupo is deprecated; use EstudiantesByGrupoPaginatedProvider instead.');
    try {
      await _grupoService.getEstudiantesByGrupo(accessToken, grupoId, page: page ?? 1, limit: limit ?? 10);
    } catch (e) {
      debugPrint('Error in deprecated loadEstudiantesByGrupo: $e');
      setError(e.toString());
    }
  }

  @Deprecated('Use EstudiantesSinAsignarPaginatedProvider instead')
  Future<void> loadEstudiantesSinAsignar(String accessToken, {int? page, int? limit}) async {
    debugPrint('loadEstudiantesSinAsignar is deprecated; use EstudiantesSinAsignarPaginatedProvider instead.');
    try {
      await _grupoService.getEstudiantesSinAsignar(accessToken, page: page ?? 1, limit: limit ?? 10);
    } catch (e) {
      debugPrint('Error in deprecated loadEstudiantesSinAsignar: $e');
      setError(e.toString());
    }
  }

  /// Asigna un estudiante a un grupo
  Future<bool> asignarEstudianteAGrupo(String accessToken, String grupoId, String estudianteId) async {
    try {
      final success = await _grupoService.asignarEstudianteAGrupo(accessToken, grupoId, estudianteId);
      if (success) {
        // The UI should refresh the paginated providers after this call.
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error asignando estudiante a grupo: $e');
      setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Desasigna un estudiante de un grupo
  Future<bool> desasignarEstudianteDeGrupo(String accessToken, String grupoId, String estudianteId) async {
    try {
      final success = await _grupoService.desasignarEstudianteDeGrupo(accessToken, grupoId, estudianteId);
      if (success) {
        // UI should refresh the paginated providers after this call.
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error desasignando estudiante de grupo: $e');
      setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Limpia los datos de estudiantes
  void clearEstudiantesData() {
  // Nothing to clear here: paginated providers handle students cache.
    notifyListeners();
  }
}