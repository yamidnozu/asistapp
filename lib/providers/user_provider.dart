import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userId;
  String? _userRole;
  bool _isLoading = false;

  String? get userId => _userId;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;

  Future<void> syncUserData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user != null) {
        _userId = user.uid;

        // Obtener rol desde Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          _userRole = userDoc.data()?['role'] ?? 'user';
        } else {
          // Crear documento de usuario si no existe
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });
          _userRole = 'user';
        }
      }
    } catch (e) {
      // Error sincronizando usuario
      debugPrint('Error sincronizando usuario: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setUserRole(String role) async {
    try {
      if (_userId != null) {
        await _firestore.collection('users').doc(_userId).update({'role': role});
        _userRole = role;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error actualizando rol: $e');
    }
  }

  bool hasRole(String role) => _userRole == role;
  bool isAdmin() => _userRole == 'admin';
  bool isUser() => _userRole == 'user';
}
