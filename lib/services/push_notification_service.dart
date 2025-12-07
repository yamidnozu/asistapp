import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'acudiente_service.dart';

/// Helper para verificar si estamos en plataforma móvil
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (e) {
    return false;
  }
}

/// Handler para mensajes en background (debe ser función top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(
      '📩 Mensaje recibido en background: ${message.notification?.title}');
}

/// Servicio para manejar Firebase Cloud Messaging
/// Gestiona notificaciones push para el rol Acudiente
/// NOTA: Solo funciona en Android e iOS
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // Solo crear instancia de FirebaseMessaging si estamos en móvil
  FirebaseMessaging? _messaging;
  FirebaseMessaging? get messaging {
    if (!_isMobilePlatform) return null;
    _messaging ??= FirebaseMessaging.instance;
    return _messaging;
  }

  final AcudienteService _acudienteService = AcudienteService();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  String? _fcmToken;
  String? _accessToken;

  // Callback para cuando llega una notificación en foreground
  Function(RemoteMessage)? onForegroundMessage;

  // Callback para cuando el usuario toca una notificación
  Function(RemoteMessage)? onNotificationTapped;

  /// Inicializa Firebase (debe llamarse en main.dart antes de runApp)
  static Future<void> initializeFirebase() async {
    if (!_isMobilePlatform) {
      debugPrint('ℹ️ Firebase Messaging no disponible en esta plataforma');
      return;
    }
    try {
      await Firebase.initializeApp();
      // Configurar handler de mensajes en background
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('✅ Firebase inicializado para push notifications');
    } catch (e) {
      debugPrint('⚠️ Error inicializando Firebase: $e');
    }
  }

  /// Configura el servicio de notificaciones push
  /// Debe llamarse después del login exitoso
  Future<void> configure(String accessToken) async {
    if (!_isMobilePlatform) {
      debugPrint('ℹ️ Push notifications no disponibles en esta plataforma');
      return;
    }

    _accessToken = accessToken;

    // Solicitar permisos
    await _requestPermission();

    // Obtener y registrar token FCM
    await _registerToken();

    // Configurar listeners para mensajes
    _setupMessageListeners();

    debugPrint('✅ PushNotificationService configurado correctamente');
  }

  /// Solicita permisos de notificación al usuario
  Future<void> _requestPermission() async {
    final msg = messaging;
    if (msg == null) return;

    try {
      final settings = await msg.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
          '📱 Permisos de notificación: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('⚠️ Error solicitando permisos: $e');
    }
  }

  /// Obtiene el token FCM y lo registra en el backend
  Future<void> _registerToken() async {
    final msg = messaging;
    if (msg == null) return;

    try {
      _fcmToken = await msg.getToken();
      if (_fcmToken != null && _accessToken != null) {
        debugPrint('📲 Token FCM obtenido: ${_fcmToken!.substring(0, 20)}...');

        // Determinar plataforma
        String plataforma = 'android';
        try {
          if (Platform.isIOS) plataforma = 'ios';
        } catch (_) {}

        // Registrar token en el backend
        await _acudienteService.registrarDispositivo(
          _accessToken!,
          _fcmToken!,
          plataforma,
        );
        debugPrint('✅ Token FCM registrado en el backend');
      }
    } catch (e) {
      debugPrint('⚠️ Error obteniendo/registrando token FCM: $e');
    }

    // Escuchar cambios en el token
    msg.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      if (_accessToken != null) {
        try {
          String plataforma = 'android';
          try {
            if (Platform.isIOS) plataforma = 'ios';
          } catch (_) {}

          await _acudienteService.registrarDispositivo(
            _accessToken!,
            newToken,
            plataforma,
          );
          debugPrint('🔄 Token FCM actualizado en el backend');
        } catch (e) {
          debugPrint('⚠️ Error actualizando token FCM: $e');
        }
      }
    });
  }

  /// Configura los listeners para mensajes entrantes
  void _setupMessageListeners() {
    if (!_isMobilePlatform) return;

    // Mensaje recibido mientras la app está en foreground
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📩 Mensaje en foreground: ${message.notification?.title}');
      onForegroundMessage?.call(message);
    });

    // Mensaje que abrió la app desde background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
          '📩 App abierta desde notificación: ${message.notification?.title}');
      onNotificationTapped?.call(message);
    });

    // Verificar si hay un mensaje inicial (app abierta desde terminated)
    _checkInitialMessage();
  }

  /// Verifica si la app fue abierta desde una notificación (estado terminated)
  Future<void> _checkInitialMessage() async {
    final msg = messaging;
    if (msg == null) return;

    try {
      final initialMessage = await msg.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            '📩 App iniciada desde notificación: ${initialMessage.notification?.title}');
        // Dar tiempo para que los listeners se configuren
        await Future.delayed(const Duration(milliseconds: 500));
        onNotificationTapped?.call(initialMessage);
      }
    } catch (e) {
      debugPrint('⚠️ Error verificando mensaje inicial: $e');
    }
  }

  /// Suscribe al usuario a un topic (ej: su institución)
  Future<void> subscribeToTopic(String topic) async {
    final msg = messaging;
    if (msg == null) return;

    try {
      await msg.subscribeToTopic(topic);
      debugPrint('📌 Suscrito a topic: $topic');
    } catch (e) {
      debugPrint('⚠️ Error suscribiéndose a topic: $e');
    }
  }

  /// Desuscribe al usuario de un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    final msg = messaging;
    if (msg == null) return;

    try {
      await msg.unsubscribeFromTopic(topic);
      debugPrint('📌 Desuscrito de topic: $topic');
    } catch (e) {
      debugPrint('⚠️ Error desuscribiéndose de topic: $e');
    }
  }

  /// Obtiene el token FCM actual
  String? get currentToken => _fcmToken;

  /// Limpia los recursos al cerrar sesión
  Future<void> dispose() async {
    if (!_isMobilePlatform) return;

    await _foregroundSubscription?.cancel();
    _fcmToken = null;
    _accessToken = null;
    debugPrint('🧹 PushNotificationService limpiado');
  }
}
