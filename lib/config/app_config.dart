import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de la aplicación con soporte para múltiples entornos
/// 
/// Uso con --dart-define:
/// ```bash
/// # Desarrollo local
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3002
/// 
/// # Producción
/// flutter build apk --dart-define=API_BASE_URL=https://api.asistapp.com
/// 
/// # Staging
/// flutter build apk --dart-define=API_BASE_URL=https://staging.asistapp.com --dart-define=ENVIRONMENT=staging
/// ```
class AppConfig {
  static String? _baseUrl;
  static String? _environment;

  /// Inicializa la configuración de forma asíncrona
  /// Prioridad de configuración:
  /// 1. --dart-define en tiempo de compilación
  /// 2. Variables de entorno en archivo .env
  /// 3. Valores por defecto según plataforma
  static Future<void> initialize() async {
    // 1. Intentar obtener de --dart-define (tiempo de compilación)
    const dartDefineUrl = String.fromEnvironment('API_BASE_URL');
    const dartDefineEnv = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    if (dartDefineUrl.isNotEmpty) {
      _baseUrl = dartDefineUrl;
      _environment = dartDefineEnv;
      debugPrint('AppConfig: Usando configuración de --dart-define');
      debugPrint('  - API_BASE_URL: $_baseUrl');
      debugPrint('  - ENVIRONMENT: $_environment');
      return;
    }

    // 2. Intentar cargar de archivo .env
    try {
      await dotenv.load(fileName: '.env');
      final envUrl = dotenv.env['API_BASE_URL'];
      final envEnvironment = dotenv.env['ENVIRONMENT'] ?? 'development';
      
      if (envUrl != null && envUrl.isNotEmpty) {
        _baseUrl = envUrl;
        _environment = envEnvironment;
        debugPrint('AppConfig: Usando configuración de .env');
        debugPrint('  - API_BASE_URL: $_baseUrl');
        debugPrint('  - ENVIRONMENT: $_environment');
        return;
      }
    } catch (e) {
      debugPrint('AppConfig: No se pudo cargar .env: $e');
    }

    // 3. Usar valores por defecto
    _baseUrl = _getDefaultUrl();
    _environment = 'development';
    debugPrint('AppConfig: Usando configuración por defecto');
    debugPrint('  - API_BASE_URL: $_baseUrl');
    debugPrint('  - ENVIRONMENT: $_environment');
    debugPrint('  - Plataforma: ${Platform.operatingSystem}');
  }

  /// Determina la URL por defecto según la plataforma
  static String _getDefaultUrl() {
    // Android emulador usa 10.0.2.2 para conectar al localhost del host
    // iOS simulator usa localhost directamente
    // Dispositivos físicos necesitan la IP de la red local
    
    if (kDebugMode) {
      // En desarrollo, intentar detectar la mejor opción
      if (Platform.isAndroid) {
        // Para emulador de Android
        return 'http://10.0.2.2:3002';
      } else if (Platform.isIOS) {
        // Para simulador de iOS
        return 'http://localhost:3002';
      }
    }
    
    // Fallback: red local (ajustar según tu configuración)
    return 'http://192.168.20.22:3002';
  }

  /// Devuelve la URL base de la API
  static String get baseUrl {
    if (_baseUrl == null) {
      throw StateError(
        'AppConfig no ha sido inicializado. '
        'Llama a AppConfig.initialize() antes de usar baseUrl.'
      );
    }
    return _baseUrl!;
  }

  /// Devuelve el entorno actual (development, staging, production)
  static String get environment {
    return _environment ?? 'development';
  }

  /// Indica si está en modo de desarrollo
  static bool get isDevelopment => environment == 'development';

  /// Indica si está en modo de staging
  static bool get isStaging => environment == 'staging';

  /// Indica si está en modo de producción
  static bool get isProduction => environment == 'production';

  /// Configuración para timeouts de red según el entorno
  static Duration get networkTimeout {
    if (isProduction) {
      return const Duration(seconds: 30);
    } else {
      return const Duration(seconds: 60); // Más tiempo en desarrollo para debugging
    }
  }

  /// Indica si se deben mostrar logs de red
  static bool get enableNetworkLogs => isDevelopment || isStaging;
}
