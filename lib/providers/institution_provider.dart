import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pagination_types.dart';
import '../services/institution_service.dart';
import '../models/institution.dart';
import 'paginated_data_mixin.dart';
// import '../models/user.dart'; // unused

// InstitutionState removed: rely on PaginatedDataMixin state

class InstitutionProvider extends ChangeNotifier with PaginatedDataMixin<Institution> {
  final InstitutionService _institutionService;

  InstitutionProvider({InstitutionService? institutionService})
      : _institutionService = institutionService ?? InstitutionService();

  // Error delegated to PaginatedDataProvider

  // Items are stored in PaginatedDataProvider._items
  Institution? _selectedInstitution;
  // Pagination managed by PaginatedDataProvider

  // Getters
  // Use PaginatedDataProvider's errorMessage
  List<Institution> get institutions => items;
  Institution? get selectedInstitution => _selectedInstitution;
  // Use base paginationInfo

  // Delegated to PaginatedDataProvider - use base implementation
  // Use base isLoadingMore and hasMoreData

  // Computed properties
  List<Institution> get activeInstitutions =>
    items.where((inst) => inst.activa).toList();

  List<Institution> get inactiveInstitutions =>
    items.where((inst) => !inst.activa).toList();

  int get totalInstitutions => items.length;
  int get activeInstitutionsCount => activeInstitutions.length;
  int get inactiveInstitutionsCount => inactiveInstitutions.length;

  // _setState helper removed; use base provider methods instead

  /// Reinicia la paginación para scroll infinito
  @override
  void resetPagination() {
    super.resetPagination();
  }

  /// Carga todas las instituciones con paginación
  Future<void> loadInstitutions(String accessToken, {int? page, int? limit, bool? activa, String? search}) async {
    if (isLoading) return;
    resetPagination(); // Resetear para scroll infinito

    // Set filters
    // Only update filters when explicit values are provided. If null, keep existing filters.
    if (search != null) {
      if (search.isNotEmpty) {
        setFilter('search', search);
      } else {
        removeFilter('search');
      }
    }
    if (activa != null) {
      setFilter('activa', activa.toString());
    }

    try {
      debugPrint('InstitutionProvider: Iniciando carga de instituciones...');
      // Use provided search param if not null, otherwise fallback to provider filters
      final effectiveSearch = search ?? (this.filters['search'] as String?);
      await loadItems(
        accessToken,
        page: page ?? 1,
        limit: limit,
        search: effectiveSearch,
        filters: filters.isNotEmpty ? filters.map((k, v) => MapEntry(k, v.toString())) : null,
      );
      // paginationInfo handled by base provider
      notifyListeners();
      debugPrint('InstitutionProvider: Estado cambiado a loaded');
    } catch (e) {
      debugPrint('InstitutionProvider: Error loading institutions: $e');
      setError(e.toString());
    }
  }

  /// Carga una institución específica por ID
  Future<void> loadInstitutionById(String accessToken, String id) async {
    // Always allow fetching a single institution by ID even if other operations
    // are running (e.g. list loading). This avoids blocking detail fetches when
    // the provider is already fetching paginated list data.
    try {
      final institution = await _institutionService.getInstitutionById(accessToken, id);
      debugPrint('InstitutionProvider: loadInstitutionById - fetched: ${institution?.toString()}');
      _selectedInstitution = institution;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading institution: $e');
      setError(e.toString());
    }
  }

  /// Crea una nueva institución
  Future<bool> createInstitution(
    String accessToken,
    Map<String, dynamic> institutionData,
  ) async {
  if (isLoading) return false;

    try {
      final newInstitution = await _institutionService.createInstitution(
        accessToken,
        nombre: institutionData['nombre'],
        direccion: institutionData['direccion'],
        telefono: institutionData['telefono'],
        email: institutionData['email'],
      );

      if (newInstitution != null) {
        items.insert(0, newInstitution);
        notifyListeners();
        return true;
      }
      setError('Error al crear institución');
      return false;
    } catch (e) {
      debugPrint('Error creating institution: $e');
      setError(e.toString());
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
  if (isLoading) return false;

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
  final index = items.indexWhere((inst) => inst.id == id);
      if (index != -1 && updatedInstitution != null) {
  items[index] = updatedInstitution;
      }

      // Actualizar la institución seleccionada si es la misma
      if (_selectedInstitution?.id == id && updatedInstitution != null) {
        _selectedInstitution = updatedInstitution;
      }

    notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating institution: $e');
      setError(e.toString());
      return false;
    }
  }

  /// Elimina una institución
  Future<bool> deleteInstitution(String accessToken, String id) async {
    if (isLoading) return false;

    try {
      await _institutionService.deleteInstitution(accessToken, id);

      // Remover la institución de la lista
  items.removeWhere((inst) => inst.id == id);

      // Limpiar la institución seleccionada si es la misma
      if (_selectedInstitution?.id == id) {
        _selectedInstitution = null;
      }

  notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting institution: $e');
      setError(e.toString());
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
    clearItems();
    clearFilters();
    _selectedInstitution = null;
    clearError();
  }  /// Recarga los datos (útil después de operaciones)
  Future<void> refreshData(String accessToken) async {
    await loadInstitutions(accessToken);
  }

  /// Busca instituciones por nombre o código
  List<Institution> searchInstitutions(String query) {
  if (query.isEmpty) return items;

    final lowercaseQuery = query.toLowerCase();
  return items.where((inst) {
      return inst.nombre.toLowerCase().contains(lowercaseQuery) ||
             (inst.email?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Carga más instituciones para scroll infinito
  Future<void> loadMoreInstitutions(String accessToken) async {
    await super.loadNextPage(accessToken);
  }

  @override
  Future<PaginatedResponse<Institution>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final activeStr = this.filters['activa'];
    final active = activeStr == 'true';
    final searchQuery = this.filters['search'] as String?;
    final response = await _institutionService.getAllInstitutions(accessToken, page: page, limit: limit, activa: activeStr != null ? active : null, search: searchQuery);
    if (response == null) return null;
    return PaginatedResponse(items: response.institutions, pagination: response.pagination);
  }

  @override
  Future<Institution?> createItemApi(String accessToken, dynamic data) async {
    final map = data as Map<String, dynamic>;
    final created = await _institutionService.createInstitution(
      accessToken,
      nombre: map['nombre'] as String,
      direccion: map['direccion'] as String?,
      telefono: map['telefono'] as String?,
      email: map['email'] as String?,
    );
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _institutionService.deleteInstitution(accessToken, id);
  }

  @override
  Future<Institution?> updateItemApi(String accessToken, String id, dynamic data) async {
    final updated = await _institutionService.updateInstitution(accessToken, id,
      nombre: data['nombre'] as String?,
      direccion: data['direccion'] as String?,
      telefono: data['telefono'] as String?,
      email: data['email'] as String?,
      activa: data['activa'] as bool?,
    );
    return updated;
  }
}