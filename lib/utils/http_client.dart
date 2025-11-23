import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// ✅ Cliente HTTP centralizado con interceptor automático para 401
/// 
/// Beneficios:
/// - Manejo automático de tokens expirados (401)
/// - Cierre de sesión y redirección automática al login
/// - Logging centralizado de requests/responses
/// - Headers consistentes en todas las peticiones
class AppHttpClient {
  final BuildContext? context;
  final http.Client _client = http.Client();

  AppHttpClient({this.context});

  /// Headers por defecto para todas las peticiones
  Map<String, String> _getDefaultHeaders({Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Maneja la respuesta HTTP y detecta errores 401
  void _handleResponse(http.Response response, Uri url) {
    debugPrint('📡 HTTP ${response.statusCode} ${url.path}');

    if (response.statusCode == 401) {
      debugPrint('🔒 Token expirado o inválido - cerrando sesión');
      _forceLogout('Tu sesión ha expirado. Por favor inicia sesión nuevamente.');
      throw UnauthorizedException('Token expirado o inválido');
    }

    // Manejar 403 específicamente para "Institución inactiva" u otros bloqueos de acceso
    if (response.statusCode == 403) {
      final body = jsonDecode(response.body);
      final errorMsg = body['error'] ?? '';
      
      if (errorMsg.toString().contains('inactiva')) {
        debugPrint('🔒 Institución inactiva - cerrando sesión');
        _forceLogout('La institución ha sido desactivada. Contacta al administrador.');
        throw UnauthorizedException('Institución inactiva');
      }
    }
  }

  void _forceLogout(String message) {
    if (context != null && context!.mounted) {
      // Cerrar sesión en el provider
      final authProvider = Provider.of<AuthProvider>(context!, listen: false);
      authProvider.logout();

      // Mostrar mensaje al usuario
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// GET request con manejo automático de 401
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    try {
      debugPrint('📤 GET ${url.path}');
      
      final response = await _client.get(
        url,
        headers: _getDefaultHeaders(additionalHeaders: headers),
      );

      _handleResponse(response, url);
      return response;
    } catch (e) {
      debugPrint('❌ Error en GET ${url.path}: $e');
      rethrow;
    }
  }

  /// POST request con manejo automático de 401
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      debugPrint('📤 POST ${url.path}');
      
      final response = await _client.post(
        url,
        headers: _getDefaultHeaders(additionalHeaders: headers),
        body: body,
        encoding: encoding,
      );

      _handleResponse(response, url);
      return response;
    } catch (e) {
      debugPrint('❌ Error en POST ${url.path}: $e');
      rethrow;
    }
  }

  /// PUT request con manejo automático de 401
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      debugPrint('📤 PUT ${url.path}');
      
      final response = await _client.put(
        url,
        headers: _getDefaultHeaders(additionalHeaders: headers),
        body: body,
        encoding: encoding,
      );

      _handleResponse(response, url);
      return response;
    } catch (e) {
      debugPrint('❌ Error en PUT ${url.path}: $e');
      rethrow;
    }
  }

  /// DELETE request con manejo automático de 401
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      debugPrint('📤 DELETE ${url.path}');
      
      final response = await _client.delete(
        url,
        headers: _getDefaultHeaders(additionalHeaders: headers),
        body: body,
        encoding: encoding,
      );

      _handleResponse(response, url);
      return response;
    } catch (e) {
      debugPrint('❌ Error en DELETE ${url.path}: $e');
      rethrow;
    }
  }

  /// PATCH request con manejo automático de 401
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      debugPrint('📤 PATCH ${url.path}');
      
      final response = await _client.patch(
        url,
        headers: _getDefaultHeaders(additionalHeaders: headers),
        body: body,
        encoding: encoding,
      );

      _handleResponse(response, url);
      return response;
    } catch (e) {
      debugPrint('❌ Error en PATCH ${url.path}: $e');
      rethrow;
    }
  }

  /// Cierra el cliente HTTP
  void close() {
    _client.close();
  }
}

/// Excepción personalizada para errores 401
class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// ✅ EJEMPLO DE USO:
/// 
/// ```dart
/// // En un servicio o widget:
/// final httpClient = AppHttpClient(context: context);
/// 
/// try {
///   final response = await httpClient.get(
///     Uri.parse('${AppConfig.apiBaseUrl}/api/horarios'),
///     headers: {'Authorization': 'Bearer $token'},
///   );
///   
///   if (response.statusCode == 200) {
///     final data = jsonDecode(response.body);
///     // Procesar datos...
///   }
/// } on UnauthorizedException {
///   // El interceptor ya manejó el logout y redirección
///   print('Sesión expirada');
/// } catch (e) {
///   print('Error: $e');
/// }
/// ```
