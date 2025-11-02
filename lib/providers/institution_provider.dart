import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/institution_service.dart';
import '../models/institution.dart';
import '../models/user.dart';

enum InstitutionState {
  initial,
  loading,
  loaded,
  error,
}

class InstitutionProvider with ChangeNotifier {
  final InstitutionService _institutionService = InstitutionService();

  InstitutionState _state = InstitutionState.initial;
  String? _errorMessage;
  List<Institution> _institutions = [];
  Institution? _selectedInstitution;
  PaginationInfo? _paginationInfo;
  
  // Scroll infinito
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  // Getters
  InstitutionState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Institution> get institutions => _institutions;
  Institution? get selectedInstitution => _selectedInstitution;
  PaginationInfo? get paginationInfo => _paginationInfo;

  bool get isLoading => _state == InstitutionState.loading;
  bool get hasError => _state == InstitutionState.error;
  bool get isLoaded => _state == InstitutionState.loaded;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;

  // Computed properties
  List<Institution> get activeInstitutions =>
      _institutions.where((inst) => inst.activa).toList();

  List<Institution> get inactiveInstitutions =>
      _institutions.where((inst) => !inst.activa).toList();

  int get totalInstitutions => _institutions.length;
  int get activeInstitutionsCount => activeInstitutions.length;
  int get inactiveInstitutionsCount => inactiveInstitutions.length;

  void _setState(InstitutionState newState, [String? error]) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  /// Reinicia la paginación para scroll infinito
  void resetPagination() {
    _hasMoreData = true;
    _isLoadingMore = false;
  }

  /// Carga todas las instituciones con paginación
  Future<void> loadInstitutions(String accessToken, {int? page, int? limit, bool? activa, String? search}) async {
    if (_state == InstitutionState.loading) return;

    _setState(InstitutionState.loading);
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('InstitutionProvider: Iniciando carga de instituciones...');
      final response = await _institutionService.getAllInstitutions(accessToken, page: page ?? 1, limit: limit, activa: activa, search: search);
      if (response != null) {
        debugPrint('InstitutionProvider: Recibidas ${response.institutions.length} instituciones');
        _institutions = response.institutions;
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        _setState(InstitutionState.loaded);
        debugPrint('InstitutionProvider: Estado cambiado a loaded');
      } else {
        _setState(InstitutionState.error, 'Error al cargar instituciones');
      }
    } catch (e) {
      debugPrint('InstitutionProvider: Error loading institutions: $e');
      _setState(InstitutionState.error, e.toString());
    }
  }

  /// Carga una institución específica por ID
  Future<void> loadInstitutionById(String accessToken, String id) async {
    _setState(InstitutionState.loading);

    try {
      final institution = await _institutionService.getInstitutionById(accessToken, id);
      _selectedInstitution = institution;
      _setState(InstitutionState.loaded);
    } catch (e) {
      debugPrint('Error loading institution: $e');
      _setState(InstitutionState.error, e.toString());
    }
  }

  /// Crea una nueva institución
  Future<bool> createInstitution(
    String accessToken,
    Map<String, dynamic> institutionData,
  ) async {
    _setState(InstitutionState.loading);

    try {
      final newInstitution = await _institutionService.createInstitution(
        accessToken,
        nombre: institutionData['nombre'],
        direccion: institutionData['direccion'],
        telefono: institutionData['telefono'],
        email: institutionData['email'],
      );

      // Agregar la nueva institución a la lista
      if (newInstitution != null) {
        _institutions.insert(0, newInstitution);
      }
      _setState(InstitutionState.loaded);
      return true;
    } catch (e) {
      debugPrint('Error creating institution: $e');
      _setState(InstitutionState.error, e.toString());
      return false;
    }
  }

  /// Actualiza una institución existente
  Future<bool> updateInstitution(
    String accessToken,
    String id, {
    String? nombre,
    String? direccion,
    String? telefono,
    String? email,
    bool? activa,
  }) async {
    _setState(InstitutionState.loading);

    try {
      final updatedInstitution = await _institutionService.updateInstitution(
        accessToken,
        id,
        nombre: nombre,
        direccion: direccion,
        telefono: telefono,
        email: email,
        activa: activa,
      );

      // Actualizar la institución en la lista
      final index = _institutions.indexWhere((inst) => inst.id == id);
      if (index != -1 && updatedInstitution != null) {
        _institutions[index] = updatedInstitution;
      }

      // Actualizar la institución seleccionada si es la misma
      if (_selectedInstitution?.id == id && updatedInstitution != null) {
        _selectedInstitution = updatedInstitution;
      }

      _setState(InstitutionState.loaded);
      return true;
    } catch (e) {
      debugPrint('Error updating institution: $e');
      _setState(InstitutionState.error, e.toString());
      return false;
    }
  }

  /// Elimina una institución
  Future<bool> deleteInstitution(String accessToken, String id) async {
    _setState(InstitutionState.loading);

    try {
      await _institutionService.deleteInstitution(accessToken, id);

      // Remover la institución de la lista
      _institutions.removeWhere((inst) => inst.id == id);

      // Limpiar la institución seleccionada si es la misma
      if (_selectedInstitution?.id == id) {
        _selectedInstitution = null;
      }

      _setState(InstitutionState.loaded);
      return true;
    } catch (e) {
      debugPrint('Error deleting institution: $e');
      _setState(InstitutionState.error, e.toString());
      return false;
    }
  }

  /// Selecciona una institución para edición
  void selectInstitution(Institution institution) {
    _selectedInstitution = institution;
    notifyListeners();
  }

  /// Limpia la institución seleccionada
  void clearSelectedInstitution() {
    _selectedInstitution = null;
    notifyListeners();
  }

  /// Limpia todos los datos
  void clearData() {
    _institutions = [];
    _selectedInstitution = null;
    _setState(InstitutionState.initial);
  }

  /// Recarga los datos (útil después de operaciones)
  Future<void> refreshData(String accessToken) async {
    await loadInstitutions(accessToken);
  }

  /// Busca instituciones por nombre o código
  List<Institution> searchInstitutions(String query) {
    if (query.isEmpty) return _institutions;

    final lowercaseQuery = query.toLowerCase();
    return _institutions.where((inst) {
      return inst.nombre.toLowerCase().contains(lowercaseQuery) ||
             (inst.email?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Carga más instituciones para scroll infinito
  Future<void> loadMoreInstitutions(String accessToken, {bool? activa, String? search}) async {
    if (_isLoadingMore || !_hasMoreData || _paginationInfo == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _paginationInfo!.page + 1;
      debugPrint('InstitutionProvider: Cargando más instituciones, página $nextPage...');
      
      final response = await _institutionService.getAllInstitutions(
        accessToken, 
        page: nextPage, 
        limit: _paginationInfo!.limit,
        activa: activa, 
        search: search
      );
      
      if (response != null && response.institutions.isNotEmpty) {
        debugPrint('InstitutionProvider: Recibidas ${response.institutions.length} instituciones adicionales');
        _institutions.addAll(response.institutions);
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      debugPrint('InstitutionProvider: Error loading more institutions: $e');
      _hasMoreData = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}