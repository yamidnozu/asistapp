import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/institution_service.dart';
import '../models/institution.dart';

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

  // Getters
  InstitutionState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Institution> get institutions => _institutions;
  Institution? get selectedInstitution => _selectedInstitution;

  bool get isLoading => _state == InstitutionState.loading;
  bool get hasError => _state == InstitutionState.error;
  bool get isLoaded => _state == InstitutionState.loaded;

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

  /// Carga todas las instituciones
  Future<void> loadInstitutions(String accessToken) async {
    if (_state == InstitutionState.loading) return;

    _setState(InstitutionState.loading);

    try {
      debugPrint('InstitutionProvider: Iniciando carga de instituciones...');
      final institutions = await _institutionService.getAllInstitutions(accessToken);
      debugPrint('InstitutionProvider: Recibidas ${institutions.length} instituciones');
      _institutions = institutions;
      _setState(InstitutionState.loaded);
      debugPrint('InstitutionProvider: Estado cambiado a loaded');
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
        codigo: institutionData['codigo'],
        direccion: institutionData['direccion'],
        telefono: institutionData['telefono'],
        email: institutionData['email'],
      );

      // Agregar la nueva institución a la lista
      _institutions.insert(0, newInstitution);
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
    String? codigo,
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
        codigo: codigo,
        direccion: direccion,
        telefono: telefono,
        email: email,
        activa: activa,
      );

      // Actualizar la institución en la lista
      final index = _institutions.indexWhere((inst) => inst.id == id);
      if (index != -1) {
        _institutions[index] = updatedInstitution;
      }

      // Actualizar la institución seleccionada si es la misma
      if (_selectedInstitution?.id == id) {
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
             inst.codigo.toLowerCase().contains(lowercaseQuery) ||
             (inst.email?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Filtra instituciones por estado activo/inactivo
  List<Institution> filterInstitutions({bool? active}) {
    if (active == null) return _institutions;
    return _institutions.where((inst) => inst.activa == active).toList();
  }
}