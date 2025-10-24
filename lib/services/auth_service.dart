import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Modelo para respuesta de login
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: json['user'],
    );
  }
}

// Modelo para respuesta de refresh
class RefreshResponse {
  final String accessToken;
  final String refreshToken;

  RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory RefreshResponse.fromJson(Map<String, dynamic> json) {
    return RefreshResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }
}

class AuthService {
  static const String baseUrl = 'http://localhost:3000'; // Cambiar según el backend

  // Login con email, password e institución
  Future<LoginResponse?> login(String email, String password, String institutionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'institutionId': institutionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoginResponse.fromJson(data);
      } else {
        debugPrint('Login failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  // Refresh token
  Future<RefreshResponse?> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RefreshResponse.fromJson(data);
      } else {
        debugPrint('Refresh failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Refresh error: $e');
      return null;
    }
  }

  // Logout
  Future<bool> logout(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Logout error: $e');
      return false;
    }
  }

  // Obtener lista de instituciones
  Future<List<Map<String, dynamic>>?> getInstitutions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/institutions'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        debugPrint('Get institutions failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Get institutions error: $e');
      return null;
    }
  }
}