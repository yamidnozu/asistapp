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
  Future<List<AsistenciaEstudiante>> getAsistencias({
    required String accessToken,
    required String horarioId,
    DateTime? date,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      // El endpoint correcto es GET /asistencias con query params
      final queryParams = <String, String>{
        'horarioId': horarioId,
      };
      if (date != null) {
        queryParams['fecha'] = date.toIso8601String().split('T')[0];
      }
      final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '$baseUrlValue/asistencias?$queryString';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('GET /asistencias?horarioId=$horarioId - Status: ${response.statusCode}');

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
  /// Actualiza una asistencia existente (estado, observación, justificación)
  Future<bool> updateAsistencia({
    required String accessToken,
    required String asistenciaId,
    required String estado,
    String? observacion,
    bool? justificada,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;

      final response = await http.put(
        Uri.parse('$baseUrlValue/asistencias/$asistenciaId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'estado': estado,
          'observacion': observacion,
          'justificada': justificada,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PUT /asistencias/$asistenciaId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ Asistencia actualizada exitosamente');
          return true;
        } else {
          throw Exception(responseData['message'] ?? 'Error al actualizar asistencia');
        }
      } else {
        final responseData = jsonDecode(response.body);
        final errorMsg = responseData['message'] ?? 
                        responseData['error'] ?? 
                        'Error al actualizar asistencia';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('❌ Error al actualizar asistencia: $e');
      rethrow;
    }
  }
}