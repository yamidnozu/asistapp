import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String? _baseUrl;

  /// Inicializa la configuración de forma asíncrona
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      final envUrl = dotenv.env['API_BASE_URL'];
      
      if (envUrl != null && envUrl.isNotEmpty) {
        debugPrint('AppConfig.initialize - leyendo API_BASE_URL de .env: $envUrl');
        _baseUrl = envUrl;
      } else {
        // Detectar plataforma y usar configuración apropiada
        _baseUrl = _getDefaultUrl();
      }
    } catch (e) {
      // Si falla la carga de dotenv, usar valor por defecto según plataforma
      _baseUrl = _getDefaultUrl();
      debugPrint('Error cargando configuración: $e. Usando valor por defecto.');
    }
    debugPrint('AppConfig.initialize - URL base configurada: $_baseUrl');
  }

  /// Determina la URL por defecto según la plataforma
  static String _getDefaultUrl() {
    // Prefer localhost for local development. When running on Android emulators,
    // the special host 10.0.2.2 maps to the host machine. Use port 3002 which
    // is the default mapping for the backend container in docker-compose.
    // If running on a local Android emulator use the loopback alias
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3002';
      }
    } catch (_) {
      // Platform may not be available on some targets (web), ignore
    }

    // Default to local LAN IP so physical devices can reach the backend
    return 'http://192.168.20.22:3002';
    
  }

  /// Devuelve la URL base de la API (síncrona)
  static String get baseUrl {
    if (_baseUrl == null) {
      throw StateError('AppConfig no ha sido inicializado. Llama a AppConfig.initialize() antes de usar baseUrl.');
    }
    return _baseUrl!;
  }
}
