import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserProvider with ChangeNotifier {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  auth.User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  late final Stream<auth.User?> _authStateStream;

  // Cache para optimizar recuperación rápida
  auth.User? _cachedUser;
  DateTime? _lastCacheUpdate;

  auth.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  UserProvider() {
    _init();
  }

  void _init() {
    _authStateStream = _auth.authStateChanges();
    _authStateStream.listen((auth.User? firebaseUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateUser(firebaseUser);
      });
    });

    // Intentar cargar desde cache inicialmente
    _loadFromCache();
  }

  void _updateUser(auth.User? firebaseUser) {
    _currentUser = firebaseUser;
    _isLoading = false;
    _isInitialized = true;

    // Actualizar cache
    _cachedUser = firebaseUser;
    _lastCacheUpdate = DateTime.now();

    notifyListeners();
  }

  void _loadFromCache() {
    // Si hay usuario en cache y es reciente (< 5 minutos), usar cache
    if (_cachedUser != null &&
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5) {
      _currentUser = _cachedUser;
      _isInitialized = true;
      notifyListeners();
      debugPrint('UserProvider: Loaded user from cache');
    }
  }

  /// Método para refrescar el estado de autenticación forzosamente
  Future<void> refreshAuthState() async {
    debugPrint('UserProvider: Refreshing auth state...');
    _isLoading = true;
    notifyListeners();

    try {
      // Forzar refresh del token de Firebase
      await _auth.currentUser?.reload();
      final refreshedUser = _auth.currentUser;
      _updateUser(refreshedUser);
      debugPrint('UserProvider: Auth state refreshed');
    } catch (e) {
      debugPrint('UserProvider: Error refreshing auth state: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Método llamado cuando la app vuelve a primer plano
  void onAppResumed() {
    // Solo refrescar si han pasado más de 10 minutos desde el último update
    if (_lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).inMinutes > 10) {
      debugPrint('UserProvider: App resumed, checking auth state...');
      refreshAuthState();
    } else {
      debugPrint('UserProvider: App resumed, using cached state');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _cachedUser = null;
    _lastCacheUpdate = null;
    _isLoading = false;
    notifyListeners();
  }
}
