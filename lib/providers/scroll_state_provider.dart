import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gestionar posiciones de scroll en la aplicación
class ScrollStateProvider with ChangeNotifier {
  final Map<String, double> _scrollPositions = {};
  static const String _storageKey = 'scrollPositions';

  ScrollStateProvider() {
    _loadScrollPositions();
  }

  /// Obtiene la posición de scroll guardada para una ruta
  double getScrollPosition(String route) {
    return _scrollPositions[route] ?? 0.0;
  }

  /// Guarda la posición de scroll para una ruta
  Future<void> saveScrollPosition(String route, double position) async {
    _scrollPositions[route] = position;
    await _persistScrollPositions();
    notifyListeners();
  }

  /// Limpia la posición de scroll de una ruta específica
  Future<void> clearScrollPosition(String route) async {
    _scrollPositions.remove(route);
    await _persistScrollPositions();
    notifyListeners();
  }

  /// Limpia todas las posiciones de scroll
  Future<void> clearAllScrollPositions() async {
    _scrollPositions.clear();
    await _persistScrollPositions();
    notifyListeners();
  }

  /// Carga las posiciones de scroll desde almacenamiento
  Future<void> _loadScrollPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionsJson = prefs.getString(_storageKey);
      
      if (positionsJson != null) {
        final positions = jsonDecode(positionsJson) as Map<String, dynamic>;
        _scrollPositions.clear();
        positions.forEach((key, value) {
          _scrollPositions[key] = (value as num).toDouble();
        });
        debugPrint('Posiciones de scroll cargadas: ${_scrollPositions.length} rutas');
      }
    } catch (e) {
      debugPrint('Error loading scroll positions: $e');
    }
  }

  /// Persiste las posiciones de scroll en almacenamiento
  Future<void> _persistScrollPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_scrollPositions));
    } catch (e) {
      debugPrint('Error persisting scroll positions: $e');
    }
  }
}
