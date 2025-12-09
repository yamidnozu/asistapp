import 'package:flutter/foundation.dart';
import 'dart:io' show Platform, File, Directory;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de la aplicación con soporte para múltiples entornos
///
/// Uso con --dart-define:
/// ```bash
/// # Desarrollo local
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
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
    const dartDefineEnv =
        String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

    if (dartDefineUrl.isNotEmpty) {
      _baseUrl = dartDefineUrl;
      _environment = dartDefineEnv;
      debugPrint('AppConfig: Usando configuración de --dart-define');
      debugPrint('  - API_BASE_URL: $_baseUrl');
      debugPrint('  - ENVIRONMENT: $_environment');
      return;
    }

    // 2. Intentar cargar de archivo .env (buscar en directorio actual y padres)
    String? foundPath;
    final attemptedPaths = <String>[];
    try {
      // Buscar .env en varias ubicaciones probables (working dir, script y ejecutable),
      // subiendo hasta 6 niveles en cada ruta.

      bool _searchUpwards(Directory start) {
        try {
          var dir = start;
          for (var i = 0; i < 6; i++) {
            final candidatePath = '${dir.path}${Platform.pathSeparator}.env';
            attemptedPaths.add(candidatePath);
            final candidate = File(candidatePath);
            if (candidate.existsSync()) {
              foundPath = candidate.path;
              return true;
            }
            if (dir.parent.path == dir.path) break; // reached root
            dir = dir.parent;
          }
        } catch (_) {
          // ignore filesystem lookup errors for this start point
        }
        return false;
      }

      // 1) Directorio actual (frecuente en `flutter run` desde el proyecto)
      _searchUpwards(Directory.current);

      // 2) Intentar con la ubicación del script (cuando Platform.script es file://)
      try {
        final script = Platform.script;
        if (script.scheme == 'file') {
          final scriptFile = File(script.toFilePath());
          _searchUpwards(scriptFile.parent);
        }
      } catch (_) {
        // ignore
      }

      // 3) Intentar con la ubicación del ejecutable (útil en builds y en Windows runner)
      try {
        final exec = Platform.resolvedExecutable;
        if (exec.isNotEmpty) {
          final execDir = File(exec).parent;
          _searchUpwards(execDir);
          // también buscar un nivel extra por si el ejecutable está en /bin o /runner/Debug
          _searchUpwards(execDir.parent);
        }
      } catch (_) {
        // ignore
      }

      // 4) Si no encontramos nada, intentar cargar el nombre por defecto (puede lanzar FileNotFound)
      if (foundPath != null) {
        await dotenv.load(fileName: foundPath!);
        debugPrint('AppConfig: Cargado .env desde: $foundPath');
      } else {
        // Registrar los intentos para diagnóstico y luego intentar carga por nombre simple
        debugPrint('AppConfig: No se encontró .env en rutas probadas:');
        for (final p in attemptedPaths.take(30)) {
          debugPrint('  - $p');
        }
        // Intentar carga por fallback (puede lanzar si no existe)
        await dotenv.load(fileName: '.env');
      }

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
      if (attemptedPaths.isNotEmpty) {
        debugPrint('AppConfig: Rutas intentadas para .env (muestra hasta 30):');
        for (final p in attemptedPaths.take(30)) debugPrint('  - $p');
      }
    }

    // 3. Usar valores por defecto
    _baseUrl = _getDefaultUrl();
    // En release mode, el entorno por defecto es producción
    _environment = kDebugMode ? 'development' : 'production';
    debugPrint('AppConfig: Usando configuración por defecto');
    debugPrint('  - API_BASE_URL: $_baseUrl');
    debugPrint('  - ENVIRONMENT: $_environment');
    debugPrint('  - Plataforma: ${Platform.operatingSystem}');
    debugPrint('  - Modo: ${kDebugMode ? "DEBUG" : "RELEASE"}');
  }

  /// Determina la URL por defecto según la plataforma y el modo de compilación
  static String _getDefaultUrl() {
    // Android emulador usa 10.0.2.2 para conectar al localhost del host
    // iOS simulator usa localhost directamente
    // Dispositivos físicos necesitan la IP de la red local

    if (kDebugMode) {
      // En desarrollo, intentar detectar la mejor opción
      if (Platform.isAndroid) {
        // Para emulador de Android
        return 'http://10.0.2.2:3000';
      } else if (Platform.isIOS) {
        // Para simulador de iOS
        return 'http://localhost:3000';
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Para desarrollo en escritorio
        return 'http://localhost:3000';
      }
      // Fallback para debug en dispositivo físico: usar localhost
      // El desarrollador debe configurar .env con su IP local si es necesario
      return 'http://localhost:3000';
    }

    // En modo RELEASE (producción), NO hay valor por defecto
    // La URL DEBE ser configurada via --dart-define o .env
    throw StateError(
      'AppConfig: No se encontró API_BASE_URL para modo producción.\n'
      'Debes configurar la URL de la API mediante:\n'
      '  1. --dart-define=API_BASE_URL=https://tu-dominio.com (recomendado para builds)\n'
      '  2. Archivo .env con API_BASE_URL=https://tu-dominio.com\n'
      'Revisa la documentación en .env.example para más detalles.',
    );
  }

  /// Devuelve la URL base de la API
  static String get baseUrl {
    if (_baseUrl == null) {
      throw StateError('AppConfig no ha sido inicializado. '
          'Llama a AppConfig.initialize() antes de usar baseUrl.');
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
      return const Duration(
          seconds: 60); // Más tiempo en desarrollo para debugging
    }
  }

  /// Indica si se deben mostrar logs de red
  static bool get enableNetworkLogs => isDevelopment || isStaging;
}
