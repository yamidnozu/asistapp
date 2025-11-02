import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/user_service.dart' as user_service;
import '../services/profesor_service.dart' as profesor_service;
import '../models/user.dart';

enum UserState {
  initial,
  loading,
  loaded,
  error,
}

class UserProvider with ChangeNotifier {
  final user_service.UserService _userService = user_service.UserService();
  final profesor_service.ProfesorService _profesorService = profesor_service.ProfesorService();

  UserState _state = UserState.initial;
  String? _errorMessage;
  List<User> _users = [];
  User? _selectedUser;
  String? _selectedInstitutionId;
  PaginationInfo? _paginationInfo;
  
  // Scroll infinito
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  // Getters
  UserState get state => _state;
  String? get errorMessage => _errorMessage;
  List<User> get users => _users;
  User? get selectedUser => _selectedUser;
  String? get selectedInstitutionId => _selectedInstitutionId;
  PaginationInfo? get paginationInfo => _paginationInfo;

  bool get isLoading => _state == UserState.loading;
  bool get hasError => _state == UserState.error;
  bool get isLoaded => _state == UserState.loaded;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;

  // Computed properties
  List<User> get activeUsers => _users.where((user) => user.activo).toList();
  List<User> get inactiveUsers => _users.where((user) => !user.activo).toList();

  List<User> get professors => _users.where((user) => user.esProfesor).toList();
  List<User> get students => _users.where((user) => user.esEstudiante).toList();
  List<User> get adminInstitutions => _users.where((user) => user.esAdminInstitucion).toList();

  int get totalUsers => _users.length;
  int get activeUsersCount => activeUsers.length;
  int get inactiveUsersCount => inactiveUsers.length;

  int get professorsCount => professors.length;
  int get studentsCount => students.length;
  int get adminInstitutionsCount => adminInstitutions.length;

  void _setState(UserState newState, [String? error]) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  /// Carga todos los usuarios con paginación y filtros (activo, búsqueda, roles)
  Future<void> loadUsers(String accessToken, {int? page, int? limit, bool? activo, String? search, List<String>? roles}) async {
    if (_state == UserState.loading) return;

    _setState(UserState.loading);
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('UserProvider: Iniciando carga de usuarios...');
      final response = await _userService.getAllUsers(
        accessToken,
        page: page ?? 1,
        limit: limit,
        activo: activo,
        search: search,
        roles: roles,
      );
      if (response != null) {
        debugPrint('UserProvider: Recibidos ${response.users.length} usuarios');
        _users = response.users;
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        _setState(UserState.loaded);
        debugPrint('UserProvider: Estado cambiado a loaded');
      } else {
        _setState(UserState.error, 'Error al cargar usuarios');
      }
    } catch (e) {
      debugPrint('UserProvider: Error loading users: $e');
      _setState(UserState.error, e.toString());
    }
  }

  /// Carga usuarios por institución con paginación
  Future<void> loadUsersByInstitution(String accessToken, String institutionId, {int? page, int limit = 5, String? role, bool? activo, String? search}) async {
    if (_state == UserState.loading) return;

    _setState(UserState.loading);
    _selectedInstitutionId = institutionId;
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('UserProvider: Iniciando carga de usuarios por institución $institutionId...');
      final response = await _userService.getUsersByInstitution(accessToken, institutionId, page: page ?? 1, limit: limit, role: role, activo: activo, search: search);
      if (response != null) {
        debugPrint('UserProvider: Recibidos ${response.users.length} usuarios de institución $institutionId');
        _users = response.users;
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        _setState(UserState.loaded);
      } else {
        _setState(UserState.error, 'Error al cargar usuarios de la institución');
      }
    } catch (e) {
      debugPrint('UserProvider: Error loading users by institution: $e');
      _setState(UserState.error, e.toString());
    }
  }

  /// Carga administradores de una institución específica (sin paginación)
  Future<void> loadAdminsByInstitution(String accessToken, String institutionId) async {
    if (_state == UserState.loading) return;

    _setState(UserState.loading);
    _selectedInstitutionId = institutionId;

    try {
      debugPrint('UserProvider: Cargando admins de la institución $institutionId...');
      final admins = await _userService.getAdminsByInstitution(accessToken, institutionId);
      if (admins != null) {
        _users = admins;
        _hasMoreData = false;
        _setState(UserState.loaded);
      } else {
        _setState(UserState.error, 'Error al cargar administradores de la institución');
      }
    } catch (e) {
      debugPrint('UserProvider: Error loading admins by institution: $e');
      _setState(UserState.error, e.toString());
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
    if (_state == UserState.loading) return;

    _setState(UserState.loading);
    resetPagination(); // Resetear para scroll infinito

    try {
      debugPrint('UserProvider: Iniciando carga de usuarios por rol $role...');
      final response = await _userService.getUsersByRole(accessToken, role, page: page ?? 1, limit: limit);
      if (response != null) {
        debugPrint('UserProvider: Recibidos ${response.users.length} usuarios con rol $role');
        _users = response.users;
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        _setState(UserState.loaded);
      } else {
        _setState(UserState.error, 'Error al cargar usuarios por rol');
      }
    } catch (e) {
      debugPrint('UserProvider: Error loading users by role: $e');
      _setState(UserState.error, e.toString());
    }
  }

  /// Carga un usuario específico por ID
  Future<void> loadUserById(String accessToken, String userId) async {
    _setState(UserState.loading);

    try {
      final user = await _userService.getUserById(accessToken, userId);
      if (user != null) {
        _selectedUser = user;
        _setState(UserState.loaded);
      } else {
        _setState(UserState.error, 'Usuario no encontrado');
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      _setState(UserState.error, e.toString());
    }
  }

  /// Crea un nuevo usuario
  Future<bool> createUser(String accessToken, CreateUserRequest userData) async {
    _setState(UserState.loading);

    try {
      final newUser = await _userService.createUser(accessToken, userData);
      if (newUser != null) {
        // Agregar el nuevo usuario a la lista
        _users.insert(0, newUser);
        _setState(UserState.loaded);
        return true;
      } else {
        _setState(UserState.error, 'Error al crear usuario');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating user: $e');
      _setState(UserState.error, e.toString());
      return false;
    }
  }

  /// Actualiza un usuario existente
  Future<bool> updateUser(String accessToken, String userId, UpdateUserRequest userData) async {
    _setState(UserState.loading);

    try {
      final updatedUser = await _userService.updateUser(accessToken, userId, userData);
      if (updatedUser != null) {
        // Actualizar el usuario en la lista
        final index = _users.indexWhere((user) => user.id == userId);
        if (index != -1) {
          _users[index] = updatedUser;
        }

        // Actualizar el usuario seleccionado si es el mismo
        if (_selectedUser?.id == userId) {
          _selectedUser = updatedUser;
        }

        _setState(UserState.loaded);
        return true;
      } else {
        _setState(UserState.error, 'Error al actualizar usuario');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      _setState(UserState.error, e.toString());
      return false;
    }
  }

  /// Elimina un usuario (desactivación lógica)
  Future<bool> deleteUser(String accessToken, String userId, String currentUserRole, String targetUserRole) async {
    // Este método ya no gestionará el estado de la lista.
    // La pantalla se encargará de solicitar la recarga, que sí gestiona el estado.
    try {
      bool success = false;

      // Para admin_institucion eliminando profesores, usar el servicio de profesores
      if (currentUserRole == 'admin_institucion' && targetUserRole == 'profesor') {
        success = await _profesorService.deleteProfesor(accessToken, userId);
      } else {
        // Para otros casos, usar el servicio general de usuarios
        success = await _userService.deleteUser(accessToken, userId);
      }

      if (!success) {
        // Guardamos el mensaje de error para que la UI pueda mostrarlo.
        _errorMessage = 'Error al eliminar el usuario desde el servicio.';
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Selecciona un usuario para edición
  void selectUser(User user) {
    _selectedUser = user;
    notifyListeners();
  }

  /// Limpia el usuario seleccionado
  void clearSelectedUser() {
    _selectedUser = null;
    notifyListeners();
  }

  /// Limpia todos los datos
  void clearData() {
    _users = [];
    _selectedUser = null;
    _selectedInstitutionId = null;
    _paginationInfo = null;
    _setState(UserState.initial);
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
    if (query.isEmpty) return _users;

    final lowercaseQuery = query.toLowerCase();
    return _users.where((user) {
      return user.nombreCompleto.toLowerCase().contains(lowercaseQuery) ||
             user.email.toLowerCase().contains(lowercaseQuery) ||
             (user.telefono?.contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Filtra usuarios por rol
  List<User> filterUsersByRole(String role) {
    if (role.isEmpty) return _users;
    return _users.where((user) => user.rol == role).toList();
  }

  // NOTE: filterUsersLocally removed. All role filtering should be done via backend queries.

  /// Filtra usuarios por estado activo/inactivo
  List<User> filterUsersByStatus({bool? active}) {
    if (active == null) return _users;
    return _users.where((user) => user.activo == active).toList();
  }

  /// Carga la siguiente página de usuarios
  Future<void> loadNextPage(String accessToken) async {
    if (_paginationInfo == null || !_paginationInfo!.hasNext || _state == UserState.loading) return;

    final nextPage = _paginationInfo!.page + 1;
    if (_selectedInstitutionId != null) {
      await loadUsersByInstitution(accessToken, _selectedInstitutionId!, page: nextPage, limit: _paginationInfo!.limit);
    } else {
      await loadUsers(accessToken, page: nextPage, limit: _paginationInfo!.limit);
    }
  }

  /// Carga la página anterior de usuarios
  Future<void> loadPreviousPage(String accessToken) async {
    if (_paginationInfo == null || !_paginationInfo!.hasPrev || _state == UserState.loading) return;

    final prevPage = _paginationInfo!.page - 1;
    if (_selectedInstitutionId != null) {
      await loadUsersByInstitution(accessToken, _selectedInstitutionId!, page: prevPage, limit: _paginationInfo!.limit);
    } else {
      await loadUsers(accessToken, page: prevPage, limit: _paginationInfo!.limit);
    }
  }

  /// Carga una página específica
  Future<void> loadPage(String accessToken, int page) async {
    if (_state == UserState.loading) return;

    if (_selectedInstitutionId != null) {
      await loadUsersByInstitution(accessToken, _selectedInstitutionId!, page: page, limit: _paginationInfo?.limit ?? 5);
    } else {
      await loadUsers(accessToken, page: page, limit: _paginationInfo?.limit ?? 5);
    }
  }

  /// Obtiene estadísticas de usuarios
  Map<String, int> getUserStatistics() {
    return {
      'total': _paginationInfo?.total ?? totalUsers,
      'activos': activeUsersCount,
      'inactivos': inactiveUsersCount,
      'profesores': professorsCount,
      'estudiantes': studentsCount,
      'admins_institucion': adminInstitutionsCount,
    };
  }

  /// Carga más usuarios para scroll infinito (append)
  Future<void> loadMoreUsers(String accessToken, {bool? activo, String? search, List<String>? roles}) async {
    if (_isLoadingMore || !_hasMoreData || _paginationInfo == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _paginationInfo!.page + 1;

      user_service.PaginatedUserResponse? response;
      if (_selectedInstitutionId != null) {
        response = await _userService.getUsersByInstitution(
          accessToken,
          _selectedInstitutionId!,
          page: nextPage,
          limit: _paginationInfo!.limit,
        );
      } else {
        // No tenemos filtros almacenados en el provider por defecto; la UI debe pasar los filtros
        response = await _userService.getAllUsers(
          accessToken,
          page: nextPage,
          limit: _paginationInfo!.limit,
          activo: activo,
          search: search,
          roles: roles,
        );
      }

      if (response != null) {
        _users.addAll(response.users); // Agregar al final de la lista
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
        debugPrint('UserProvider: Cargados ${response.users.length} usuarios más. Total ahora: ${_users.length}');
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      debugPrint('UserProvider: Error loading more users: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
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
  void resetPagination() {
    _hasMoreData = true;
    _isLoadingMore = false;
  }
}