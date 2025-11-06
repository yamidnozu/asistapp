import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/asistencia_estudiante.dart';

class AsistenciaService {
  /// Registra la asistencia de un estudiante mediante código QR
  Future<bool> registrarAsistencia({
    required String accessToken,
    required String horarioId,
    required String codigoQr,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;

      final response = await http.post(
        Uri.parse('$baseUrlValue/asistencias/registrar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'horarioId': horarioId,
          'codigoQr': codigoQr,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /asistencias/registrar - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ Asistencia registrada exitosamente');
          return true;
        } else {
          throw Exception(responseData['message'] ?? 'Error al registrar asistencia');
        }
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        // 400 puede ser ValidationError (ej: ya registrado) o datos inválidos
        final errorMsg = responseData['message'] ?? 
                        responseData['error'] ?? 
                        'Datos inválidos';
        throw Exception(errorMsg);
      } else if (response.statusCode == 403) {
        final responseData = jsonDecode(response.body);
        final errorMsg = responseData['message'] ?? 
                        responseData['error'] ?? 
                        'No tienes permisos para esta acción';
        throw Exception(errorMsg);
      } else if (response.statusCode == 404) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['error'] ?? 'Horario o estudiante no encontrado');
      } else if (response.statusCode == 500) {
        // Intentar extraer el mensaje de error del servidor
        try {
          final responseData = jsonDecode(response.body);
          final errorMessage = responseData['error'] ?? 
                              responseData['message'] ?? 
                              'Error interno del servidor';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Error interno del servidor');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error al registrar asistencia: $e');
      rethrow;
    }
  }

  /// Registra la asistencia de un estudiante manualmente (sin QR)
  Future<bool> registrarAsistenciaManual({
    required String accessToken,
    required String horarioId,
    required String estudianteId,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;

      final response = await http.post(
        Uri.parse('$baseUrlValue/asistencias/registrar-manual'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'horarioId': horarioId,
          'estudianteId': estudianteId,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /asistencias/registrar-manual - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ Asistencia manual registrada exitosamente');
          return true;
        } else {
          throw Exception(responseData['message'] ?? 'Error al registrar asistencia manual');
        }
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Datos inválidos');
      } else if (response.statusCode == 403) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'No tienes permisos para esta acción');
      } else if (response.statusCode == 404) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Horario o estudiante no encontrado');
      } else if (response.statusCode == 500) {
        // Intentar extraer el mensaje de error del servidor
        try {
          final responseData = jsonDecode(response.body);
          final errorMessage = responseData['error'] ?? 
                              responseData['message'] ?? 
                              'Error interno del servidor';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Error interno del servidor');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error al registrar asistencia manual: $e');
      rethrow;
    }
  }

  /// Obtiene la lista de asistencias para un horario específico
  Future<List<AsistenciaEstudiante>> fetchAsistencias({
    required String accessToken,
    required String horarioId,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;

      final response = await http.get(
        Uri.parse('$baseUrlValue/horarios/$horarioId/asistencias'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('GET /horarios/$horarioId/asistencias - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> asistenciasJson = responseData['data'];
          final asistencias = asistenciasJson
              .map((json) => AsistenciaEstudiante.fromJson(json))
              .toList();
          debugPrint('✅ Obtenidas ${asistencias.length} asistencias');
          return asistencias;
        } else {
          throw Exception(responseData['message'] ?? 'Error al obtener asistencias');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Horario no encontrado');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error al obtener asistencias: $e');
      rethrow;
    }
  }
}