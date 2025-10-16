import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  late final Stream<User?> _authStateStream;

  User? get user => _user;

  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _authService.currentUser;
    _authStateStream = _authService.authStateChanges;
    _authStateStream.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        _user = _authService.currentUser;
        notifyListeners();
        // Esperar un poco para que Firebase actualice el estado
        await Future.delayed(const Duration(milliseconds: 500));
        _user = _authService.currentUser;
        notifyListeners();
      }
    } catch (e) {
      // Error al iniciar sesión
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      // Error al cerrar sesión
    }
  }
}