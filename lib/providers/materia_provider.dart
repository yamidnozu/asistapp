import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/academic_service.dart' as academic_service;
import '../models/materia.dart';
import '../models/user.dart'; // Para PaginationInfo

enum MateriaState {
  initial,
  loading,
  loaded,
  error,
}

class MateriaProvider with ChangeNotifier {
  final academic_service.AcademicService _academicService = academic_service.AcademicService();

  MateriaState _state = MateriaState.initial;
  String? _errorMessage;
  List<Materia> _materias = [];
  Materia? _selectedMateria;
  PaginationInfo? _paginationInfo;

  // Scroll infinito
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  // Getters
  MateriaState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Materia> get materias => _materias;
  Materia? get selectedMateria => _selectedMateria;
  PaginationInfo? get paginationInfo => _paginationInfo;

  bool get isLoading => _state == MateriaState.loading;
  bool get hasError => _state == MateriaState.error;
  bool get isLoaded => _state == MateriaState.loaded;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;

  // Número de materias actualmente cargadas en memoria (página actual)
  int get loadedMateriasCount => _materias.length;

  /// Número total de materias reportado por la paginación del backend
  int get totalMateriasFromPagination => _paginationInfo?.total ?? 0;

  void _setState(MateriaState newState, [String? error]) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  /// Carga todas las materias con paginación y filtros
  Future<void> loadMaterias(String accessToken, {int? page, int? limit, String? search}) async {
    if (_state == MateriaState.loading) return;

    _setState(MateriaState.loading);
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('MateriaProvider: Iniciando carga de materias...');
      final response = await _academicService.getMaterias(
        accessToken,
        page: page ?? 1,
        limit: limit,
        search: search,
      );
      if (response != null) {
        debugPrint('MateriaProvider: Recibidas ${response.materias.length} materias');
        _materias = response.materias;
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        _setState(MateriaState.loaded);
        debugPrint('MateriaProvider: Estado cambiado a loaded');
      } else {
        _setState(MateriaState.error, 'Error al cargar materias');
      }
    } catch (e) {
      debugPrint('MateriaProvider: Error loading materias: $e');
      _setState(MateriaState.error, e.toString());
    }
  }

  /// Carga una materia específica por ID
  Future<void> loadMateriaById(String accessToken, String materiaId) async {
    _setState(MateriaState.loading);

    try {
      final materia = await _academicService.getMateriaById(accessToken, materiaId);
      if (materia != null) {
        _selectedMateria = materia;
        _setState(MateriaState.loaded);
      } else {
        _setState(MateriaState.error, 'Materia no encontrada');
      }
    } catch (e) {
      debugPrint('Error loading materia: $e');
      _setState(MateriaState.error, e.toString());
    }
  }

  /// Crea una nueva materia
  Future<bool> createMateria(String accessToken, academic_service.CreateMateriaRequest materiaData) async {
    _setState(MateriaState.loading);

    try {
      final newMateria = await _academicService.createMateria(accessToken, materiaData);
      if (newMateria != null) {
        // Agregar la nueva materia a la lista
        _materias.insert(0, newMateria);
        _setState(MateriaState.loaded);
        return true;
      } else {
        _setState(MateriaState.error, 'Error al crear materia');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating materia: $e');
      _setState(MateriaState.error, e.toString());
      return false;
    }
  }

  /// Actualiza una materia existente
  Future<bool> updateMateria(String accessToken, String materiaId, academic_service.UpdateMateriaRequest materiaData) async {
    _setState(MateriaState.loading);

    try {
      final updatedMateria = await _academicService.updateMateria(accessToken, materiaId, materiaData);
      if (updatedMateria != null) {
        // Actualizar la materia en la lista
        final index = _materias.indexWhere((materia) => materia.id == materiaId);
        if (index != -1) {
          _materias[index] = updatedMateria;
        }

        // Actualizar la materia seleccionada si es la misma
        if (_selectedMateria?.id == materiaId) {
          _selectedMateria = updatedMateria;
        }

        _setState(MateriaState.loaded);
        return true;
      } else {
        _setState(MateriaState.error, 'Error al actualizar materia');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating materia: $e');
      _setState(MateriaState.error, e.toString());
      return false;
    }
  }

  /// Elimina una materia
  Future<bool> deleteMateria(String accessToken, String materiaId) async {
    // Este método ya no gestionará el estado de la lista.
    // La pantalla se encargará de solicitar la recarga, que sí gestiona el estado.
    try {
      final success = await _academicService.deleteMateria(accessToken, materiaId);

      if (!success) {
        // Guardamos el mensaje de error para que la UI pueda mostrarlo.
        _errorMessage = 'Error al eliminar la materia desde el servicio.';
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting materia: $e');
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Selecciona una materia para edición
  void selectMateria(Materia materia) {
    _selectedMateria = materia;
    notifyListeners();
  }

  /// Limpia la materia seleccionada
  void clearSelectedMateria() {
    _selectedMateria = null;
    notifyListeners();
  }

  /// Limpia todos los datos
  void clearData() {
    _materias = [];
    _selectedMateria = null;
    _paginationInfo = null;
    _setState(MateriaState.initial);
  }

  /// Recarga los datos (útil después de operaciones)
  Future<void> refreshData(String accessToken) async {
    await loadMaterias(accessToken);
  }

  /// Busca materias por nombre o código
  List<Materia> searchMaterias(String query) {
    if (query.isEmpty) return _materias;

    final lowercaseQuery = query.toLowerCase();
    return _materias.where((materia) {
      return materia.nombre.toLowerCase().contains(lowercaseQuery) ||
             (materia.codigo?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Carga la siguiente página de materias
  Future<void> loadNextPage(String accessToken) async {
    if (_paginationInfo == null || !_paginationInfo!.hasNext || _state == MateriaState.loading) return;

    final nextPage = _paginationInfo!.page + 1;
    await loadMaterias(accessToken, page: nextPage, limit: _paginationInfo!.limit);
  }

  /// Carga la página anterior de materias
  Future<void> loadPreviousPage(String accessToken) async {
    if (_paginationInfo == null || !_paginationInfo!.hasPrev || _state == MateriaState.loading) return;

    final prevPage = _paginationInfo!.page - 1;
    await loadMaterias(accessToken, page: prevPage, limit: _paginationInfo!.limit);
  }

  /// Carga una página específica
  Future<void> loadPage(String accessToken, int page) async {
    if (_state == MateriaState.loading) return;

    await loadMaterias(accessToken, page: page, limit: _paginationInfo?.limit ?? 10);
  }

  /// Obtiene estadísticas de materias
  Map<String, int> getMateriasStatistics() {
    return {
      'total': _paginationInfo?.total ?? 0,
      'con_codigo': _materias.where((m) => m.codigo != null).length,
      'sin_codigo': _materias.where((m) => m.codigo == null).length,
    };
  }

  /// Carga más materias para scroll infinito (append)
  Future<void> loadMoreMaterias(String accessToken, {String? search}) async {
    if (_isLoadingMore || !_hasMoreData || _paginationInfo == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _paginationInfo!.page + 1;

      final response = await _academicService.getMaterias(
        accessToken,
        page: nextPage,
        limit: _paginationInfo!.limit,
        search: search,
      );

      if (response != null) {
        _materias.addAll(response.materias); // Agregar al final de la lista
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        debugPrint('MateriaProvider: Cargadas ${response.materias.length} materias más. Total ahora: ${_materias.length}');
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      debugPrint('MateriaProvider: Error loading more materias: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Busca materias en el backend (búsqueda remota)
  Future<List<Materia>?> searchMateriasRemote(String accessToken, {String? search, int limit = 10}) async {
    try {
      final response = await _academicService.getMaterias(
        accessToken,
        page: 1,
        limit: limit,
        search: search,
      );
      return response?.materias;
    } catch (e) {
      debugPrint('Error searchMateriasRemote: $e');
      return null;
    }
  }

  /// Reinicia la paginación para scroll infinito
  void resetPagination() {
    _hasMoreData = true;
    _isLoadingMore = false;
  }
}