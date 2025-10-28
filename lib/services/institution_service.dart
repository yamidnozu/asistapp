import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/institution.dart';

class InstitutionResponse {
  final bool success;
  final String? message;
  final Institution? data;
  final List<Institution>? dataList;

  InstitutionResponse({
    required this.success,
    this.message,
    this.data,
    this.dataList,
  });

  factory InstitutionResponse.fromJson(Map<String, dynamic> json) {
    return InstitutionResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && json['data'] is! List
          ? Institution.fromJson(json['data'])
          : null,
      dataList: json['data'] != null && json['data'] is List
          ? (json['data'] as List).map((e) => Institution.fromJson(e)).toList()
          : null,
    );
  }
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

  /// Obtiene todas las instituciones
  Future<List<Institution>> getAllInstitutions(String accessToken) async {
    try {
      final baseUrlValue = await baseUrl;
      final url = '$baseUrlValue/instituciones';

      final response = await http.get(
        Uri.parse(url),
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

      debugPrint('GET $url - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('Response body: ${response.body}');
        final institutionResponse = InstitutionResponse.fromJson(jsonDecode(response.body));
        debugPrint('InstitutionResponse success: ${institutionResponse.success}');
        debugPrint('InstitutionResponse dataList length: ${institutionResponse.dataList?.length ?? 0}');
        if (institutionResponse.success && institutionResponse.dataList != null) {
          debugPrint('Returning ${institutionResponse.dataList!.length} institutions');
          return institutionResponse.dataList!;
        } else {
          debugPrint('No success or no dataList: ${institutionResponse.message}');
          throw Exception(institutionResponse.message ?? 'Error al obtener instituciones');
        }
      } else {
        debugPrint('Error response: ${response.body}');
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting institutions: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception('Error al obtener instituciones: $e');
    }
  }

  /// Obtiene una institución por ID
  Future<Institution> getInstitutionById(String accessToken, String id) async {
    try {
      final baseUrlValue = await baseUrl;
      final url = '$baseUrlValue/instituciones/$id';

      final response = await http.get(
        Uri.parse(url),
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

      debugPrint('GET $url - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final institutionResponse = InstitutionResponse.fromJson(jsonDecode(response.body));
        if (institutionResponse.success && institutionResponse.data != null) {
          return institutionResponse.data!;
        } else {
          throw Exception(institutionResponse.message ?? 'Institución no encontrada');
        }
      } else {
        debugPrint('Error response: ${response.body}');
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting institution: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception('Error al obtener institución: $e');
    }
  }

  /// Crea una nueva institución
  Future<Institution> createInstitution(
    String accessToken, {
    required String nombre,
    required String codigo,
    String? direccion,
    String? telefono,
    String? email,
  }) async {
    try {
      final baseUrlValue = await baseUrl;
      final url = '$baseUrlValue/instituciones';

      final requestBody = jsonEncode({
        'nombre': nombre,
        'codigo': codigo,
        if (direccion != null) 'direccion': direccion,
        if (telefono != null) 'telefono': telefono,
        if (email != null) 'email': email,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: requestBody,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('POST $url - Status: ${response.statusCode}');
      debugPrint('Request body: $requestBody');

      if (response.statusCode == 201) {
        final institutionResponse = InstitutionResponse.fromJson(jsonDecode(response.body));
        if (institutionResponse.success && institutionResponse.data != null) {
          return institutionResponse.data!;
        } else {
          throw Exception(institutionResponse.message ?? 'Error al crear institución');
        }
      } else {
        debugPrint('Error response: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating institution: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception('Error al crear institución: $e');
    }
  }

  /// Actualiza una institución
  Future<Institution> updateInstitution(
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
      final url = '$baseUrlValue/instituciones/$id';

      final requestBody = jsonEncode({
        if (nombre != null) 'nombre': nombre,
        if (codigo != null) 'codigo': codigo,
        if (direccion != null) 'direccion': direccion,
        if (telefono != null) 'telefono': telefono,
        if (email != null) 'email': email,
        if (activa != null) 'activa': activa,
      });

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: requestBody,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no responde');
        },
      );

      debugPrint('PUT $url - Status: ${response.statusCode}');
      debugPrint('Request body: $requestBody');

      if (response.statusCode == 200) {
        final institutionResponse = InstitutionResponse.fromJson(jsonDecode(response.body));
        if (institutionResponse.success && institutionResponse.data != null) {
          return institutionResponse.data!;
        } else {
          throw Exception(institutionResponse.message ?? 'Error al actualizar institución');
        }
      } else {
        debugPrint('Error response: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating institution: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception('Error al actualizar institución: $e');
    }
  }

  /// Elimina una institución
  Future<void> deleteInstitution(String accessToken, String id) async {
    try {
      final baseUrlValue = await baseUrl;
      final url = '$baseUrlValue/instituciones/$id';

      final response = await http.delete(
        Uri.parse(url),
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

      debugPrint('DELETE $url - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return;
        } else {
          throw Exception(responseData['message'] ?? 'Error al eliminar institución');
        }
      } else {
        debugPrint('Error response: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting institution: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception('Error al eliminar institución: $e');
    }
  }
}