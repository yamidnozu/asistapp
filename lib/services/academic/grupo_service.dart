import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import '../../models/grupo.dart';
import '../../models/user.dart';

class PaginatedGruposResponse {
  final List<Grupo> grupos;
  final PaginationInfo pagination;

  PaginatedGruposResponse({
    required this.grupos,
    required this.pagination,
  });
}

class PaginatedUsersResponse {
  final List<User> users;
  final PaginationInfo pagination;

  PaginatedUsersResponse({
    required this.users,
    required this.pagination,
  });
}

class GrupoService {
  // ===== GRUPOS =====

  /// Obtiene todos los grupos con paginación y filtros
  Future<PaginatedGruposResponse?> getGrupos(String accessToken, {int? page, int? limit, String? periodoId, String? search}) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (periodoId != null && periodoId.isNotEmpty) queryParams['periodoId'] = periodoId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrlValue/grupos').replace(queryParameters: queryParams);

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

      debugPrint('GET /grupos - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final grupos = (responseData['data'] as List)
              .map((grupoJson) => Grupo.fromJson(grupoJson))
              .toList();
          final pagination = PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedGruposResponse(grupos: grupos, pagination: pagination);
        }
      } else {
        debugPrint('Error getting grupos: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting grupos: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene un grupo por ID
  Future<Grupo?> getGrupoById(String accessToken, String grupoId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/grupos/$grupoId'),
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

      debugPrint('GET /grupos/$grupoId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return Grupo.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error getting grupo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting grupo: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Crea un nuevo grupo
  Future<Grupo?> createGrupo(String accessToken, CreateGrupoRequest grupoData) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/grupos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(grupoData.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /grupos - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return Grupo.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error creating grupo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating grupo: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Actualiza un grupo
  Future<Grupo?> updateGrupo(String accessToken, String grupoId, UpdateGrupoRequest grupoData) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.put(
        Uri.parse('$baseUrlValue/grupos/$grupoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(grupoData.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PUT /grupos/$grupoId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return Grupo.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error updating grupo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating grupo: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Elimina un grupo
  Future<bool> deleteGrupo(String accessToken, String grupoId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.delete(
        Uri.parse('$baseUrlValue/grupos/$grupoId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('DELETE /grupos/$grupoId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint('Error deleting grupo: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting grupo: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  // ===== STUDENTS =====

  /// Obtiene estudiantes asignados a un grupo
  Future<PaginatedUsersResponse?> getEstudiantesByGrupo(String accessToken, String grupoId, {int? page, int? limit}) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$baseUrlValue/grupos/$grupoId/estudiantes').replace(queryParameters: queryParams);

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

      debugPrint('GET /grupos/$grupoId/estudiantes - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final users = (responseData['data'] as List).map((userJson) {
            // Backend historically devolvía estudiante con campos anidados
            // en `usuario` (usuario.nombres/apellidos). Normalizar para
            // que `User.fromJson` funcione independientemente de la forma.
            if (userJson is Map && userJson['usuario'] is Map) {
              final usuario = userJson['usuario'] as Map<String, dynamic>;
              // Solo asignar si las claves no existen en la raíz
              userJson['nombres'] ??= usuario['nombres'];
              userJson['apellidos'] ??= usuario['apellidos'];
              userJson['email'] ??= usuario['email'];
            }
            return User.fromJson(userJson);
          }).toList();
          final pagination = PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedUsersResponse(users: users, pagination: pagination);
        }
      } else {
        debugPrint('Error getting estudiantes by grupo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting estudiantes by grupo: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene estudiantes sin asignar a ningún grupo
  Future<PaginatedUsersResponse?> getEstudiantesSinAsignar(String accessToken, {int? page, int? limit}) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$baseUrlValue/grupos/estudiantes-sin-asignar').replace(queryParameters: queryParams);

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

      debugPrint('GET /grupos/estudiantes-sin-asignar - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final users = (responseData['data'] as List).map((userJson) {
            if (userJson is Map && userJson['usuario'] is Map) {
              final usuario = userJson['usuario'] as Map<String, dynamic>;
              userJson['nombres'] ??= usuario['nombres'];
              userJson['apellidos'] ??= usuario['apellidos'];
              userJson['email'] ??= usuario['email'];
            }
            return User.fromJson(userJson);
          }).toList();
          final pagination = PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedUsersResponse(users: users, pagination: pagination);
        }
      } else {
        debugPrint('Error getting estudiantes sin asignar: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting estudiantes sin asignar: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Asigna un estudiante a un grupo
  Future<bool> asignarEstudianteAGrupo(String accessToken, String grupoId, String estudianteId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/grupos/$grupoId/asignar-estudiante'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'estudianteId': estudianteId}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /grupos/$grupoId/asignar-estudiante - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint('Error asignando estudiante a grupo: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error asignando estudiante a grupo: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Desasigna un estudiante de un grupo
  Future<bool> desasignarEstudianteDeGrupo(String accessToken, String grupoId, String estudianteId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/grupos/$grupoId/desasignar-estudiante'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'estudianteId': estudianteId}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /grupos/$grupoId/desasignar-estudiante - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint('Error desasignando estudiante de grupo: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error desasignando estudiante de grupo: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }
}

// ===== REQUEST CLASSES =====

class CreateGrupoRequest {
  final String nombre;
  final String grado;
  final String? seccion;
  final String periodoId;

  CreateGrupoRequest({
    required this.nombre,
    required this.grado,
    this.seccion,
    required this.periodoId,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'grado': grado,
      'seccion': seccion,
      'periodoId': periodoId,
    };
  }
}

class UpdateGrupoRequest {
  final String nombre;
  final String grado;
  final String? seccion;

  UpdateGrupoRequest({
    required this.nombre,
    required this.grado,
    this.seccion,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'grado': grado,
      'seccion': seccion,
    };
  }
}