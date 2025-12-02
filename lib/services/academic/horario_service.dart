import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import '../../models/horario.dart';
import '../../models/clase_del_dia.dart';
import '../../models/user.dart';

class PaginatedHorariosResponse {
  final List<Horario> horarios;
  final PaginationInfo pagination;

  PaginatedHorariosResponse({
    required this.horarios,
    required this.pagination,
  });
}

class HorarioService {
  // ===== HORARIOS =====

  /// Obtiene todos los horarios con paginación y filtros
  Future<PaginatedHorariosResponse?> getHorarios(String accessToken, {int? page, int? limit, String? grupoId, String? periodoId}) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (grupoId != null && grupoId.isNotEmpty) queryParams['grupoId'] = grupoId;
      if (periodoId != null && periodoId.isNotEmpty) queryParams['periodoId'] = periodoId;

      final uri = Uri.parse('$baseUrlValue/horarios').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('GET /horarios - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final horarios = (responseData['data'] as List)
              .map((horarioJson) => Horario.fromJson(horarioJson))
              .toList();
          final pagination = PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedHorariosResponse(horarios: horarios, pagination: pagination);
        }
      } else {
        debugPrint('Error getting horarios: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting horarios: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene horarios por grupo específico
  Future<List<Horario>?> getHorariosPorGrupo(String accessToken, String grupoId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final uri = Uri.parse('$baseUrlValue/horarios').replace(queryParameters: {'grupoId': grupoId});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('GET /horarios?grupoId=$grupoId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Response data: ${responseData.toString().substring(0, 500)}');
        if (responseData['success'] == true && responseData['data'] != null) {
          try {
            final List<dynamic> horariosList = responseData['data'] as List<dynamic>;
            debugPrint('Parsing ${horariosList.length} horarios...');

            final result = <Horario>[];
            for (int i = 0; i < horariosList.length; i++) {
              try {
                debugPrint('=== Iniciando parseo de horario $i ===');
                final horarioJson = horariosList[i] as Map<String, dynamic>;
                debugPrint('Horario JSON keys: ${horarioJson.keys.toList()}');
                debugPrint('Horario grado: ${horarioJson['grupo']?['grado']}');
                debugPrint('Horario materia nombre: ${horarioJson['materia']?['nombre']}');
                debugPrint('Horario profesor: ${horarioJson['profesor']}');

                final horario = Horario.fromJson(horarioJson);
                result.add(horario);
                debugPrint('✅ Horario $i parseado exitosamente');
              } catch (e, stackTrace) {
                debugPrint('❌ Error parseando horario $i: $e');
                debugPrint('StackTrace: $stackTrace');
                debugPrint('Data: ${horariosList[i]}');
              }
            }
            debugPrint('Total horarios cargados: ${result.length}');
            return result;
          } catch (e) {
            debugPrint('Error parseando lista de horarios: $e');
            return null;
          }
        } else {
          debugPrint('Response sin success o data vacía');
          return null;
        }
      } else {
        debugPrint('Error getting horarios por grupo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting horarios por grupo: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Obtiene un horario por ID
  Future<Horario?> getHorarioById(String accessToken, String horarioId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/horarios/$horarioId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('GET /horarios/$horarioId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return Horario.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error getting horario: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting horario: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Crea un nuevo horario
  Future<Horario?> createHorario(String accessToken, CreateHorarioRequest horarioData) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/horarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(horarioData.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /horarios - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          try {
            // Defensive: asegurar que `grupo.periodoAcademico` exista antes de parsear
            final rawData = responseData['data'];
            if (rawData is Map<String, dynamic>) {
              final horarioJson = Map<String, dynamic>.from(rawData);
              if (horarioJson['grupo'] != null && horarioJson['grupo'] is Map<String, dynamic>) {
                final grupoJson = Map<String, dynamic>.from(horarioJson['grupo']);
                if ((grupoJson['periodoAcademico'] == null || grupoJson['periodoAcademico'] is! Map) && horarioJson['periodoAcademico'] != null) {
                  grupoJson['periodoAcademico'] = horarioJson['periodoAcademico'];
                }
                horarioJson['grupo'] = grupoJson;
                try {
                  return Horario.fromJson(horarioJson);
                } catch (e) {
                  debugPrint('Error parseando Horario (create): $e');
                  debugPrint('Response body: ${response.body}');
                  return null;
                }
              }
            }
            // Fallback: intentar parsear directamente
            return Horario.fromJson(responseData['data']);
          } catch (e) {
            debugPrint('Error procesando respuesta de createHorario: $e');
            debugPrint('Response body: ${response.body}');
            return null;
          }
        }
      } else {
        debugPrint('Error updating horario: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating horario: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Actualiza un horario
  Future<Horario?> updateHorario(String accessToken, String horarioId, UpdateHorarioRequest horarioData) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.put(
        Uri.parse('$baseUrlValue/horarios/$horarioId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(horarioData.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PUT /horarios/$horarioId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          try {
            final rawData = responseData['data'];
            if (rawData is Map<String, dynamic>) {
              final horarioJson = Map<String, dynamic>.from(rawData);
              if (horarioJson['grupo'] != null && horarioJson['grupo'] is Map<String, dynamic>) {
                final grupoJson = Map<String, dynamic>.from(horarioJson['grupo']);
                if ((grupoJson['periodoAcademico'] == null || grupoJson['periodoAcademico'] is! Map) && horarioJson['periodoAcademico'] != null) {
                  grupoJson['periodoAcademico'] = horarioJson['periodoAcademico'];
                }
                horarioJson['grupo'] = grupoJson;
                try {
                  return Horario.fromJson(horarioJson);
                } catch (e) {
                  debugPrint('Error parseando Horario (getById): $e');
                  debugPrint('Response body: ${response.body}');
                  return null;
                }
              }
            }
            return Horario.fromJson(responseData['data']);
          } catch (e) {
            debugPrint('Error procesando respuesta getHorarioById: $e');
            debugPrint('Response body: ${response.body}');
            return null;
          }
        }
      } else {
        // Extraer error del backend y lanzarlo con código y razón si están presentes
        debugPrint('Error updating horario: ${response.statusCode} - ${response.body}');
        String serverMessage = response.body;
        String code = '';
        String reason = '';
        dynamic meta;
        try {
          final parsed = jsonDecode(response.body);
          serverMessage = parsed['error'] ?? parsed['message'] ?? response.body;
          code = parsed['code'] ?? '';
          reason = parsed['reason'] ?? '';
          meta = parsed['meta'] ?? parsed['errorMeta'];
        } catch (_) {}
        throw Exception('${response.statusCode} - $serverMessage - $code - $reason - ${meta != null ? jsonEncode(meta) : ''}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating horario: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Elimina un horario
  Future<bool> deleteHorario(String accessToken, String horarioId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.delete(
        Uri.parse('$baseUrlValue/horarios/$horarioId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('DELETE /horarios/$horarioId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint('Error deleting horario: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting horario: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Obtiene las clases del día actual para el profesor
  Future<List<ClaseDelDia>?> getMisClasesDelDia(String accessToken) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/profesores/dashboard/clases-hoy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('GET /profesores/dashboard/clases-hoy - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return (responseData['data'] as List)
              .map((claseJson) => ClaseDelDia.fromJson(claseJson))
              .toList();
        }
      } else {
        debugPrint('Error getting clases del dia: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting clases del dia: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene las clases de un día específico para el profesor
  Future<List<ClaseDelDia>?> getMisClasesPorDia(String accessToken, int diaSemana) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/profesores/dashboard/clases/$diaSemana'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('GET /profesores/dashboard/clases/$diaSemana - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return (responseData['data'] as List)
              .map((claseJson) => ClaseDelDia.fromJson(claseJson))
              .toList();
        }
      } else {
        debugPrint('Error getting clases por dia: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting clases por dia: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene el horario semanal completo del profesor
  Future<List<ClaseDelDia>?> getMiHorarioSemanal(String accessToken) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/profesores/dashboard/horario-semanal'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('GET /profesores/dashboard/horario-semanal - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return (responseData['data'] as List)
              .map((claseJson) => ClaseDelDia.fromJson(claseJson))
              .toList();
        }
      } else {
        debugPrint('Error getting horario semanal: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting horario semanal: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }
}

// ===== REQUEST CLASSES =====

class CreateHorarioRequest {
  final String periodoId;
  final String grupoId;
  final String materiaId;
  final String? profesorId;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final String institucionId;

  CreateHorarioRequest({
    required this.periodoId,
    required this.grupoId,
    required this.materiaId,
    this.profesorId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.institucionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'periodoId': periodoId,
      'grupoId': grupoId,
      'materiaId': materiaId,
      'profesorId': profesorId,
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'institucionId': institucionId,
    };
  }
}

class UpdateHorarioRequest {
  final String? profesorId;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;

  UpdateHorarioRequest({
    this.profesorId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  Map<String, dynamic> toJson() {
    return {
      'profesorId': profesorId,
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
    };
  }
}