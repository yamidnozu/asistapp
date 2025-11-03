import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/institution.dart';
import 'user_provider.dart';
import 'institution_provider.dart';

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

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _selectedInstitutionId = null;
    await _saveTokensToStorage();
    notifyListeners();
  }

  void clearHeavyData() {
    _institutions = null;
    notifyListeners();
  }

  void clearTemporaryData() {
    _institutions = null;
    _selectedInstitutionId = null;
    notifyListeners();
  }

  Future<void> recoverFullState() async {
    if (_accessToken != null) {
      debugPrint('Recuperando estado completo del usuario');
      await loadUserInstitutions();

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

  Future<void> loadUserInstitutions({bool notify = true}) async {
    if (_accessToken == null) return;

    try {
      final institutionMaps = await _authService.getUserInstitutions(_accessToken!);
      _institutions = institutionMaps?.map((map) => Institution.fromJson(map)).toList();
      if (notify) notifyListeners();
    } catch (e) {
      debugPrint('Error loading user institutions: $e');
    }
  }

  void selectInstitution(String institutionId) {
    _selectedInstitutionId = institutionId;
    _saveTokensToStorage();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final result = await _authService.login(email, password);
      if (result != null) {
        _accessToken = result.accessToken;
        _refreshToken = result.refreshToken;
        _user = result.user;

        await loadUserInstitutions(notify: false);

        if (_institutions != null && _institutions!.length == 1) {
          _selectedInstitutionId = _institutions!.first.id;
          debugPrint('Institución seleccionada automáticamente: $_selectedInstitutionId');
        } else if (_institutions != null && _institutions!.length > 1) {
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
      // Propagar la excepción para que la UI la pueda mostrar de forma explícita
      rethrow;
    }
  }

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

  Future<void> logout() async {
    if (_refreshToken != null) {
      await _authService.logout(_refreshToken!);
    }
    await _clearTokens();
  }

  Future<void> logoutAndClearAllData(BuildContext context) async {
    if (_refreshToken != null) {
      await _authService.logout(_refreshToken!);
    }
    await _clearTokens();

    // Limpiar datos de otros providers
    if (context.mounted) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.clearData();

        final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);
        institutionProvider.clearData();
      } catch (e) {
        debugPrint('Error clearing provider data: $e');
      }
    }
  }
}