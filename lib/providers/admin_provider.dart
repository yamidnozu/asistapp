import 'package:flutter/foundation.dart';
import '../models/user.dart' as model;
import '../services/user_service.dart';
import '../services/admin_service.dart';

class AdminProvider with ChangeNotifier {
  final UserService _userService = UserService();
  final AdminService _adminService = AdminService();

  List<model.User> _users = [];
  bool _isLoading = false;

  List<model.User> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      _users = await _userService.getAllUsers();
    } catch (e) {
      debugPrint('Error cargando usuarios: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> assignRoles(String uid, List<String> roles) async {
    await _adminService.assignRoles(uid, roles);
    await loadUsers(); // Reload users
  }

  Future<void> assignSites(String uid, List<String> sites) async {
    await _adminService.assignSites(uid, sites);
    await loadUsers();
  }

  Future<void> setUserStatus(String uid, String status) async {
    await _adminService.setUserStatus(uid, status);
    await loadUsers();
  }

  Future<List<String>> getSuperAdminUids() async {
    return await _adminService.getSuperAdminUids();
  }

  Future<void> addSuperAdmin(String uid) async {
    await _adminService.addSuperAdmin(uid);
  }

  Future<void> removeSuperAdmin(String uid) async {
    await _adminService.removeSuperAdmin(uid);
  }
}