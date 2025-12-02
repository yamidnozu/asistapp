import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/institution.dart';
import '../models/user.dart';
import '../config/app_config.dart';

class PaginatedInstitutionResponse {
  final List<Institution> institutions;
  final PaginationInfo pagination;

  PaginatedInstitutionResponse({
    required this.institutions,
    required this.pagination,
  });
}

class InstitutionService {
  // Usar AppConfig.baseUrl para obtener la URL de la API centralizada

  /// Obtiene todas las instituciones con paginación y filtros
  Future<PaginatedInstitutionResponse?> getAllInstitutions(String accessToken, {int? page, int? limit, bool? activa, String? search}) async {
    try {
  final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (activa != null) queryParams['activa'] = activa.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      
      final uri = Uri.parse('$baseUrlValue/instituciones').replace(queryParameters: queryParams);
      
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

  debugPrint('GET /instituciones - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
    debugPrint('GET /instituciones - data[0]: ${(responseData['data'] as List).isNotEmpty ? (responseData['data'] as List)[0] : 'empty'}');
    final institutions = (responseData['data'] as List)
              .map((institutionJson) => Institution.fromJson(institutionJson))
              .toList();
          final pagination = PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedInstitutionResponse(institutions: institutions, pagination: pagination);
        }
      } else {
        debugPrint('Error getting institutions: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting institutions: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene una institución por ID
  Future<Institution?> getInstitutionById(String accessToken, String id) async {
    try {
  final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/instituciones/$id'),
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

  debugPrint('GET /instituciones/$id - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('GET /instituciones/$id - data: ${responseData['data']}');
        if (responseData['success'] == true) {
          return Institution.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error getting institution: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting institution: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }



  /// Crea una nueva institución
  Future<Institution?> createInstitution(
    String accessToken, {
    required String nombre,
    String? direccion,
    String? telefono,
    String? email,
  }) async {
    try {
  final baseUrlValue = AppConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/instituciones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'nombre': nombre,
          if (direccion != null) 'direccion': direccion,
          if (telefono != null) 'telefono': telefono,
          if (email != null) 'email': email,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /instituciones - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return Institution.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error creating institution: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating institution: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Actualiza una institución
  Future<Institution?> updateInstitution(
    String accessToken,
    String id, {
    String? nombre,
    String? direccion,
    String? telefono,
    String? email,
    bool? activa,
  }) async {
    try {
  final baseUrlValue = AppConfig.baseUrl;
      final response = await http.put(
        Uri.parse('$baseUrlValue/instituciones/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          if (nombre != null) 'nombre': nombre,
          if (direccion != null) 'direccion': direccion,
          if (telefono != null) 'telefono': telefono,
          if (email != null) 'email': email,
          if (activa != null) 'activa': activa,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PUT /instituciones/$id - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return Institution.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error updating institution: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating institution: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Elimina una institución (desactivación lógica)
  Future<bool> deleteInstitution(String accessToken, String id) async {
    try {
  final baseUrlValue = AppConfig.baseUrl;
      final response = await http.delete(
        Uri.parse('$baseUrlValue/instituciones/$id'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('DELETE /instituciones/$id - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint('Error deleting institution: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting institution: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Actualiza la configuracion de notificaciones de una institucion
  Future<bool> updateNotificationConfig(
    String accessToken,
    String institutionId, {
    required bool notificacionesActivas,
    required String canalNotificacion,
    required String modoNotificacionAsistencia,
    String? horaDisparoNotificacion,
    int? umbralInasistenciasAlerta,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      // La ruta de notificaciones usa /api/institutions (no /instituciones)
      final url = '$baseUrlValue/api/institutions/$institutionId/notification-config';
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'notificacionesActivas': notificacionesActivas,
          'canalNotificacion': canalNotificacion,
          'modoNotificacionAsistencia': modoNotificacionAsistencia,
          if (horaDisparoNotificacion != null) 'horaDisparoNotificacion': horaDisparoNotificacion,
          if (umbralInasistenciasAlerta != null) 'umbralInasistenciasAlerta': umbralInasistenciasAlerta,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PUT $url - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint('Error updating notification config: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating notification config: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }
}