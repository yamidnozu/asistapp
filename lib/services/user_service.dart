import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../config/app_config.dart';
import '../models/user.dart';

class EmailAlreadyExistsException implements Exception {
  final String message;
  EmailAlreadyExistsException(this.message);
  @override
  String toString() => message;
}

class PaginatedUserResponse {
  final List<User> users;
  final PaginationInfo pagination;

  PaginatedUserResponse({
    required this.users,
    required this.pagination,
  });
}

class UserService {
  Map<String, dynamic> _normalizeUserJson(Map<String, dynamic> raw) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(raw);

    // Si el backend ya devuelve `instituciones`, no hacemos nada.
    if (data.containsKey('instituciones')) return data;

    // Manejar `usuarioInstituciones` (forma relacional común)
    if (data.containsKey('usuarioInstituciones') &&
        data['usuarioInstituciones'] is List) {
      final List items = data['usuarioInstituciones'] as List;
      final List<Map<String, dynamic>> instituciones = [];

      for (final item in items) {
        if (item is Map) {
          // Puede venir como { "institucion": { id,nombre }, "rolEnInstitucion":..., "activo": true }
          final institucionObj = item['institucion'];
          String id = '';
          String nombre = '';
          if (institucionObj is Map) {
            id = institucionObj['id']?.toString() ?? '';
            nombre = institucionObj['nombre']?.toString() ?? '';
          } else if (item['institucionId'] != null) {
            id = item['institucionId'].toString();
          }

          if (id.isNotEmpty) {
            instituciones.add({
              'id': id,
              'nombre': nombre,
              'rolEnInstitucion':
                  item['rolEnInstitucion'] ?? item['rol'] ?? null,
              'activo': item['activo'] ?? true,
            });
          }
        }
      }

      data['instituciones'] = instituciones;
      return data;
    }

    // Otras formas planas: buscar campos como 'institucionId' y 'institucionNombre'
    if (data.containsKey('institucionId')) {
      final id = data['institucionId']?.toString() ?? '';
      final nombre = data['institucionNombre']?.toString() ?? '';
      if (id.isNotEmpty) {
        data['instituciones'] = [
          {
            'id': id,
            'nombre': nombre,
            'rolEnInstitucion': data['rolEnInstitucion'] ?? data['rol'] ?? null,
            'activo': data['activo'] ?? true,
          }
        ];
      }
    }

    return data;
  }
  // Usar AppConfig.baseUrl para obtener la URL de la API centralizada

  Future<PaginatedUserResponse?> getAllUsers(String accessToken,
      {int? page,
      int? limit,
      bool? activo,
      String? search,
      List<String>? roles}) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (activo != null) queryParams['activo'] = activo.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (roles != null && roles.isNotEmpty)
        queryParams['rol'] = roles.join(',');

      final uri = Uri.parse('$baseUrlValue/usuarios')
          .replace(queryParameters: queryParams);
      debugPrint('UserService.getAllUsers URL: $uri');

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
              .map((userJson) => User.fromJson(
                  _normalizeUserJson(userJson as Map<String, dynamic>)))
              .toList();
          final pagination =
              PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedUserResponse(users: users, pagination: pagination);
        }
      } else {
        debugPrint(
            'Error getting users: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting users: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  Future<User?> getUserById(String accessToken, String userId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
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
        debugPrint('GET /usuarios/$userId - body: ${response.body}');
        if (responseData['success'] == true) {
          return User.fromJson(
              _normalizeUserJson(responseData['data'] as Map<String, dynamic>));
        }
      } else {
        debugPrint(
            'Error getting user: ${response.statusCode} - ${response.body}');
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
  Future<PaginatedUserResponse?> getUsersByRole(String accessToken, String role,
      {int? page, int? limit, bool? activo, String? search}) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (activo != null) queryParams['activo'] = activo.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrlValue/usuarios/rol/$role')
          .replace(queryParameters: queryParams);

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

      debugPrint('GET /usuarios/rol/$role - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final users = (responseData['data'] as List)
              .map((userJson) => User.fromJson(
                  _normalizeUserJson(userJson as Map<String, dynamic>)))
              .toList();
          final pagination =
              PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedUserResponse(users: users, pagination: pagination);
        }
      } else {
        debugPrint(
            'Error getting users by role: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting users by role: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene usuarios por institución con paginación
  Future<PaginatedUserResponse?> getUsersByInstitution(
      String accessToken, String institutionId,
      {int? page,
      int limit = 5,
      String? role,
      bool? activo,
      String? search}) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      if (role != null && role.isNotEmpty) queryParams['rol'] = role;
      if (activo != null) queryParams['activo'] = activo.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrlValue/usuarios/institucion/$institutionId')
          .replace(queryParameters: queryParams);
      debugPrint('UserService.getUsersByInstitution URL: $uri');

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

      debugPrint(
          'GET /usuarios/institucion/$institutionId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final users = (responseData['data'] as List)
              .map((userJson) => User.fromJson(
                  _normalizeUserJson(userJson as Map<String, dynamic>)))
              .toList();
          final pagination =
              PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedUserResponse(users: users, pagination: pagination);
        }
      } else {
        debugPrint(
            'Error getting users by institution: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting users by institution: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene administradores de una institución (sin paginación)
  Future<List<User>?> getAdminsByInstitution(
      String accessToken, String institutionId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final uri =
          Uri.parse('$baseUrlValue/instituciones/$institutionId/admins');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final list = (responseData['data'] as List)
              .map((item) {
                // El backend puede devolver la relación con campo 'usuario' o un objeto plano
                if (item is Map && item.containsKey('usuario')) {
                  return User.fromJson(item['usuario']);
                }
                if (item is Map && item.containsKey('email')) {
                  // Construir estructura mínima compatible con User.fromJson
                  final usuarioJson = {
                    'id': item['usuarioId'] ?? item['id'],
                    'email': item['email'],
                    'nombres': item['nombres'],
                    'apellidos': item['apellidos'],
                    'rol': 'admin_institucion',
                    'telefono': item['telefono'],
                    'activo': item['activo'] ?? true,
                    'usuarioInstituciones': [
                      {
                        'institucion': {
                          'id': item['institucionId'],
                          'nombre': '',
                        },
                        'rolEnInstitucion': item['rolEnInstitucion'],
                        'activo': item['activo'] ?? true,
                      }
                    ],
                  };
                  return User.fromJson(_normalizeUserJson(usuarioJson));
                }
                return null;
              })
              .whereType<User>()
              .toList();

          return list;
        }
      }
      return null;
    } catch (e, st) {
      debugPrint('Error getting admins by institution: $e');
      debugPrint('StackTrace: $st');
      return null;
    }
  }

  /// Asigna un usuario existente como admin de institución
  Future<User?> assignAdminToInstitution(
      String accessToken, String institutionId, String userId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final uri =
          Uri.parse('$baseUrlValue/instituciones/$institutionId/admins');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({'userId': userId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          // Intentar parsear usuario
          if (data is Map && data['id'] != null) {
            return User.fromJson(data as Map<String, dynamic>);
          }
        }
      }
      return null;
    } catch (e, st) {
      debugPrint('Error assigning admin to institution: $e');
      debugPrint('StackTrace: $st');
      return null;
    }
  }

  /// Remueve un admin de institución
  Future<bool?> removeAdminFromInstitution(
      String accessToken, String institutionId, String userId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final uri = Uri.parse(
          '$baseUrlValue/instituciones/$institutionId/admins/$userId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      }
      return null;
    } catch (e, st) {
      debugPrint('Error removing admin from institution: $e');
      debugPrint('StackTrace: $st');
      return null;
    }
  }

  /// Cambia la contraseña de un usuario (solo para admins)
  Future<bool> changePassword(
      String accessToken, String userId, String newPassword) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final uri = Uri.parse('$baseUrlValue/usuarios/$userId/change-password');

      final response = await http
          .patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'newPassword': newPassword}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint(
          'PATCH /usuarios/$userId/change-password - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint(
            'Error changePassword: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, st) {
      debugPrint('Error changePassword: $e');
      debugPrint('StackTrace: $st');
      return false;
    }
  }

  /// Crea un nuevo usuario
  Future<User?> createUser(
      String accessToken, CreateUserRequest userData) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http
          .post(
        Uri.parse('$baseUrlValue/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(userData.toJson()),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /usuarios - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return User.fromJson(
              _normalizeUserJson(responseData['data'] as Map<String, dynamic>));
        }
      } else if (response.statusCode == 409) {
        throw EmailAlreadyExistsException('El email ya está en uso');
      } else {
        debugPrint(
            'Error creating user: ${response.statusCode} - ${response.body}');
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
  Future<User?> updateUser(
      String accessToken, String userId, UpdateUserRequest userData) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http
          .put(
        Uri.parse('$baseUrlValue/usuarios/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(userData.toJson()),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PUT /usuarios/$userId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint(
            'PUT /usuarios/$userId - request: ${jsonEncode(userData.toJson())}');
        debugPrint('PUT /usuarios/$userId - body: ${response.body}');
        if (responseData['success'] == true) {
          // Use the API response as the source of truth and normalize user JSON
          final data = responseData['data'] as Map<String, dynamic>;
          return User.fromJson(_normalizeUserJson(data));
        }
      } else if (response.statusCode == 409) {
        throw EmailAlreadyExistsException('El email ya está en uso');
      } else {
        debugPrint(
            'Error updating user: ${response.statusCode} - ${response.body}');
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
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.delete(
        Uri.parse('$baseUrlValue/usuarios/$userId'),
        headers: {
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
        debugPrint(
            'Error deleting user: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting user: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Genera una contraseña segura aleatoria
  String generateSecurePassword({int length = 12}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}
