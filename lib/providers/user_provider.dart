import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pagination_types.dart';
import '../services/user_service.dart' as user_service;
import '../models/user.dart';
import 'paginated_data_mixin.dart';

// UserState removed; rely on base PaginatedDataMixin methods

class UserProvider extends ChangeNotifier with PaginatedDataMixin<User> {
  final user_service.UserService _userService;

  UserProvider({user_service.UserService? userService})
      : _userService = userService ?? user_service.UserService();

  // Error handling delegated to PaginatedDataProvider

  // Items are stored in PaginatedDataProvider._items. Retain _state for UI-specific flags.
  User? _selectedUser;
  String? _selectedInstitutionId;
  // pagination handled by PaginatedDataProvider

  // Getters
  // Use PaginatedDataProvider's errorMessage
  List<User> get users => items;
  User? get selectedUser => _selectedUser;
  String? get selectedInstitutionId => _selectedInstitutionId;
  // use base paginationInfo

  // Delegated to PaginatedDataProvider - use base implementation
  // Use local scroll state flags to preserve current semantics;
  // eventually we can centralize on the base implementation.
  // delegated to base

  // Computed properties
  List<User> get activeUsers => items.where((user) => user.activo).toList();
  List<User> get inactiveUsers => items.where((user) => !user.activo).toList();

  List<User> get professors => items.where((user) => user.esProfesor).toList();
  List<User> get students => items.where((user) => user.esEstudiante).toList();
  List<User> get adminInstitutions => items.where((user) => user.esAdminInstitucion).toList();

  // Número de usuarios actualmente cargados en memoria (página actual)
  int get loadedUsersCount => items.length;
  int get activeUsersCount => activeUsers.length;
  int get inactiveUsersCount => inactiveUsers.length;

  int get professorsCount => professors.length;
  int get studentsCount => students.length;
  int get adminInstitutionsCount => adminInstitutions.length;
  
  /// Número total de usuarios reportado por la paginación del backend
  int get totalUsersFromPagination => paginationInfo?.total ?? 0;

  // Legacy state helper removed; rely on base provider for loading/errors

  /// Carga todos los usuarios con paginación y filtros (activo, búsqueda, roles)
  Future<void> loadUsers(String accessToken, {int? page, int? limit, bool? activo, String? search, List<String>? roles}) async {
    if (isLoading) return;
    resetPagination(); // Resetear para scroll infinito

    // Clear institution filter if loading global users
    removeFilter('institutionId');
    _selectedInstitutionId = null;

    // Update filters only when explicit values are provided. Do not clear existing filters otherwise.
    if (search != null) {
      if (search.isNotEmpty) {
        setFilter('search', search);
      } else {
        removeFilter('search');
      }
    }
    if (activo != null) {
      setFilter('activo', activo.toString());
    }
    if (roles != null) {
      if (roles.isNotEmpty) setFilter('roles', roles.join(',')); else removeFilter('roles');
    }

    try {
      debugPrint('UserProvider: Iniciando carga de usuarios...');
      // Use base pagination via `loadItems` / `fetchPage`
      await loadItems(accessToken, page: page ?? 1, limit: limit, search: search, filters: filters.isNotEmpty ? filters.map((k, v) => MapEntry(k, v.toString())) : null);
      // base handles pagination info and hasMoreData
      notifyListeners();
    } catch (e) {
      debugPrint('UserProvider: Error loading users: $e');
      setError(e.toString());
    }
  }

  /// Carga usuarios por institución con paginación
  Future<void> loadUsersByInstitution(String accessToken, String institutionId, {int? page, int limit = 5, String? role, bool? activo, String? search}) async {
    if (isLoading) return;
    // Clear items immediately to avoid mixed data
    clearItems();
    _selectedInstitutionId = institutionId;
    resetPagination(); // Resetear para scroll infinito

    // Set filters
    setFilter('institutionId', institutionId);
    if (role != null) {
      if (role.isNotEmpty) setFilter('role', role); else removeFilter('role');
    }
    if (activo != null) {
      setFilter('activo', activo.toString());
    }
    if (search != null) {
      if (search.isNotEmpty) setFilter('search', search); else removeFilter('search');
    }

    try {
      debugPrint('UserProvider: Iniciando carga de usuarios por institución $institutionId...');
      await loadItems(accessToken, page: page ?? 1, limit: limit, filters: filters.isNotEmpty ? filters.map((k, v) => MapEntry(k, v.toString())) : null);
      // base handles pagination info and hasMoreData
      notifyListeners();
    } catch (e) {
      debugPrint('UserProvider: Error loading users by institution: $e');
      setError(e.toString());
    }
  }

  /// Carga administradores de una institución específica (sin paginación)
  Future<void> loadAdminsByInstitution(String accessToken, String institutionId) async {
  if (isLoading) return;

  // base handles loading state
    _selectedInstitutionId = institutionId;

    try {
      debugPrint('UserProvider: Cargando admins de la institución $institutionId...');
      final admins = await _userService.getAdminsByInstitution(accessToken, institutionId);
      if (admins != null) {
        clearItems();
  items.addAll(admins);
  setHasMoreData(false);
  notifyListeners();
      } else {
  setError('Error al cargar administradores de la institución');
      }
    } catch (e) {
      debugPrint('UserProvider: Error loading admins by institution: $e');
  setError(e.toString());
    }
  }

  /// Asigna un usuario existente como admin de institución
  Future<bool> assignAdminToInstitution(String accessToken, String institutionId, String userId) async {
    try {
      final updated = await _userService.assignAdminToInstitution(accessToken, institutionId, userId);
      if (updated != null) {
        // Refrescar lista local
        await loadAdminsByInstitution(accessToken, institutionId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error assignAdminToInstitution: $e');
      return false;
    }
  }

  /// Remueve el rol de admin de institución para un usuario
  Future<bool> removeAdminFromInstitution(String accessToken, String institutionId, String userId) async {
    try {
      final result = await _userService.removeAdminFromInstitution(accessToken, institutionId, userId);
      if (result != null) {
        await loadAdminsByInstitution(accessToken, institutionId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removeAdminFromInstitution: $e');
      return false;
    }
  }

  /// Carga usuarios por rol con paginación
  Future<void> loadUsersByRole(String accessToken, String role, {int? page, int? limit}) async {
  if (isLoading) return;

  // base handles loading state
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('UserProvider: Iniciando carga de usuarios por rol $role...');
      final response = await _userService.getUsersByRole(accessToken, role, page: page ?? 1, limit: limit);
      if (response != null) {
        debugPrint('UserProvider: Recibidos ${response.users.length} usuarios con rol $role');
  // loadItems populates items
  setPaginationInfo(response.pagination);
  notifyListeners();
      } else {
  setError('Error al cargar usuarios por rol');
      }
    } catch (e) {
      debugPrint('UserProvider: Error loading users by role: $e');
  setError(e.toString());
    }
  }

  /// Carga un usuario específico por ID
  Future<void> loadUserById(String accessToken, String userId) async {
  // base handles loading state

    try {
      final user = await _userService.getUserById(accessToken, userId);
      if (user != null) {
        _selectedUser = user;
  notifyListeners();
      } else {
  setError('Usuario no encontrado');
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
  setError(e.toString());
    }
  }

  /// Crea un nuevo usuario
  Future<bool> createUser(String accessToken, CreateUserRequest userData) async {
  // base handles loading state

    try {
      final newUser = await _userService.createUser(accessToken, userData);
      if (newUser != null) {
        // Agregar el nuevo usuario a la lista
  items.insert(0, newUser);
  notifyListeners();
        return true;
      } else {
  setError('Error al crear usuario');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating user: $e');
  setError(e.toString());
      return false;
    }
  }

  /// Actualiza un usuario existente
  Future<bool> updateUser(String accessToken, String userId, UpdateUserRequest userData) async {
  // base handles loading state

    try {
      final updatedUser = await _userService.updateUser(accessToken, userId, userData);
      if (updatedUser != null) {
        // Actualizar el usuario en la lista
        final index = items.indexWhere((user) => user.id == userId);
        if (index != -1) {
          items[index] = updatedUser;
        }

        // Actualizar el usuario seleccionado si es el mismo
        if (_selectedUser?.id == userId) {
          _selectedUser = updatedUser;
        }

  notifyListeners();
        return true;
      } else {
  setError('Error al actualizar usuario');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
  setError(e.toString());
      return false;
    }
  }

  /// Elimina un usuario (desactivación lógica)
  /// El backend maneja internamente las validaciones de permisos según el rol del usuario autenticado
  Future<bool> deleteUser(String accessToken, String userId) async {
    // Este método ya no gestionará el estado de la lista.
    // La pantalla se encargará de solicitar la recarga, que sí gestiona el estado.
    try {
      final success = await _userService.deleteUser(accessToken, userId);

      if (!success) {
        // Guardamos el mensaje de error para que la UI pueda mostrarlo.
        setError('Error al eliminar el usuario desde el servicio.');
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      setError(e.toString());
      return false;
    }
  }

  /// Cambia la contraseña de un usuario (llama al servicio)
  Future<bool> changeUserPassword(String accessToken, String userId, String newPassword) async {
    try {
      final result = await _userService.changePassword(accessToken, userId, newPassword);
      return result == true;
    } catch (e) {
      debugPrint('Error changeUserPassword: $e');
      setError(e.toString());
      return false;
    }
  }

  /// Selecciona un usuario para edición
  void selectUser(User user) {
    _selectedUser = user;
  setIsLoadingMore(true);
  }

  /// Limpia el usuario seleccionado
  void clearSelectedUser() {
    _selectedUser = null;
    notifyListeners();
  }

  /// Limpia todos los datos
  void clearData() {
    clearItems();
    clearFilters();
    _selectedUser = null;
    _selectedInstitutionId = null;
    setPaginationInfo(null);
    clearError();
  }  /// Recarga los datos (útil después de operaciones)
  Future<void> refreshData(String accessToken) async {
    if (filters['institutionId'] != null) {
      await loadUsersByInstitution(accessToken, filters['institutionId'] as String);
    } else {
      await loadUsers(accessToken);
    }
  }

  /// Busca usuarios por nombre, email o apellidos
  List<User> searchUsers(String query) {
  if (query.isEmpty) return items;

    final lowercaseQuery = query.toLowerCase();
  return items.where((user) {
      return user.nombreCompleto.toLowerCase().contains(lowercaseQuery) ||
             user.email.toLowerCase().contains(lowercaseQuery) ||
             (user.telefono?.contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Filtra usuarios por rol
  List<User> filterUsersByRole(String role) {
  if (role.isEmpty) return items;
  return items.where((user) => user.rol == role).toList();
  }

  // NOTE: filterUsersLocally removed. All role filtering should be done via backend queries.

  /// Filtra usuarios por estado activo/inactivo
  List<User> filterUsersByStatus({bool? active}) {
  if (active == null) return items;
  return items.where((user) => user.activo == active).toList();
  }

  /// Carga la siguiente página de usuarios
  @override
  Future<void> loadNextPage(String accessToken) async {
    await super.loadNextPage(accessToken);
  }

  /// Carga la página anterior de usuarios
  Future<void> loadPreviousPage(String accessToken) async {
  if (paginationInfo == null || !paginationInfo!.hasPrev || isLoading) return;

    final prevPage = paginationInfo!.page - 1;
    if (_selectedInstitutionId != null) {
      await loadUsersByInstitution(accessToken, _selectedInstitutionId!, page: prevPage, limit: paginationInfo!.limit);
    } else {
  await loadUsers(accessToken, page: prevPage, limit: paginationInfo!.limit);
    }
  }

  /// Carga una página específica
  Future<void> loadPage(String accessToken, int page) async {
  if (isLoading) return;

    if (_selectedInstitutionId != null) {
      await loadUsersByInstitution(accessToken, _selectedInstitutionId!, page: page, limit: paginationInfo?.limit ?? 5);
    } else {
  await loadUsers(accessToken, page: page, limit: paginationInfo?.limit ?? 5);
    }
  }

  /// Obtiene estadísticas de usuarios
  Map<String, int> getUserStatistics() {
    return {
      // 'total' debe reflejar el total informado por la paginación del backend.
  'total': paginationInfo?.total ?? 0,
      'activos': activeUsersCount,
      'inactivos': inactiveUsersCount,
      'profesores': professorsCount,
      'estudiantes': studentsCount,
      'admins_institucion': adminInstitutionsCount,
    };
  }

  /// Carga más usuarios para scroll infinito (append)
  Future<void> loadMoreUsers(String accessToken) async {
    await super.loadNextPage(accessToken);
  }

  @override
  Future<PaginatedResponse<User>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final institutionId = this.filters['institutionId'];
    final role = this.filters['role'];
    final activoStr = this.filters['activo'];
    final activo = activoStr == 'true';
    final searchQuery = this.filters['search'] as String?;
    final rolesStr = this.filters['roles'] as String?;
    final roles = rolesStr != null && rolesStr.isNotEmpty ? rolesStr.split(',') : null;

    if (institutionId != null && institutionId.isNotEmpty) {
      final response = await _userService.getUsersByInstitution(
        accessToken,
        institutionId,
        page: page,
        limit: limit ?? 5,
        role: role,
        activo: activoStr != null ? activo : null,
        search: searchQuery,
      );
      if (response == null) return null;
      return PaginatedResponse(items: response.users, pagination: response.pagination);
    }

    final response = await _userService.getAllUsers(accessToken, page: page, limit: limit, search: searchQuery, activo: activoStr != null ? activo : null, roles: roles);
    if (response == null) return null;
    return PaginatedResponse(items: response.users, pagination: response.pagination);
  }

  @override
  Future<User?> createItemApi(String accessToken, dynamic data) async {
    final created = await _userService.createUser(accessToken, data as CreateUserRequest);
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _userService.deleteUser(accessToken, id);
  }

  @override
  Future<User?> updateItemApi(String accessToken, String id, dynamic data) async {
    final updated = await _userService.updateUser(accessToken, id, data as UpdateUserRequest);
    return updated;
  }

  /// Busca usuarios en el backend (búsqueda remota) — usado por diálogos que requieren búsqueda puntual
  Future<List<User>?> searchUsersRemote(String accessToken, {String? search, int limit = 10}) async {
    try {
      final response = await _userService.getAllUsers(
        accessToken,
        page: 1,
        limit: limit,
        search: search,
      );
      return response?.users;
    } catch (e) {
      debugPrint('Error searchUsersRemote: $e');
      return null;
    }
  }

  /// Reinicia la paginación para scroll infinito
  @override
  void resetPagination() {
    super.resetPagination();
  }
}