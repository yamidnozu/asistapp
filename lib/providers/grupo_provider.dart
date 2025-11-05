import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/academic_service.dart' as academic_service;
import '../models/grupo.dart';
import '../models/user.dart'; // Para PaginationInfo

enum GrupoState {
  initial,
  loading,
  loaded,
  error,
}

class GrupoProvider with ChangeNotifier {
  final academic_service.AcademicService _academicService = academic_service.AcademicService();

  GrupoState _state = GrupoState.initial;
  String? _errorMessage;
  List<Grupo> _grupos = [];
  Grupo? _selectedGrupo;
  String? _selectedPeriodoId;
  PaginationInfo? _paginationInfo;

  // Scroll infinito
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  // Getters
  GrupoState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Grupo> get grupos => _grupos;
  Grupo? get selectedGrupo => _selectedGrupo;
  String? get selectedPeriodoId => _selectedPeriodoId;
  PaginationInfo? get paginationInfo => _paginationInfo;

  bool get isLoading => _state == GrupoState.loading;
  bool get hasError => _state == GrupoState.error;
  bool get isLoaded => _state == GrupoState.loaded;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;

  // Computed properties
  List<Grupo> get gruposActivos => _grupos.where((grupo) => grupo.periodoAcademico.activo).toList();
  List<Grupo> get gruposInactivos => _grupos.where((grupo) => !grupo.periodoAcademico.activo).toList();

  // Número de grupos actualmente cargados en memoria (página actual)
  int get loadedGruposCount => _grupos.length;
  int get gruposActivosCount => gruposActivos.length;
  int get gruposInactivosCount => gruposInactivos.length;

  /// Número total de grupos reportado por la paginación del backend
  int get totalGruposFromPagination => _paginationInfo?.total ?? 0;

  void _setState(GrupoState newState, [String? error]) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  /// Carga todos los grupos con paginación y filtros
  Future<void> loadGrupos(String accessToken, {int? page, int? limit, String? periodoId, String? search}) async {
    if (_state == GrupoState.loading) return;

    _setState(GrupoState.loading);
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('GrupoProvider: Iniciando carga de grupos...');
      final response = await _academicService.getGrupos(
        accessToken,
        page: page ?? 1,
        limit: limit,
        periodoId: periodoId,
        search: search,
      );
      if (response != null) {
        debugPrint('GrupoProvider: Recibidos ${response.grupos.length} grupos');
        _grupos = response.grupos;
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        _setState(GrupoState.loaded);
        debugPrint('GrupoProvider: Estado cambiado a loaded');
      } else {
        _setState(GrupoState.error, 'Error al cargar grupos');
      }
    } catch (e) {
      debugPrint('GrupoProvider: Error loading grupos: $e');
      _setState(GrupoState.error, e.toString());
    }
  }

  /// Carga grupos por periodo académico
  Future<void> loadGruposByPeriodo(String accessToken, String periodoId, {int? page, int limit = 10, String? search}) async {
    if (_state == GrupoState.loading) return;

    _setState(GrupoState.loading);
    _selectedPeriodoId = periodoId;
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('GrupoProvider: Iniciando carga de grupos por periodo $periodoId...');
      final response = await _academicService.getGrupos(accessToken, page: page ?? 1, limit: limit, periodoId: periodoId, search: search);
      if (response != null) {
        debugPrint('GrupoProvider: Recibidos ${response.grupos.length} grupos del periodo $periodoId');
        _grupos = response.grupos;
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        _setState(GrupoState.loaded);
      } else {
        _setState(GrupoState.error, 'Error al cargar grupos del periodo');
      }
    } catch (e) {
      debugPrint('GrupoProvider: Error loading grupos by periodo: $e');
      _setState(GrupoState.error, e.toString());
    }
  }

  /// Carga un grupo específico por ID
  Future<void> loadGrupoById(String accessToken, String grupoId) async {
    _setState(GrupoState.loading);

    try {
      final grupo = await _academicService.getGrupoById(accessToken, grupoId);
      if (grupo != null) {
        _selectedGrupo = grupo;
        _setState(GrupoState.loaded);
      } else {
        _setState(GrupoState.error, 'Grupo no encontrado');
      }
    } catch (e) {
      debugPrint('Error loading grupo: $e');
      _setState(GrupoState.error, e.toString());
    }
  }

  /// Crea un nuevo grupo
  Future<bool> createGrupo(String accessToken, academic_service.CreateGrupoRequest grupoData) async {
    _setState(GrupoState.loading);

    try {
      final newGrupo = await _academicService.createGrupo(accessToken, grupoData);
      if (newGrupo != null) {
        // Agregar el nuevo grupo a la lista
        _grupos.insert(0, newGrupo);
        _setState(GrupoState.loaded);
        return true;
      } else {
        _setState(GrupoState.error, 'Error al crear grupo');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating grupo: $e');
      _setState(GrupoState.error, e.toString());
      return false;
    }
  }

  /// Actualiza un grupo existente
  Future<bool> updateGrupo(String accessToken, String grupoId, academic_service.UpdateGrupoRequest grupoData) async {
    _setState(GrupoState.loading);

    try {
      final updatedGrupo = await _academicService.updateGrupo(accessToken, grupoId, grupoData);
      if (updatedGrupo != null) {
        // Actualizar el grupo en la lista
        final index = _grupos.indexWhere((grupo) => grupo.id == grupoId);
        if (index != -1) {
          _grupos[index] = updatedGrupo;
        }

        // Actualizar el grupo seleccionado si es el mismo
        if (_selectedGrupo?.id == grupoId) {
          _selectedGrupo = updatedGrupo;
        }

        _setState(GrupoState.loaded);
        return true;
      } else {
        _setState(GrupoState.error, 'Error al actualizar grupo');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating grupo: $e');
      _setState(GrupoState.error, e.toString());
      return false;
    }
  }

  /// Elimina un grupo
  Future<bool> deleteGrupo(String accessToken, String grupoId) async {
    // Este método ya no gestionará el estado de la lista.
    // La pantalla se encargará de solicitar la recarga, que sí gestiona el estado.
    try {
      final success = await _academicService.deleteGrupo(accessToken, grupoId);

      if (!success) {
        // Guardamos el mensaje de error para que la UI pueda mostrarlo.
        _errorMessage = 'Error al eliminar el grupo desde el servicio.';
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting grupo: $e');
      _errorMessage = e.toString();
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
    _grupos = [];
    _selectedGrupo = null;
    _selectedPeriodoId = null;
    _paginationInfo = null;
    _setState(GrupoState.initial);
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
    if (query.isEmpty) return _grupos;

    final lowercaseQuery = query.toLowerCase();
    return _grupos.where((grupo) {
      return grupo.nombre.toLowerCase().contains(lowercaseQuery) ||
             grupo.grado.toLowerCase().contains(lowercaseQuery) ||
             (grupo.seccion?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Filtra grupos por grado
  List<Grupo> filterGruposByGrado(String grado) {
    if (grado.isEmpty) return _grupos;
    return _grupos.where((grupo) => grupo.grado == grado).toList();
  }

  /// Filtra grupos por estado del periodo (activo/inactivo)
  List<Grupo> filterGruposByPeriodoStatus({bool? activo}) {
    if (activo == null) return _grupos;
    return _grupos.where((grupo) => grupo.periodoAcademico.activo == activo).toList();
  }

  /// Carga la siguiente página de grupos
  Future<void> loadNextPage(String accessToken) async {
    if (_paginationInfo == null || !_paginationInfo!.hasNext || _state == GrupoState.loading) return;

    final nextPage = _paginationInfo!.page + 1;
    if (_selectedPeriodoId != null) {
      await loadGruposByPeriodo(accessToken, _selectedPeriodoId!, page: nextPage, limit: _paginationInfo!.limit);
    } else {
      await loadGrupos(accessToken, page: nextPage, limit: _paginationInfo!.limit);
    }
  }

  /// Carga la página anterior de grupos
  Future<void> loadPreviousPage(String accessToken) async {
    if (_paginationInfo == null || !_paginationInfo!.hasPrev || _state == GrupoState.loading) return;

    final prevPage = _paginationInfo!.page - 1;
    if (_selectedPeriodoId != null) {
      await loadGruposByPeriodo(accessToken, _selectedPeriodoId!, page: prevPage, limit: _paginationInfo!.limit);
    } else {
      await loadGrupos(accessToken, page: prevPage, limit: _paginationInfo!.limit);
    }
  }

  /// Carga una página específica
  Future<void> loadPage(String accessToken, int page) async {
    if (_state == GrupoState.loading) return;

    if (_selectedPeriodoId != null) {
      await loadGruposByPeriodo(accessToken, _selectedPeriodoId!, page: page, limit: _paginationInfo?.limit ?? 10);
    } else {
      await loadGrupos(accessToken, page: page, limit: _paginationInfo?.limit ?? 10);
    }
  }

  /// Obtiene estadísticas de grupos
  Map<String, int> getGruposStatistics() {
    return {
      'total': _paginationInfo?.total ?? 0,
      'activos': gruposActivosCount,
      'inactivos': gruposInactivosCount,
    };
  }

  /// Carga más grupos para scroll infinito (append)
  Future<void> loadMoreGrupos(String accessToken, {String? periodoId, String? search}) async {
    if (_isLoadingMore || !_hasMoreData || _paginationInfo == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _paginationInfo!.page + 1;

      academic_service.PaginatedGruposResponse? response;
      if (_selectedPeriodoId != null) {
        response = await _academicService.getGrupos(
          accessToken,
          page: nextPage,
          limit: _paginationInfo!.limit,
          periodoId: _selectedPeriodoId,
        );
      } else {
        response = await _academicService.getGrupos(
          accessToken,
          page: nextPage,
          limit: _paginationInfo!.limit,
          periodoId: periodoId,
          search: search,
        );
      }

      if (response != null) {
        _grupos.addAll(response.grupos); // Agregar al final de la lista
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        debugPrint('GrupoProvider: Cargados ${response.grupos.length} grupos más. Total ahora: ${_grupos.length}');
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      debugPrint('GrupoProvider: Error loading more grupos: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Busca grupos en el backend (búsqueda remota)
  Future<List<Grupo>?> searchGruposRemote(String accessToken, {String? search, int limit = 10}) async {
    try {
      final response = await _academicService.getGrupos(
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
  void resetPagination() {
    _hasMoreData = true;
    _isLoadingMore = false;
  }
}