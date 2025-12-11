import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gestionar las configuraciones/preferencias de la aplicación
/// Persiste las preferencias usando SharedPreferences
class SettingsProvider with ChangeNotifier {
  // Keys para SharedPreferences
  static const String _keyThemeMode = 'settings_theme_mode';
  static const String _keyItemsPerPage = 'settings_items_per_page';
  static const String _keyAutoRefresh = 'settings_auto_refresh';
  static const String _keyRefreshInterval = 'settings_refresh_interval';

  static const String _keyShowTestUsers = 'settings_show_test_users';

  // Valores por defecto
  ThemeMode _themeMode = ThemeMode.dark;
  int _itemsPerPage = 10;
  bool _autoRefresh = false;
  int _refreshIntervalMinutes = 5;

  bool _showTestUsers = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  int get itemsPerPage => _itemsPerPage;
  bool get autoRefresh => _autoRefresh;
  int get refreshIntervalMinutes => _refreshIntervalMinutes;

  bool get showTestUsers => _showTestUsers;

  /// Indica si el tema es oscuro
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  SettingsProvider() {
    _loadSettings();
  }

  /// Carga las configuraciones desde SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeModeIndex = prefs.getInt(_keyThemeMode);
      if (themeModeIndex != null && themeModeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeModeIndex];
      }

      _itemsPerPage = prefs.getInt(_keyItemsPerPage) ?? 10;
      _autoRefresh = prefs.getBool(_keyAutoRefresh) ?? false;
      _refreshIntervalMinutes = prefs.getInt(_keyRefreshInterval) ?? 5;

      _showTestUsers = prefs.getBool(_keyShowTestUsers) ?? false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  /// Guarda una configuración en SharedPreferences
  Future<void> _savePreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (e) {
      debugPrint('Error saving preference $key: $e');
    }
  }

  // ============================================================================
  // SETTERS CON PERSISTENCIA
  // ============================================================================

  /// Cambia el modo del tema (claro/oscuro/sistema)
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _savePreference(_keyThemeMode, mode.index);
  }

  /// Alterna entre tema oscuro y claro
  Future<void> toggleDarkMode() async {
    await setThemeMode(
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Cambia el número de elementos por página en las listas
  Future<void> setItemsPerPage(int value) async {
    if (value >= 5 && value <= 50) {
      _itemsPerPage = value;
      notifyListeners();
      await _savePreference(_keyItemsPerPage, value);
    }
  }

  /// Activa/desactiva la actualización automática de datos
  Future<void> setAutoRefresh(bool value) async {
    _autoRefresh = value;
    notifyListeners();
    await _savePreference(_keyAutoRefresh, value);
  }

  /// Cambia el intervalo de actualización automática
  Future<void> setRefreshInterval(int minutes) async {
    if (minutes >= 1 && minutes <= 60) {
      _refreshIntervalMinutes = minutes;
      notifyListeners();
      await _savePreference(_keyRefreshInterval, minutes);
    }
  }

  /// Activa/desactiva la visualización de usuarios de prueba
  Future<void> setShowTestUsers(bool value) async {
    _showTestUsers = value;
    notifyListeners();
    await _savePreference(_keyShowTestUsers, value);
  }

  /// Restaura todas las configuraciones a sus valores por defecto
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.dark;
    _itemsPerPage = 10;
    _autoRefresh = false;
    _refreshIntervalMinutes = 5;

    _showTestUsers = false;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyThemeMode);
    await prefs.remove(_keyItemsPerPage);
    await prefs.remove(_keyAutoRefresh);
    await prefs.remove(_keyRefreshInterval);

    await prefs.remove(_keyShowTestUsers);
  }
}
