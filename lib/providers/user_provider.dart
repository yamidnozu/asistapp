import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart' as model;
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final UserService _userService = UserService();

  model.User? _currentUser;
  List<model.User> _allUsers = [];
  bool _isLoading = false;
  late final Stream<auth.User?> _authStateStream;

  model.User? get currentUser => _currentUser;
  List<model.User> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  UserProvider() {
    _init();
  }

  void _init() {
    _authStateStream = _auth.authStateChanges();
    _authStateStream.listen((auth.User? firebaseUser) {
      // Use addPostFrameCallback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (firebaseUser != null) {
          await _syncUserData();
        } else {
          _currentUser = null;
          _isLoading = false;
          notifyListeners();
        }
      });
    });
  }

  Future<void> syncUserData() async {
    await _syncUserData();
  }

  Future<void> _syncUserData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        // Ensure user doc exists (role assignment is handled in UserService)
        final user = model.User(
          uid: firebaseUser.uid,
          displayName: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          photoURL: firebaseUser.photoURL,
          roles: [], // Will be set by UserService
          sites: [],
          status: 'active',
          createdAt: DateTime.now(),
        );
        await _userService.ensureUserDocOnFirstLogin(user);

        // Get updated user data
        _currentUser = await _userService.getUser(firebaseUser.uid);
      } else {
        _currentUser = null;
      }
    } catch (e) {
      debugPrint('Error sincronizando usuario: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserRoles(List<String> roles) async {
    if (_currentUser != null) {
      await _userService.updateUser(_currentUser!.uid, {'roles': roles});
      _currentUser = _currentUser!.copyWith(roles: roles);
      notifyListeners();
    }
  }

  Future<void> loadAllUsers() async {
    try {
      _allUsers = await _userService.getAllUsers();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando todos los usuarios: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  bool hasRole(String role) => _currentUser?.roles.contains(role) ?? false;
  bool isSuperAdmin() => hasRole('super_admin');
  bool isSiteAdmin() => hasRole('site_admin');
  bool isEmployee() => hasRole('employee');
  bool canManageUsers() => isSuperAdmin() || isSiteAdmin();
  bool canResetDB() => isSuperAdmin();
}
