import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  String? _selectedInstitutionId;
  List<Map<String, dynamic>>? _institutions;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get user => _user;
  String? get selectedInstitutionId => _selectedInstitutionId;
  List<Map<String, dynamic>>? get institutions => _institutions;

  bool get isAuthenticated => _accessToken != null && _user != null;

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

  // Cargar instituciones
  Future<void> loadInstitutions() async {
    try {
      _institutions = await _authService.getInstitutions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading institutions: $e');
    }
  }

  // Seleccionar institución
  void selectInstitution(String institutionId) {
    _selectedInstitutionId = institutionId;
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password, String institutionId) async {
    try {
      final result = await _authService.login(email, password, institutionId);
      if (result != null) {
        _accessToken = result.accessToken;
        _refreshToken = result.refreshToken;
        _user = result.user;
        _selectedInstitutionId = institutionId;
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