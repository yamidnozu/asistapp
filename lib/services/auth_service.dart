import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

// Modelo para respuesta de login
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
    // El backend devuelve la respuesta dentro de 'data'
    final data = json['data'] ?? json;
    
    // El backend devuelve 'usuario', no 'user'
    final usuario = data['usuario'] ?? data['user'];
    
    return LoginResponse(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: usuario is Map<String, dynamic> ? usuario : {},
      expiresIn: data['expiresIn'] as int?,
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
  // Función para obtener la IP local automáticamente
  static Future<String> _getLocalIp() async {
    try {
      // En desarrollo web, usar localhost
      if (kIsWeb) {
        return 'localhost';
      }
      
      // Para móvil/desktop, intentar detectar IP local
      // Por ahora usamos la IP conocida, pero esto se puede mejorar
      return '192.168.20.22';
    } catch (e) {
      debugPrint('Error obteniendo IP local: $e');
      return 'localhost'; // fallback
    }
  }

  // URL base que se obtiene dinámicamente
  static Future<String> get baseUrl async {
    final ip = await _getLocalIp();
    return 'http://$ip:3000';
  }

  // Login con email y password
  Future<LoginResponse?> login(String email, String password) async {
    try {
      final baseUrlValue = await baseUrl;
      final url = '$baseUrlValue/auth/login';
      
      // 🔍 LOG: Mostrar hacia dónde se está apuntando
      debugPrint('🌐 ========== AUTH SERVICE DEBUG ==========');
      debugPrint('📍 URL: $url');
      debugPrint('📧 Email: $email');
      debugPrint('🔑 Password: ${password.substring(0, 3)}***'); // Solo los primeros 3 caracteres
      debugPrint('📤 Enviando petición POST...');
      
      final requestBody = jsonEncode({
        'email': email,
        'password': password,
      });
      
      debugPrint('📦 Body: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ TIMEOUT: No se pudo conectar al servidor en 10 segundos');
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('📥 Respuesta recibida:');
      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Body: ${response.body}');
      debugPrint('========================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // El backend envuelve la respuesta en 'data'
        final data = responseData['data'] ?? responseData;
        
        // Verificar si la respuesta tiene el formato esperado
        if (data['accessToken'] == null || data['refreshToken'] == null) {
          debugPrint('❌ ERROR: Respuesta incompleta del servidor');
          debugPrint('   accessToken: ${data['accessToken']}');
          debugPrint('   refreshToken: ${data['refreshToken']}');
          debugPrint('   usuario: ${data['usuario']}');
          return null;
        }
        
        debugPrint('✅ Login exitoso!');
        return LoginResponse.fromJson(responseData);
      } else {
        debugPrint('❌ Login failed: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ========== LOGIN ERROR ==========');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('====================================');
      return null;
    }
  }

  // Refresh token
  Future<RefreshResponse?> refreshToken(String refreshToken) async {
    try {
      final baseUrlValue = await baseUrl;
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

  // Logout
  Future<bool> logout(String refreshToken) async {
    try {
      final baseUrlValue = await baseUrl;
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

  // Obtener instituciones del usuario autenticado
  Future<List<Map<String, dynamic>>?> getUserInstitutions(String accessToken) async {
    try {
      final baseUrlValue = await baseUrl;
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