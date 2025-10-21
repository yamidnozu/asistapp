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
      print('🔐 Iniciando proceso de Google Sign-In...');

      // Verificar si ya hay un usuario conectado
      if (_auth.currentUser != null) {
        print('✅ Ya hay un usuario autenticado: ${_auth.currentUser!.email}');
        return null;
      }

      // Iniciar el flujo de Google Sign-In
      print('📱 Solicitando cuenta de Google...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ Usuario canceló el sign-in de Google');
        return null;
      }

      print('✅ Usuario de Google seleccionado: ${googleUser.email}');

      // Obtener los detalles de autenticación de la solicitud
      print('🔑 Obteniendo tokens de autenticación...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('🔍 Debug - Access Token: ${googleAuth.accessToken != null ? "Presente" : "NULL"}');
      print('🔍 Debug - ID Token: ${googleAuth.idToken != null ? "Presente" : "NULL"}');

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('❌ Error: Tokens de Google son null');
        print('❌ Access Token: ${googleAuth.accessToken}');
        print('❌ ID Token: ${googleAuth.idToken}');
        return null;
      }

      print('✅ Tokens obtenidos correctamente');

      // Crear una nueva credencial
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 Autenticando con Firebase...');
      // Una vez que se firme en, devolver la UserCredential
      final userCredential = await _auth.signInWithCredential(credential);

      print('✅ Autenticación exitosa con Firebase: ${userCredential.user?.email}');
      return userCredential;

    } catch (e) {
      print('❌ Error al iniciar sesión con Google: $e');
      print('Stack trace: ${StackTrace.current}');

      // Intentar desconectar si hay error
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        print('⚠️ Error al desconectar Google Sign-In: $signOutError');
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