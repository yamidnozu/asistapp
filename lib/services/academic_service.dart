import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/grupo.dart';
import '../models/materia.dart';
import '../models/horario.dart';
import '../models/clase_del_dia.dart';
import '../models/user.dart'; // Para PaginationInfo

class PaginatedGruposResponse {
  final List<Grupo> grupos;
  final PaginationInfo pagination;

  PaginatedGruposResponse({
    required this.grupos,
    required this.pagination,
  });
}

class PaginatedMateriasResponse {
  final List<Materia> materias;
  final PaginationInfo pagination;

  PaginatedMateriasResponse({
    required this.materias,
    required this.pagination,
  });
}

class PaginatedHorariosResponse {
  final List<Horario> horarios;
  final PaginationInfo pagination;

  PaginatedHorariosResponse({
    required this.horarios,
    required this.pagination,
  });
}

class AcademicService {
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

  // ===== MATERIAS =====

  /// Obtiene todas las materias con paginación y filtros
  Future<PaginatedMateriasResponse?> getMaterias(String accessToken, {int? page, int? limit, String? search}) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrlValue/materias').replace(queryParameters: queryParams);

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

      debugPrint('GET /materias - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final materias = (responseData['data'] as List)
              .map((materiaJson) => Materia.fromJson(materiaJson))
              .toList();
          final pagination = PaginationInfo.fromJson(responseData['pagination']);
          return PaginatedMateriasResponse(materias: materias, pagination: pagination);
        }
      } else {
        debugPrint('Error getting materias: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting materias: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Obtiene una materia por ID
  Future<Materia?> getMateriaById(String accessToken, String materiaId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/materias/$materiaId'),
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

      debugPrint('GET /materias/$materiaId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return Materia.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error getting materia: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting materia: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Crea una nueva materia
  Future<Materia?> createMateria(String accessToken, CreateMateriaRequest materiaData) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrlValue/materias'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(materiaData.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST /materias - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return Materia.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error creating materia: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating materia: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Actualiza una materia
  Future<Materia?> updateMateria(String accessToken, String materiaId, UpdateMateriaRequest materiaData) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.put(
        Uri.parse('$baseUrlValue/materias/$materiaId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(materiaData.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PUT /materias/$materiaId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return Materia.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error updating materia: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating materia: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
    return null;
  }

  /// Elimina una materia
  Future<bool> deleteMateria(String accessToken, String materiaId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.delete(
        Uri.parse('$baseUrlValue/materias/$materiaId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('DELETE /materias/$materiaId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint('Error deleting materia: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting materia: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

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
        if (responseData['success'] == true) {
          return (responseData['data'] as List)
              .map((horarioJson) => Horario.fromJson(horarioJson))
              .toList();
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
    return null;
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
          return Horario.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Error creating horario: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating horario: $e');
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
          return Horario.fromJson(responseData['data']);
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

  // ===== DASHBOARD PROFESOR =====

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

class CreateMateriaRequest {
  final String nombre;
  final String? codigo;

  CreateMateriaRequest({
    required this.nombre,
    this.codigo,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'codigo': codigo,
    };
  }
}

class UpdateMateriaRequest {
  final String nombre;
  final String? codigo;

  UpdateMateriaRequest({
    required this.nombre,
    this.codigo,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'codigo': codigo,
    };
  }
}

class CreateHorarioRequest {
  final String periodoId;
  final String grupoId;
  final String materiaId;
  final String? profesorId;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;

  CreateHorarioRequest({
    required this.periodoId,
    required this.grupoId,
    required this.materiaId,
    this.profesorId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
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