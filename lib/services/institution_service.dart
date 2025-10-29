import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/institution.dart';
import '../models/user.dart';

class PaginatedInstitutionResponse {
  final List<Institution> institutions;
  final PaginationInfo pagination;

  PaginatedInstitutionResponse({
    required this.institutions,
    required this.pagination,
  });
}

class InstitutionService {
  static Future<String> _getLocalIp() async {
    try {
      if (kIsWeb) {
        return 'localhost';
      }
      return '192.168.20.22';
    } catch (e) {
      debugPrint('Error obteniendo IP local: $e');
      return 'localhost';
    }
  }

  static Future<String> get baseUrl async {
    final ip = await _getLocalIp();
    return 'http://$ip:3000';
  }

  /// Obtiene todas las instituciones con paginación y filtros
  Future<PaginatedInstitutionResponse?> getAllInstitutions(String accessToken, {int? page, int? limit, bool? activa, String? search}) async {
    try {
      final baseUrlValue = await baseUrl;
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
      final baseUrlValue = await baseUrl;
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
    required String codigo,
    String? direccion,
    String? telefono,
    String? email,
  }) async {
    try {
      final baseUrlValue = await baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/instituciones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'nombre': nombre,
          'codigo': codigo,
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
    String? codigo,
    String? direccion,
    String? telefono,
    String? email,
    bool? activa,
  }) async {
    try {
      final baseUrlValue = await baseUrl;
      final response = await http.put(
        Uri.parse('$baseUrlValue/instituciones/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          if (nombre != null) 'nombre': nombre,
          if (codigo != null) 'codigo': codigo,
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
      final baseUrlValue = await baseUrl;
      final response = await http.delete(
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
}