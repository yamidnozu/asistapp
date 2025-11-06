import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class EstudianteService {
  /// Obtiene la información del estudiante incluyendo el código QR
  Future<Map<String, dynamic>?> getEstudianteInfo({
    required String accessToken,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;

      final response = await http.get(
        Uri.parse('$baseUrlValue/estudiantes/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('GET /estudiantes/me - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data'] as Map<String, dynamic>;
        } else {
          throw Exception(responseData['message'] ?? 'Error al obtener información del estudiante');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Perfil de estudiante no encontrado');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error al obtener información del estudiante: $e');
      rethrow;
    }
  }
}