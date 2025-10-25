import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gestionar el estado de navegación de la aplicación
/// Permite guardar y recuperar el estado completo de navegación
class NavigationStateProvider with ChangeNotifier {
  String? _currentRoute;
  Map<String, dynamic>? _routeArguments;
  DateTime? _lastStateUpdate;
  
  // Configuración: tiempo máximo para considerar un estado válido (30 minutos)
  static const int maxStateAgeMinutes = 30;

  String? get currentRoute => _currentRoute;
  Map<String, dynamic>? get routeArguments => _routeArguments;
  DateTime? get lastStateUpdate => _lastStateUpdate;

  NavigationStateProvider() {
    _loadNavigationState();
  }

  /// Carga el estado de navegación desde almacenamiento
  Future<void> _loadNavigationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString('navigationState');
      
      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;
        final lastUpdate = DateTime.parse(state['lastStateUpdate'] as String);
        final now = DateTime.now();
        
        // Verificar si el estado es reciente (no más de 30 minutos)
        final difference = now.difference(lastUpdate).inMinutes;
        
        if (difference <= maxStateAgeMinutes) {
          _currentRoute = state['currentRoute'] as String?;
          _routeArguments = state['routeArguments'] as Map<String, dynamic>?;
          _lastStateUpdate = lastUpdate;
          debugPrint('Estado de navegación recuperado: $_currentRoute (hace $difference minutos)');
        } else {
          // Estado muy antiguo, limpiarlo
          debugPrint('Estado de navegación obsoleto (hace $difference minutos), descartando');
          await clearNavigationState();
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading navigation state: $e');
    }
  }

  /// Guarda el estado actual de navegación
  Future<void> saveNavigationState(String route, {Map<String, dynamic>? arguments}) async {
    try {
      _currentRoute = route;
      _routeArguments = arguments;
      _lastStateUpdate = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      final state = {
        'currentRoute': _currentRoute,
        'routeArguments': _routeArguments,
        'lastStateUpdate': _lastStateUpdate!.toIso8601String(),
      };

      await prefs.setString('navigationState', jsonEncode(state));
      debugPrint('Estado de navegación guardado: $_currentRoute');
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving navigation state: $e');
    }
  }

  /// Limpia completamente el estado de navegación
  Future<void> clearNavigationState() async {
    try {
      _currentRoute = null;
      _routeArguments = null;
      _lastStateUpdate = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('navigationState');
      
      debugPrint('Estado de navegación limpiado');
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing navigation state: $e');
    }
  }

  /// Verifica si hay un estado válido para recuperar
  bool hasValidState() {
    if (_lastStateUpdate == null || _currentRoute == null) return false;
    
    final difference = DateTime.now().difference(_lastStateUpdate!).inMinutes;
    return difference <= maxStateAgeMinutes;
  }

  /// Actualiza solo la marca de tiempo (útil para mantener el estado activo)
  Future<void> refreshStateTimestamp() async {
    if (_currentRoute != null) {
      await saveNavigationState(_currentRoute!, arguments: _routeArguments);
    }
  }
}
