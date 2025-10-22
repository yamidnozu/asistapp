import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
  );

  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Iniciar sesión con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Debug logs removed for production
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;

    } catch (e) {
      // Intentar desconectar si hay error
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        // Ignore sign out errors
      }
      return null;
    }
  }

  // Iniciar sesión anónima
  Future<UserCredential?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential;
    } catch (e) {
      // Error al iniciar sesión anónima
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}