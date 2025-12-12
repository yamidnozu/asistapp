import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/notificacion_in_app.dart';

/// Respuesta de hijo del acudiente
class HijoResponse {
  final String id;
  final String usuarioId;
  final String nombres;
  final String apellidos;
  final String identificacion;
  final String parentesco;
  final bool esPrincipal;
  final GrupoResumen? grupo;
  final EstadisticasResumen estadisticasResumen;

  HijoResponse({
    required this.id,
    required this.usuarioId,
    required this.nombres,
    required this.apellidos,
    required this.identificacion,
    required this.parentesco,
    required this.esPrincipal,
    this.grupo,
    required this.estadisticasResumen,
  });

  String get nombreCompleto => '$nombres $apellidos';

  factory HijoResponse.fromJson(Map<String, dynamic> json) {
    return HijoResponse(
      id: json['id'] as String,
      usuarioId: json['usuarioId'] as String,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      identificacion: json['identificacion'] as String,
      parentesco: json['parentesco'] as String,
      esPrincipal: json['esPrincipal'] as bool? ?? false,
      grupo:
          json['grupo'] != null ? GrupoResumen.fromJson(json['grupo']) : null,
      estadisticasResumen:
          EstadisticasResumen.fromJson(json['estadisticasResumen']),
    );
  }
}

class GrupoResumen {
  final String id;
  final String nombre;
  final String grado;
  final String? seccion;

  GrupoResumen({
    required this.id,
    required this.nombre,
    required this.grado,
    this.seccion,
  });

  factory GrupoResumen.fromJson(Map<String, dynamic> json) {
    return GrupoResumen(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      grado: json['grado'] as String,
      seccion: json['seccion'] as String?,
    );
  }
}

class EstadisticasResumen {
  final int totalClases;
  final int presentes;
  final int ausentes;
  final int tardanzas;
  final int justificados;
  final int porcentajeAsistencia;

  EstadisticasResumen({
    required this.totalClases,
    required this.presentes,
    required this.ausentes,
    required this.tardanzas,
    required this.justificados,
    required this.porcentajeAsistencia,
  });

  factory EstadisticasResumen.fromJson(Map<String, dynamic> json) {
    return EstadisticasResumen(
      totalClases: json['totalClases'] as int? ?? 0,
      presentes: json['presentes'] as int? ?? 0,
      ausentes: json['ausentes'] as int? ?? 0,
      tardanzas: json['tardanzas'] as int? ?? 0,
      justificados: json['justificados'] as int? ?? 0,
      porcentajeAsistencia: json['porcentajeAsistencia'] as int? ?? 100,
    );
  }
}

class AsistenciaHistorialItem {
  final String id;
  final DateTime fecha;
  final String estado;
  final DateTime horaRegistro;
  final String tipoRegistro;
  final String? observaciones;
  final MateriaResumen materia;
  final ProfesorResumen profesor;
  final HorarioResumen horario;

  AsistenciaHistorialItem({
    required this.id,
    required this.fecha,
    required this.estado,
    required this.horaRegistro,
    required this.tipoRegistro,
    this.observaciones,
    required this.materia,
    required this.profesor,
    required this.horario,
  });

  factory AsistenciaHistorialItem.fromJson(Map<String, dynamic> json) {
    return AsistenciaHistorialItem(
      id: json['id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      estado: json['estado'] as String,
      horaRegistro: DateTime.parse(json['horaRegistro'] as String),
      tipoRegistro: json['tipoRegistro'] as String,
      observaciones: json['observaciones'] as String?,
      materia: MateriaResumen.fromJson(json['materia']),
      profesor: ProfesorResumen.fromJson(json['profesor']),
      horario: HorarioResumen.fromJson(json['horario']),
    );
  }
}

class MateriaResumen {
  final String id;
  final String nombre;

  MateriaResumen({required this.id, required this.nombre});

  factory MateriaResumen.fromJson(Map<String, dynamic> json) {
    return MateriaResumen(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );
  }
}

class ProfesorResumen {
  final String id;
  final String nombres;
  final String apellidos;

  ProfesorResumen(
      {required this.id, required this.nombres, required this.apellidos});

  String get nombreCompleto => '$nombres $apellidos';

  factory ProfesorResumen.fromJson(Map<String, dynamic> json) {
    return ProfesorResumen(
      id: json['id'] as String? ?? '',
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
    );
  }
}

class HorarioResumen {
  final String horaInicio;
  final String horaFin;

  HorarioResumen({required this.horaInicio, required this.horaFin});

  factory HorarioResumen.fromJson(Map<String, dynamic> json) {
    return HorarioResumen(
      horaInicio: json['horaInicio'] as String,
      horaFin: json['horaFin'] as String,
    );
  }
}

class EstadisticaPorMateria {
  final String materiaId;
  final String materiaNombre;
  final int totalClases;
  final int ausentes;
  final int tardanzas;
  final int porcentajeAsistencia;

  EstadisticaPorMateria({
    required this.materiaId,
    required this.materiaNombre,
    required this.totalClases,
    required this.ausentes,
    required this.tardanzas,
    required this.porcentajeAsistencia,
  });

  factory EstadisticaPorMateria.fromJson(Map<String, dynamic> json) {
    return EstadisticaPorMateria(
      materiaId: json['materiaId'] as String,
      materiaNombre: json['materiaNombre'] as String,
      totalClases: json['totalClases'] as int? ?? 0,
      ausentes: json['ausentes'] as int? ?? 0,
      tardanzas: json['tardanzas'] as int? ?? 0,
      porcentajeAsistencia: json['porcentajeAsistencia'] as int? ?? 100,
    );
  }
}

class TendenciaSemanal {
  final String semana;
  final int presentes;
  final int ausentes;
  final int tardanzas;

  TendenciaSemanal({
    required this.semana,
    required this.presentes,
    required this.ausentes,
    required this.tardanzas,
  });

  factory TendenciaSemanal.fromJson(Map<String, dynamic> json) {
    return TendenciaSemanal(
      semana: json['semana'] as String,
      presentes: json['presentes'] as int? ?? 0,
      ausentes: json['ausentes'] as int? ?? 0,
      tardanzas: json['tardanzas'] as int? ?? 0,
    );
  }
}

class EstadisticasCompletas {
  final EstadisticasResumen resumen;
  final List<EstadisticaPorMateria> porMateria;
  final List<TendenciaSemanal> tendenciaSemanal;
  final List<AsistenciaHistorialItem> ultimasFaltas;

  EstadisticasCompletas({
    required this.resumen,
    required this.porMateria,
    required this.tendenciaSemanal,
    required this.ultimasFaltas,
  });

  factory EstadisticasCompletas.fromJson(Map<String, dynamic> json) {
    return EstadisticasCompletas(
      resumen: EstadisticasResumen.fromJson(json['resumen']),
      porMateria: (json['porMateria'] as List)
          .map((item) => EstadisticaPorMateria.fromJson(item))
          .toList(),
      tendenciaSemanal: (json['tendenciaSemanal'] as List)
          .map((item) => TendenciaSemanal.fromJson(item))
          .toList(),
      ultimasFaltas: (json['ultimasFaltas'] as List)
          .map((item) => AsistenciaHistorialItem.fromJson(item))
          .toList(),
    );
  }
}

/// Servicio para las operaciones del acudiente
class AcudienteService {
  /// Obtiene la lista de hijos del acudiente
  Future<List<HijoResponse>?> getHijos(String accessToken) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/acudiente/hijos'),
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

      debugPrint('GET /acudiente/hijos - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return (responseData['data'] as List)
              .map((item) => HijoResponse.fromJson(item))
              .toList();
        }
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting hijos: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Obtiene el detalle de un hijo
  Future<HijoResponse?> getHijoDetalle(
      String accessToken, String estudianteId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/acudiente/hijos/$estudianteId'),
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
          'GET /acudiente/hijos/$estudianteId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return HijoResponse.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting hijo detalle: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Obtiene el historial de asistencias de un hijo
  Future<({List<AsistenciaHistorialItem> asistencias, int total})?>
      getHistorialAsistencias(
    String accessToken,
    String estudianteId, {
    int page = 1,
    int limit = 20,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (fechaInicio != null) {
        queryParams['fechaInicio'] = fechaInicio.toIso8601String();
      }
      if (fechaFin != null) {
        queryParams['fechaFin'] = fechaFin.toIso8601String();
      }
      if (estado != null) {
        queryParams['estado'] = estado;
      }

      final uri =
          Uri.parse('$baseUrlValue/acudiente/hijos/$estudianteId/asistencias')
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

      debugPrint(
          'GET /acudiente/hijos/$estudianteId/asistencias - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final asistencias = (responseData['data'] as List)
              .map((item) => AsistenciaHistorialItem.fromJson(item))
              .toList();
          final total = responseData['pagination']['total'] as int? ?? 0;
          return (asistencias: asistencias, total: total);
        }
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting historial asistencias: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Obtiene estadísticas completas de un hijo
  Future<EstadisticasCompletas?> getEstadisticas(
      String accessToken, String estudianteId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/acudiente/hijos/$estudianteId/estadisticas'),
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
          'GET /acudiente/hijos/$estudianteId/estadisticas - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return EstadisticasCompletas.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting estadisticas: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Obtiene las notificaciones del acudiente
  Future<({List<NotificacionInApp> notificaciones, int noLeidas, int total})?>
      getNotificaciones(
    String accessToken, {
    int page = 1,
    int limit = 20,
    bool soloNoLeidas = false,
  }) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (soloNoLeidas) 'soloNoLeidas': 'true',
      };

      final uri = Uri.parse('$baseUrlValue/acudiente/notificaciones')
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

      debugPrint(
          'GET /acudiente/notificaciones - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final notificaciones = (responseData['data'] as List)
              .map((item) => NotificacionInApp.fromJson(item))
              .toList();
          final noLeidas = responseData['noLeidas'] as int? ?? 0;
          final total = responseData['pagination']['total'] as int? ?? 0;
          return (
            notificaciones: notificaciones,
            noLeidas: noLeidas,
            total: total
          );
        }
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting notificaciones: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Cuenta las notificaciones no leídas
  Future<int> contarNoLeidas(String accessToken) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/acudiente/notificaciones/no-leidas/count'),
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

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data']['count'] as int? ?? 0;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error counting unread notifications: $e');
      return 0;
    }
  }

  /// Marca una notificación como leída
  Future<bool> marcarComoLeida(
      String accessToken, String notificacionId) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.put(
        Uri.parse(
            '$baseUrlValue/acudiente/notificaciones/$notificacionId/leer'),
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

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<int> marcarTodasComoLeidas(String accessToken) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.put(
        Uri.parse('$baseUrlValue/acudiente/notificaciones/leer-todas'),
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

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['data']['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return 0;
    }
  }

  /// Registra un dispositivo para notificaciones push
  Future<(bool success, String debugMessage)> registrarDispositivo(
    String accessToken,
    String token,
    String plataforma, {
    String? modelo,
  }) async {
    final StringBuffer debugBuffer = StringBuffer();
    debugBuffer.writeln('--- DEBUG REGISTRO DISPOSITIVO ---');

    try {
      final baseUrlValue = AppConfig.baseUrl;
      final uri = Uri.parse('$baseUrlValue/acudiente/dispositivo');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };
      final body = jsonEncode({
        'token': token,
        'plataforma': plataforma,
        if (modelo != null) 'modelo': modelo,
      });

      debugBuffer.writeln('URL: $uri');
      debugBuffer.writeln('Headers: ${headers['Content-Type']}');
      debugBuffer.writeln('Authorization: Bearer ${accessToken.length > 20 ? accessToken.substring(0,20) + '...' : accessToken}');
      debugBuffer.writeln('Body: $body');
      debugBuffer.writeln('Intentando petición POST...');

      final response = await http
          .post(
        uri,
        headers: headers,
        body: body,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugBuffer.writeln('Respuesta recibida:');
      debugBuffer.writeln('Status: ${response.statusCode}');
      debugBuffer.writeln('Body: ${response.body}');

      final bool success = response.statusCode == 201;
      debugBuffer.writeln('--- FIN DEBUG REGISTRO DISPOSITIVO ---');
      return (success, debugBuffer.toString());
    } catch (e, stackTrace) {
      debugBuffer.writeln('--- ERROR DURANTE REGISTRO DE DISPOSITIVO ---');
      debugBuffer.writeln('Excepción: $e');
      debugBuffer.writeln('Stack Trace: $stackTrace');
      debugBuffer.writeln('--- FIN ERROR REGISTRO DISPOSITIVO ---');
      return (false, debugBuffer.toString());
    }
  }

  // ============================================================
  // MÉTODOS ADMIN: Vincular/Desvincular estudiantes
  // ============================================================

  /// Vincula un estudiante a un acudiente (uso admin)
  Future<void> vincularEstudiante(
    String accessToken,
    String acudienteId,
    String estudianteId,
    String parentesco,
  ) async {
    final baseUrlValue = AppConfig.baseUrl;
    final response = await http
        .post(
      Uri.parse('$baseUrlValue/admin/acudientes/$acudienteId/vincular'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'estudianteId': estudianteId,
        'parentesco': parentesco,
      }),
    )
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Timeout: El servidor no responde');
      },
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al vincular estudiante');
    }
  }

  /// Desvincula un estudiante de un acudiente (uso admin)
  Future<void> desvincularEstudiante(
    String accessToken,
    String acudienteId,
    String estudianteId,
  ) async {
    final baseUrlValue = AppConfig.baseUrl;
    final response = await http.delete(
      Uri.parse(
          '$baseUrlValue/admin/acudientes/$acudienteId/desvincular/$estudianteId'),
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

    if (response.statusCode != 200 && response.statusCode != 204) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al desvincular estudiante');
    }
  }

  /// Obtiene los acudientes de un estudiante (uso admin)
  Future<List<AcudienteVinculadoResponse>> getAcudientesDeEstudiante(
    String accessToken,
    String estudianteId,
  ) async {
    try {
      final baseUrlValue = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrlValue/admin/estudiantes/$estudianteId/acudientes'),
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
          'GET /admin/estudiantes/$estudianteId/acudientes - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return (responseData['data'] as List)
              .map((item) => AcudienteVinculadoResponse.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint('Error getting acudientes de estudiante: $e');
      debugPrint('StackTrace: $stackTrace');
      return [];
    }
  }
}

/// Modelo para acudiente vinculado en respuestas del admin
class AcudienteVinculadoResponse {
  final String id;
  final String nombres;
  final String apellidos;
  final String? email;
  final String? telefono;
  final String parentesco;
  final bool esPrincipal;

  AcudienteVinculadoResponse({
    required this.id,
    required this.nombres,
    required this.apellidos,
    this.email,
    this.telefono,
    required this.parentesco,
    required this.esPrincipal,
  });

  String get nombreCompleto => '$nombres $apellidos';

  factory AcudienteVinculadoResponse.fromJson(Map<String, dynamic> json) {
    final acudiente = json['acudiente'] as Map<String, dynamic>?;
    return AcudienteVinculadoResponse(
      id: acudiente?['id'] ?? json['acudienteId'] ?? '',
      nombres: acudiente?['nombres'] ?? json['nombres'] ?? '',
      apellidos: acudiente?['apellidos'] ?? json['apellidos'] ?? '',
      email: acudiente?['email'] ?? json['email'],
      telefono: acudiente?['telefono'] ?? json['telefono'],
      parentesco: json['parentesco'] ?? 'otro',
      esPrincipal: json['esPrincipal'] ?? false,
    );
  }
}
