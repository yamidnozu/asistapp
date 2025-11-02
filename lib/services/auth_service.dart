import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;
  final int? expiresIn;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {

    final data = json['data'] ?? json;

    final usuario = data['usuario'] ?? data['user'];
    
    return LoginResponse(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: usuario is Map<String, dynamic> ? usuario : {},
      expiresIn: data['expiresIn'] as int?,
    );
  }
}

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

  // Usar AppConfig.baseUrl para obtener la URL de la API centralizada

  Future<LoginResponse?> login(String email, String password) async {
    try {
  final baseUrlValue = AppConfig.baseUrl;
      final url = '$baseUrlValue/auth/login';

      
      final requestBody = jsonEncode({
        'email': email,
        'password': password,
      });
      
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Body: ${response.body}');
      debugPrint('========================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final data = responseData['data'] ?? responseData;

        if (data['accessToken'] == null || data['refreshToken'] == null) {
          debugPrint('   accessToken: ${data['accessToken']}');
          debugPrint('   refreshToken: ${data['refreshToken']}');
          debugPrint('   usuario: ${data['usuario']}');
          return null;
        }
        
        return LoginResponse.fromJson(responseData);
      } else {
        debugPrint('   Response: ${response.body}');
        // Intentar extraer mensaje claro del servidor y lanzarlo para que la UI lo muestre
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          final serverMessage = errorData['message'] ?? errorData['error'] ?? (errorData['data'] is Map ? errorData['data']['message'] : null) ?? response.body;
          throw Exception(serverMessage);
        } catch (parseError) {
          // Si no es JSON válido, lanzar el body crudo
          throw Exception(response.body);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('====================================');
      // Propagar la excepción para que el caller (AuthProvider / UI) pueda mostrarla
      rethrow;
    }
  }

  Future<RefreshResponse?> refreshToken(String refreshToken) async {
    try {
  final baseUrlValue = AppConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/auth/refresh'),
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

  Future<bool> logout(String refreshToken) async {
    try {
  final baseUrlValue = AppConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/auth/logout'),
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

  Future<List<Map<String, dynamic>>?> getUserInstitutions(String accessToken) async {
    try {
  final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/auth/instituciones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final institutions = data['data'] as List;
          return institutions.map((e) => e as Map<String, dynamic>).toList();
        }
      } else {
        debugPrint('Get user institutions failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Get user institutions error: $e');
      return null;
    }
    return null;
  }
}