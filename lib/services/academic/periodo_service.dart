import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import '../../models/grupo.dart';
import '../../models/user.dart';

class PaginatedPeriodosAcademicosResponse {
  final List<PeriodoAcademico> periodosAcademicos;
  final PaginationInfo pagination;

  PaginatedPeriodosAcademicosResponse({
    required this.periodosAcademicos,
    required this.pagination,
  });
}

class PeriodoService {
  // ===== PERIODOS ACADÉMICOS =====

  /// Obtiene todos los períodos académicos con paginación
  Future<PaginatedPeriodosAcademicosResponse?> getPeriodosAcademicos(String accessToken, {int? page, int? limit}) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$baseUrlValue/periodos-academicos').replace(queryParameters: queryParams);

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

      debugPrint('GET /periodos-academicos - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final periodos = (responseData['data'] as List)
              .map((periodoJson) => PeriodoAcademico.fromJson(periodoJson))
              .toList();
          final pagination = PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedPeriodosAcademicosResponse(periodosAcademicos: periodos, pagination: pagination);
        }
      } else {
        debugPrint('Error getting periodos académicos: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting periodos académicos: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene períodos académicos activos
  Future<List<PeriodoAcademico>?> getPeriodosActivos(String accessToken) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/periodos-academicos/activos'),
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

      debugPrint('GET /periodos-academicos/activos - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return (responseData['data'] as List)
              .map((periodoJson) => PeriodoAcademico.fromJson(periodoJson))
              .toList();
        }
      } else {
        debugPrint('Error getting periodos activos: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting periodos activos: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene un período académico por ID
  Future<PeriodoAcademico?> getPeriodoAcademicoById(String accessToken, String periodoId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/periodos-academicos/$periodoId'),
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

      debugPrint('GET /periodos-academicos/$periodoId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return PeriodoAcademico.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error getting período académico: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting período académico: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Crea un nuevo período académico
  Future<PeriodoAcademico?> createPeriodoAcademico(String accessToken, CreatePeriodoAcademicoRequest periodoData) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/periodos-academicos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(periodoData.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /periodos-academicos - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return PeriodoAcademico.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error creating período académico: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating período académico: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Actualiza un período académico
  Future<PeriodoAcademico?> updatePeriodoAcademico(String accessToken, String periodoId, UpdatePeriodoAcademicoRequest periodoData) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.put(
        Uri.parse('$baseUrlValue/periodos-academicos/$periodoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(periodoData.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PUT /periodos-academicos/$periodoId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return PeriodoAcademico.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error updating período académico: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating período académico: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Elimina un período académico
  Future<bool> deletePeriodoAcademico(String accessToken, String periodoId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.delete(
        Uri.parse('$baseUrlValue/periodos-academicos/$periodoId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('DELETE /periodos-academicos/$periodoId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint('Error deleting período académico: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting período académico: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Activa/desactiva un período académico
  Future<PeriodoAcademico?> togglePeriodoStatus(String accessToken, String periodoId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.patch(
        Uri.parse('$baseUrlValue/periodos-academicos/$periodoId/toggle-status'),
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

      debugPrint('PATCH /periodos-academicos/$periodoId/toggle-status - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return PeriodoAcademico.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error toggling período status: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error toggling período status: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }
}

// ===== REQUEST CLASSES =====

class CreatePeriodoAcademicoRequest {
  final String nombre;
  final String fechaInicio;
  final String fechaFin;

  CreatePeriodoAcademicoRequest({
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
    };
  }
}

class UpdatePeriodoAcademicoRequest {
  final String nombre;
  final String fechaInicio;
  final String fechaFin;

  UpdatePeriodoAcademicoRequest({
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
    };
  }
}