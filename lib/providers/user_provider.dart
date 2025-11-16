import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/user_service.dart' as user_service;
import '../models/user.dart';
import 'paginated_data_provider.dart';

// UserState removed; rely on base PaginatedDataProvider methods

class UserProvider extends PaginatedDataProvider<User> {
  final user_service.UserService _userService = user_service.UserService();

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

    try {
      debugPrint('UserProvider: Iniciando carga de usuarios...');
      // Use base pagination via `loadItems` / `fetchPage`
      await loadItems(accessToken, page: page ?? 1, limit: limit, search: search, filters: {
        if (activo != null) 'activo': activo.toString(),
        if (roles != null && roles.isNotEmpty) 'roles': roles.join(','),
      });
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
    _selectedInstitutionId = institutionId;
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('UserProvider: Iniciando carga de usuarios por institución $institutionId...');
      await loadItems(accessToken, page: page ?? 1, limit: limit, filters: {
        'institutionId': institutionId,
        if (role != null) 'role': role,
      });
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
    _selectedUser = null;
    _selectedInstitutionId = null;
  setPaginationInfo(null);
  clearError();
  }

  /// Recarga los datos (útil después de operaciones)
  Future<void> refreshData(String accessToken) async {
    if (_selectedInstitutionId != null) {
      await loadUsersByInstitution(accessToken, _selectedInstitutionId!);
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
  Future<void> loadNextPage(String accessToken, {Map<String, String>? filters}) async {
  if (paginationInfo == null || !paginationInfo!.hasNext || isLoading) return;

    final nextPage = paginationInfo!.page + 1;
    if (_selectedInstitutionId != null) {
      await loadUsersByInstitution(accessToken, _selectedInstitutionId!, page: nextPage, limit: paginationInfo!.limit);
    } else {
  await loadUsers(accessToken, page: nextPage, limit: paginationInfo!.limit);
    }
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
  Future<void> loadMoreUsers(String accessToken, {bool? activo, String? search, List<String>? roles}) async {
  if (isLoadingMore || !hasMoreData || paginationInfo == null) return;

  // Delegate to base provider's loading-more semantics
  // base provider already sets _isLoadingMore flag; we mimic same process
  // by calling loadNextPage where possible. But since this provider uses
  // a custom endpoint for next page, we implement here but using base
  // getters/setters for state.
  // Mark as loading more using the base implementation
  // (the base has a private _isLoadingMore — we cannot set it here
  // directly — but we use setPaginationInfo+notify pattern below).
  // For simplicity we still use a local transient flag (no longer needed):
  // we rely on the base isLoading flag for most UI.
    notifyListeners();

    try {
  final nextPage = paginationInfo!.page + 1;

      user_service.PaginatedUserResponse? response;
      if (_selectedInstitutionId != null) {
        response = await _userService.getUsersByInstitution(
          accessToken,
          _selectedInstitutionId!,
          page: nextPage,
          limit: paginationInfo!.limit,
        );
      } else {
        // No tenemos filtros almacenados en el provider por defecto; la UI debe pasar los filtros
        response = await _userService.getAllUsers(
          accessToken,
          page: nextPage,
          limit: paginationInfo!.limit,
          activo: activo,
          search: search,
          roles: roles,
        );
      }

  if (response != null) {
  items.addAll(response.users); // Agregar al final de la lista
    setPaginationInfo(response.pagination);
  debugPrint('UserProvider: Cargados ${response.users.length} usuarios más. Total ahora: ${items.length}');
      } else {
        setHasMoreData(false);
      }
    } catch (e) {
      debugPrint('UserProvider: Error loading more users: $e');
    } finally {
      setIsLoadingMore(false);
      // isLoadingMore is handled by the base provider; notify changes so UI updates
      notifyListeners();
    }
  }

  @override
  Future<PaginatedResponse<User>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final institutionId = filters?['institutionId'];
    final role = filters?['role'];

    if (institutionId != null && institutionId.isNotEmpty) {
      final response = await _userService.getUsersByInstitution(
        accessToken,
        institutionId,
        page: page,
        limit: limit ?? 5,
        role: role,
      );
      if (response == null) return null;
      return PaginatedResponse(items: response.users, pagination: response.pagination);
    }

    final response = await _userService.getAllUsers(accessToken, page: page, limit: limit, search: search);
    if (response == null) return null;
    return PaginatedResponse(items: response.users, pagination: response.pagination);
  }

  @override
  Future<User?> createItemApi(String accessToken, data) async {
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