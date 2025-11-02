import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String? _baseUrl;

  /// Inicializa la configuración de forma asíncrona
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      final envUrl = dotenv.env['API_BASE_URL'];
      _baseUrl = envUrl != null && envUrl.isNotEmpty ? envUrl : 'http://localhost:3000';
    } catch (e) {
      // Si falla la carga de dotenv, usar valor por defecto
      _baseUrl = 'http://localhost:3000';
      print('Error cargando configuración: $e. Usando valor por defecto.');
    }
  }

  /// Devuelve la URL base de la API (síncrona)
  static String get baseUrl {
    if (_baseUrl == null) {
      throw StateError('AppConfig no ha sido inicializado. Llama a AppConfig.initialize() antes de usar baseUrl.');
    }
    return _baseUrl!;
  }
}
