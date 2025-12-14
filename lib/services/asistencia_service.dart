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

      final response = await http
          .post(
        Uri.parse('$baseUrlValue/asistencias/registrar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'horarioId': horarioId,
          'codigoQr': codigoQr,
        }),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint(
          'POST /asistencias/registrar - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ Asistencia registrada exitosamente');
          return true;
        } else {
          throw Exception(
              responseData['message'] ?? 'Error al registrar asistencia');
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
        throw Exception(
            responseData['error'] ?? 'Horario o estudiante no encontrado');
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
  /// Ahora acepta estado personalizado para registro inteligente
  Future<bool> registrarAsistenciaManual({
    required String accessToken,
    required String horarioId,
    required String estudianteId,
    String? estado,
    String? observacion,
    bool? justificada,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;

      final body = <String, dynamic>{
        'horarioId': horarioId,
        'estudianteId': estudianteId,
      };
      if (estado != null) body['estado'] = estado;
      if (observacion != null && observacion.isNotEmpty)
        body['observacion'] = observacion;
      if (justificada != null) body['justificada'] = justificada;

      final response = await http
          .post(
        Uri.parse('$baseUrlValue/asistencias/registrar-manual'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint(
          'POST /asistencias/registrar-manual - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ Asistencia manual registrada exitosamente');
          return true;
        } else {
          throw Exception(responseData['message'] ??
              'Error al registrar asistencia manual');
        }
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Datos inválidos');
      } else if (response.statusCode == 403) {
        final responseData = jsonDecode(response.body);
        throw Exception(
            responseData['message'] ?? 'No tienes permisos para esta acción');
      } else if (response.statusCode == 404) {
        final responseData = jsonDecode(response.body);
        throw Exception(
            responseData['message'] ?? 'Horario o estudiante no encontrado');
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

  /// Obtiene la lista de estudiantes del grupo con su estado de asistencia para el día actual.
  /// Usa el endpoint GET /horarios/:horarioId/asistencias que devuelve TODOS los estudiantes
  /// del grupo, independientemente de si ya tienen asistencia registrada o no.
  Future<List<AsistenciaEstudiante>> getAsistencias({
    required String accessToken,
    required String horarioId,
    DateTime? date,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;

      // CORREGIDO: Usar la ruta de horarios que trae la lista de estudiantes del grupo
      // independientemente de si ya tienen asistencia registrada o no.
      String url = '$baseUrlValue/horarios/$horarioId/asistencias';
      if (date != null) {
        final dateStr = date.toIso8601String().split('T')[0];
        url += '?date=$dateStr';
      }

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

      debugPrint(
          'GET /horarios/$horarioId/asistencias - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> asistenciasJson = responseData['data'];

          // DEBUG: Log raw response to verify id is being returned
          for (var json in asistenciasJson) {
            debugPrint(
                '📥 Raw data - id: ${json['id']}, estudiante: ${json['estudiante']?['id']}, estado: ${json['estado']}');
          }

          // Mapeo especial porque este endpoint devuelve una estructura diferente:
          // { id: null/string, estudiante: {...}, estado: null/string, observacion: null/string, fechaRegistro: ... }
          final asistencias = asistenciasJson.map<AsistenciaEstudiante>((json) {
            final estudiante = json['estudiante'];
            return AsistenciaEstudiante(
              id: json[
                  'id'], // ID de la asistencia - null si no se ha tomado lista
              estudianteId: estudiante['id'],
              nombres: estudiante['nombres'] ?? '',
              apellidos: estudiante['apellidos'] ?? '',
              identificacion: estudiante['identificacion'] ?? '',
              estado: json['estado'], // Será null si no se ha tomado lista
              observaciones: json['observacion'], // Observación del registro
              fechaRegistro: json['fechaRegistro'] != null
                  ? DateTime.parse(json['fechaRegistro'].toString())
                  : null,
            );
          }).toList();

          debugPrint(
              '✅ Obtenidos ${asistencias.length} estudiantes para la lista');
          return asistencias;
        } else {
          throw Exception(
              responseData['message'] ?? 'Error al obtener asistencias');
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

      final response = await http
          .put(
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
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint(
          'PUT /asistencias/$asistenciaId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ Asistencia actualizada exitosamente');
          return true;
        } else {
          throw Exception(
              responseData['message'] ?? 'Error al actualizar asistencia');
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

  /// Dispara un trigger manual de notificaciones (ej: último día/semana/clase)
  Future<Map<String, dynamic>> triggerManualNotifications({
    required String accessToken,
    required String institutionId,
    String? classId,
    required String scope, // LAST_DAY, LAST_WEEK, LAST_CLASS
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;

      final response = await http
          .post(
        Uri.parse('$baseUrlValue/api/notifications/manual-trigger'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'institutionId': institutionId,
          'classId': classId,
          'scope': scope,
        }),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint(
          'POST /api/notifications/manual-trigger - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic>) return responseData;
        return {'success': true, 'data': responseData};
      } else {
        final responseData = jsonDecode(response.body);
        final errorMsg = responseData['message'] ??
            responseData['error'] ??
            'Error al disparar notificaciones';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('❌ Error al disparar notificaciones: $e');
      rethrow;
    }
  }

  /// Obtiene las asistencias del estudiante autenticado
  /// Endpoint: GET /asistencias/estudiante
  Future<List<Map<String, dynamic>>?> getAsistenciasEstudiante({
    required String accessToken,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;

      final response = await http.get(
        Uri.parse('$baseUrlValue/asistencias/estudiante'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint(
          'GET /asistencias/estudiante - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return (responseData['data'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        }
        return null;
      } else {
        debugPrint(
            'Error getting asistencias estudiante: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error al obtener asistencias del estudiante: $e');
      return null;
    }
  }
}
