import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/institution.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  String? _selectedInstitutionId;
  List<Institution>? _institutions;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get user => _user;
  String? get selectedInstitutionId => _selectedInstitutionId;
  List<Institution>? get institutions => _institutions;

  bool get isAuthenticated => _accessToken != null && _user != null;

  // Obtener la institución seleccionada actualmente
  Institution? get selectedInstitution {
    if (_selectedInstitutionId == null || _institutions == null) return null;
    try {
      return _institutions!.firstWhere(
        (institution) => institution.id == _selectedInstitutionId,
      );
    } catch (e) {
      return null;
    }
  }

  AuthProvider() {
    _loadTokensFromStorage();
  }

  // Cargar tokens desde almacenamiento seguro (shared_preferences)
  Future<void> _loadTokensFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('accessToken');
      _refreshToken = prefs.getString('refreshToken');
      final userJson = prefs.getString('user');
      if (userJson != null) {
        _user = Map<String, dynamic>.from(jsonDecode(userJson));
      }
      _selectedInstitutionId = prefs.getString('selectedInstitutionId');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from storage: $e');
    }
  }

  // Guardar tokens en almacenamiento seguro
  Future<void> _saveTokensToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString('accessToken', _accessToken!);
      } else {
        await prefs.remove('accessToken');
      }
      if (_refreshToken != null) {
        await prefs.setString('refreshToken', _refreshToken!);
      } else {
        await prefs.remove('refreshToken');
      }
      if (_user != null) {
        await prefs.setString('user', jsonEncode(_user));
      } else {
        await prefs.remove('user');
      }
      if (_selectedInstitutionId != null) {
        await prefs.setString('selectedInstitutionId', _selectedInstitutionId!);
      } else {
        await prefs.remove('selectedInstitutionId');
      }
    } catch (e) {
      debugPrint('Error saving to storage: $e');
    }
  }

  // Limpiar tokens
  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _selectedInstitutionId = null;
    await _saveTokensToStorage();
    notifyListeners();
  }

  // Limpiar datos pesados (ej. instituciones) pero mantener usuario y tokens
  void clearHeavyData() {
    _institutions = null;
    notifyListeners();
  }

  // Limpiar todo excepto usuario básico (para cuando se vuelve a la app)
  void clearTemporaryData() {
    _institutions = null;
    _selectedInstitutionId = null;
    notifyListeners();
  }

  // Recuperar estado completo (llamar al volver a la app)
  Future<void> recoverFullState() async {
    if (_accessToken != null) {
      debugPrint('Recuperando estado completo del usuario');
      await loadUserInstitutions();
      
      // Si tenía una institución guardada, recuperarla
      if (_selectedInstitutionId != null && _institutions != null) {
        final institutionExists = _institutions!.any((i) => i.id == _selectedInstitutionId);
        if (!institutionExists) {
          debugPrint('Institución guardada ya no existe, limpiando');
          _selectedInstitutionId = null;
          await _saveTokensToStorage();
        }
      }
      
      notifyListeners();
    }
  }

  // Cargar instituciones del usuario
  Future<void> loadUserInstitutions() async {
    if (_accessToken == null) return;

    try {
      final institutionMaps = await _authService.getUserInstitutions(_accessToken!);
      _institutions = institutionMaps?.map((map) => Institution.fromJson(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user institutions: $e');
    }
  }

  // Seleccionar institución
  void selectInstitution(String institutionId) {
    _selectedInstitutionId = institutionId;
    _saveTokensToStorage();
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      final result = await _authService.login(email, password);
      if (result != null) {
        _accessToken = result.accessToken;
        _refreshToken = result.refreshToken;
        _user = result.user;

        // Cargar instituciones del usuario después del login
        await loadUserInstitutions();

        // Si tiene solo una institución, seleccionarla automáticamente
        if (_institutions != null && _institutions!.length == 1) {
          _selectedInstitutionId = _institutions!.first.id;
          debugPrint('Institución seleccionada automáticamente: $_selectedInstitutionId');
        } else if (_institutions != null && _institutions!.length > 1) {
          // Si tiene múltiples instituciones, no seleccionar ninguna por ahora
          _selectedInstitutionId = null;
          debugPrint('Múltiples instituciones encontradas, esperando selección manual');
        }

        await _saveTokensToStorage();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Refresh token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final result = await _authService.refreshToken(_refreshToken!);
      if (result != null) {
        _accessToken = result.accessToken;
        _refreshToken = result.refreshToken;
        await _saveTokensToStorage();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Refresh error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    if (_refreshToken != null) {
      await _authService.logout(_refreshToken!);
    }
    await _clearTokens();
  }
}