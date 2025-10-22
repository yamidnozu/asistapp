import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserProvider with ChangeNotifier {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  auth.User? _currentUser;
  bool _isLoading = false;
  late final Stream<auth.User?> _authStateStream;

  auth.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  UserProvider() {
    _init();
  }

  void _init() {
    _authStateStream = _auth.authStateChanges();
    _authStateStream.listen((auth.User? firebaseUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _currentUser = firebaseUser;
        _isLoading = false;
        notifyListeners();
      });
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
