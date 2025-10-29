import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../utils/app_constants.dart';

class PaginatedUserResponse {
  final List<User> users;
  final PaginationInfo pagination;

  PaginatedUserResponse({
    required this.users,
    required this.pagination,
  });
}

class ProfesorService {
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

  /// Obtiene todos los profesores de la institución del admin con paginación
  Future<PaginatedUserResponse?> getAllProfesores(String accessToken, {int? page, int? limit, String? search, bool? activo}) async {
    try {
      final baseUrlValue = await baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (activo != null) queryParams['activo'] = activo.toString();

      final uri = Uri.parse('$baseUrlValue/institution-admin/profesores').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

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

      debugPrint('GET /institution-admin/profesores - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final profesores = (responseData['data'] as List)
              .map((userJson) => User.fromJson(userJson))
              .toList();

          // Crear pagination info desde la respuesta
          final pagination = responseData['pagination'] != null
              ? PaginationInfo.fromJson(responseData['pagination'])
              : PaginationInfo(
                  page: page ?? 1,
                  limit: limit ?? AppConstants.itemsPerPage,
                  total: profesores.length,
                  totalPages: 1,
                  hasNext: false,
                  hasPrev: false,
                );

          return PaginatedUserResponse(users: profesores, pagination: pagination);
        }
      } else {
        debugPrint('Error getting profesores: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting profesores: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene un profesor específico por ID
  Future<User?> getProfesorById(String accessToken, String profesorId) async {
    try {
      final baseUrlValue = await baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/institution-admin/profesores/$profesorId'),
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

      debugPrint('GET /institution-admin/profesores/$profesorId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return User.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error getting profesor: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting profesor: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Crea un nuevo profesor
  Future<User?> createProfesor(String accessToken, CreateUserRequest profesorData) async {
    try {
      final baseUrlValue = await baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/institution-admin/profesores'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'nombres': profesorData.nombres,
          'apellidos': profesorData.apellidos,
          'email': profesorData.email,
          'password': profesorData.password,
          'telefono': profesorData.telefono,
          'grupoId': profesorData.rolEnInstitucion, // Puede ser usado como grupoId
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /institution-admin/profesores - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return User.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error creating profesor: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating profesor: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Actualiza un profesor existente
  Future<User?> updateProfesor(String accessToken, String profesorId, UpdateUserRequest profesorData) async {
    try {
      final baseUrlValue = await baseUrl;
      
      // Solo incluir campos que no son null
      final Map<String, dynamic> updateData = {};
      if (profesorData.nombres != null) updateData['nombres'] = profesorData.nombres;
      if (profesorData.apellidos != null) updateData['apellidos'] = profesorData.apellidos;
      if (profesorData.email != null) updateData['email'] = profesorData.email;
      if (profesorData.telefono != null) updateData['telefono'] = profesorData.telefono;
      if (profesorData.activo != null) updateData['activo'] = profesorData.activo;
      
      final response = await http.put(
        Uri.parse('$baseUrlValue/institution-admin/profesores/$profesorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(updateData),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PUT /institution-admin/profesores/$profesorId - Status: ${response.statusCode}');
      debugPrint('Update data sent: $updateData');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return User.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error updating profesor: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating profesor: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Elimina un profesor (desactivación lógica)
  Future<bool> deleteProfesor(String accessToken, String profesorId) async {
    try {
      final baseUrlValue = await baseUrl;
      final response = await http.delete(
        Uri.parse('$baseUrlValue/institution-admin/profesores/$profesorId'),
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

      debugPrint('DELETE /institution-admin/profesores/$profesorId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint('Error deleting profesor: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting profesor: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Activa/desactiva un profesor
  Future<User?> toggleProfesorStatus(String accessToken, String profesorId) async {
    try {
      final baseUrlValue = await baseUrl;
      final response = await http.patch(
        Uri.parse('$baseUrlValue/institution-admin/profesores/$profesorId/toggle-status'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          // No enviar Content-Type para requests sin body
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PATCH /institution-admin/profesores/$profesorId/toggle-status - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return User.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error toggling profesor status: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error toggling profesor status: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }
}