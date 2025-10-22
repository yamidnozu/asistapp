import 'package:flutter/widgets.dart';

/// Estados del ciclo de vida de la aplicación
enum AppState {
  /// Aplicación está en primer plano y activa
  resumed,

  /// Aplicación está en segundo plano pero aún ejecutándose
  paused,

  /// Aplicación está completamente oculta
  hidden,

  /// Aplicación está siendo destruida
  detached,
}

/// Manager para manejar el ciclo de vida de la aplicación
/// Optimiza la recuperación de estado cuando la app vuelve a primer plano
class AppLifecycleManager extends ChangeNotifier {
  AppState _currentState = AppState.resumed;
  DateTime? _lastPausedTime;
  bool _isFirstResume = true;

  AppState get currentState => _currentState;
  bool get isInForeground => _currentState == AppState.resumed;
  bool get isInBackground => _currentState == AppState.paused || _currentState == AppState.hidden;

  AppLifecycleManager() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  void _onLifecycleChanged(AppState state) {
    final previousState = _currentState;
    _currentState = state;

    switch (state) {
      case AppState.paused:
        _handleAppPaused();
        break;
      case AppState.resumed:
        _handleAppResumed(previousState);
        break;
      case AppState.hidden:
        _handleAppHidden();
        break;
      case AppState.detached:
        _handleAppDetached();
        break;
    }

    notifyListeners();
  }

  void _handleAppPaused() {
    _lastPausedTime = DateTime.now();
    debugPrint('AppLifecycleManager: App paused at $_lastPausedTime');
  }

  void _handleAppResumed(AppState previousState) {
    final now = DateTime.now();
    final timeInBackground = _lastPausedTime != null ? now.difference(_lastPausedTime!) : Duration.zero;

    debugPrint('AppLifecycleManager: App resumed after ${timeInBackground.inSeconds}s in background');

    // Si es la primera vez que se reanuda, no hacer nada especial
    if (_isFirstResume) {
      _isFirstResume = false;
      return;
    }

    // Si estuvo en background por más de 30 segundos, forzar refresh de datos
    if (timeInBackground.inSeconds > 30) {
      debugPrint('AppLifecycleManager: Long background time, triggering data refresh');
      _triggerDataRefresh();
    } else {
      debugPrint('AppLifecycleManager: Quick resume, using cached data');
    }
  }

  void _handleAppHidden() {
    debugPrint('AppLifecycleManager: App hidden');
  }

  void _handleAppDetached() {
    debugPrint('AppLifecycleManager: App detached');
  }

  /// Fuerza la actualización de datos críticos
  void _triggerDataRefresh() {
    // Aquí se pueden agregar llamadas para refrescar datos importantes
    // Por ejemplo: verificar estado de autenticación, actualizar cache, etc.
    debugPrint('AppLifecycleManager: Triggering data refresh...');
  }

  /// Método para que otros componentes se registren para eventos de lifecycle
  void addLifecycleCallback(String key, VoidCallback callback) {
    // Implementación futura si es necesaria
  }

  void removeLifecycleCallback(String key) {
    // Implementación futura si es necesaria
  }
}

/// Observer privado para manejar los eventos del sistema
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final AppLifecycleManager _manager;

  _AppLifecycleObserver(this._manager);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppState mappedState;

    switch (state) {
      case AppLifecycleState.resumed:
        mappedState = AppState.resumed;
        break;
      case AppLifecycleState.paused:
        mappedState = AppState.paused;
        break;
      case AppLifecycleState.hidden:
        mappedState = AppState.hidden;
        break;
      case AppLifecycleState.detached:
        mappedState = AppState.detached;
        break;
      case AppLifecycleState.inactive:
        // Tratamos inactive como paused para simplificar
        mappedState = AppState.paused;
        break;
    }

    _manager._onLifecycleChanged(mappedState);
  }
}