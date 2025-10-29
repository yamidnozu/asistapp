import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class PaginatedUserResponse {
  final List<User> users;
  final PaginationInfo pagination;

  PaginatedUserResponse({
    required this.users,
    required this.pagination,
  });
}

class UserService {
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

  /// Obtiene todos los usuarios con paginación
  Future<PaginatedUserResponse?> getAllUsers(String accessToken, {int? page, int? limit, String? role}) async {
    try {
      final baseUrlValue = await baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (role != null && role.isNotEmpty) queryParams['rol'] = role;
      
      final uri = Uri.parse('$baseUrlValue/usuarios').replace(queryParameters: queryParams);
      
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

      debugPrint('GET /usuarios - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final users = (responseData['data'] as List)
              .map((userJson) => User.fromJson(userJson))
              .toList();
          final pagination = PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedUserResponse(users: users, pagination: pagination);
        }
      } else {
        debugPrint('Error getting users: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting users: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene un usuario por ID
  Future<User?> getUserById(String accessToken, String userId) async {
    try {
      final baseUrlValue = await baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/usuarios/$userId'),
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

      debugPrint('GET /usuarios/$userId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return User.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error getting user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting user: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene usuarios por rol con paginación
  /// NOTA: Esta ruta no existe en el backend, usar getUsersByInstitution y filtrar localmente
  Future<PaginatedUserResponse?> getUsersByRole(String accessToken, String role, {int? page, int? limit}) async {
    // Temporal: usar la ruta de institución y filtrar por rol localmente
    // TODO: Implementar la ruta /usuarios/rol/:role en el backend
    debugPrint('WARNING: getUsersByRole using institution route as fallback');
    
    // Obtener el ID de institución del token o de alguna manera
    // Por ahora, devolver null para forzar el uso de la ruta de institución
    debugPrint('getUsersByRole: Route /usuarios/rol/$role not implemented, returning null');
    return null;
  }

  /// Obtiene usuarios por institución con paginación
  Future<PaginatedUserResponse?> getUsersByInstitution(String accessToken, String institutionId, {int? page, int limit = 5, String? role, bool? activo, String? search}) async {
    try {
      final baseUrlValue = await baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      if (role != null && role.isNotEmpty) queryParams['rol'] = role;
      if (activo != null) queryParams['activo'] = activo.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      
      final uri = Uri.parse('$baseUrlValue/usuarios/institucion/$institutionId').replace(queryParameters: queryParams);
      
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

      debugPrint('GET /usuarios/institucion/$institutionId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final users = (responseData['data'] as List)
              .map((userJson) => User.fromJson(userJson))
              .toList();
          final pagination = PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedUserResponse(users: users, pagination: pagination);
        }
      } else {
        debugPrint('Error getting users by institution: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting users by institution: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Crea un nuevo usuario
  Future<User?> createUser(String accessToken, CreateUserRequest userData) async {
    try {
      final baseUrlValue = await baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(userData.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /usuarios - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return User.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error creating user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating user: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Actualiza un usuario
  Future<User?> updateUser(String accessToken, String userId, UpdateUserRequest userData) async {
    try {
      final baseUrlValue = await baseUrl;
      final response = await http.put(
        Uri.parse('$baseUrlValue/usuarios/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(userData.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PUT /usuarios/$userId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return User.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error updating user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating user: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Elimina un usuario (desactivación lógica)
  Future<bool> deleteUser(String accessToken, String userId) async {
    try {
      final baseUrlValue = await baseUrl;
      final response = await http.delete(
        Uri.parse('$baseUrlValue/usuarios/$userId'),
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

      debugPrint('DELETE /usuarios/$userId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint('Error deleting user: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting user: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }
}