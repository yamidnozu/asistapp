import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String? _baseUrl;

  /// Inicializa la configuración de forma asíncrona
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      final envUrl = dotenv.env['API_BASE_URL'];
      
      if (envUrl != null && envUrl.isNotEmpty) {
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
  }

  /// Determina la URL por defecto según la plataforma
  static String _getDefaultUrl() {
      return 'http://192.168.20.22:3001';
    
  }

  /// Devuelve la URL base de la API (síncrona)
  static String get baseUrl {
    if (_baseUrl == null) {
      throw StateError('AppConfig no ha sido inicializado. Llama a AppConfig.initialize() antes de usar baseUrl.');
    }
    return _baseUrl!;
  }
}
