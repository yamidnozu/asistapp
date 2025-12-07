import 'package:flutter/foundation.dart';
import '../services/acudiente_service.dart';
import '../models/notificacion_in_app.dart';

/// Provider para el rol de Acudiente
/// Maneja el estado de hijos, asistencias, estadísticas y notificaciones
class AcudienteProvider extends ChangeNotifier {
  final AcudienteService _acudienteService = AcudienteService();

  // Estado
  bool _isLoading = false;
  String? _errorMessage;

  // Hijos
  List<HijoResponse> _hijos = [];
  HijoResponse? _hijoSeleccionado;

  // Historial de asistencias
  List<AsistenciaHistorialItem> _historialAsistencias = [];
  int _totalAsistencias = 0;

  // Estadísticas
  EstadisticasCompletas? _estadisticas;

  // Notificaciones
  List<NotificacionInApp> _notificaciones = [];
  int _notificacionesNoLeidas = 0;
  int _totalNotificaciones = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<HijoResponse> get hijos => _hijos;
  HijoResponse? get hijoSeleccionado => _hijoSeleccionado;
  List<AsistenciaHistorialItem> get historialAsistencias => _historialAsistencias;
  int get totalAsistencias => _totalAsistencias;
  EstadisticasCompletas? get estadisticas => _estadisticas;
  List<NotificacionInApp> get notificaciones => _notificaciones;
  int get notificacionesNoLeidas => _notificacionesNoLeidas;
  int get totalNotificaciones => _totalNotificaciones;

  bool get hasError => _errorMessage != null;
  bool get tieneHijos => _hijos.isNotEmpty;

  /// Carga la lista de hijos del acudiente
  Future<void> cargarHijos(String accessToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hijos = await _acudienteService.getHijos(accessToken);
      if (hijos != null) {
        _hijos = hijos;
        debugPrint('AcudienteProvider: ${hijos.length} hijos cargados');
      } else {
        _errorMessage = 'Error al cargar los hijos';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando hijos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selecciona un hijo para ver detalle
  Future<void> seleccionarHijo(String accessToken, String estudianteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hijo = await _acudienteService.getHijoDetalle(accessToken, estudianteId);
      if (hijo != null) {
        _hijoSeleccionado = hijo;
      } else {
        _errorMessage = 'Error al cargar detalle del hijo';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error seleccionando hijo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia la selección del hijo
  void limpiarHijoSeleccionado() {
    _hijoSeleccionado = null;
    _historialAsistencias = [];
    _estadisticas = null;
    notifyListeners();
  }

  /// Carga el historial de asistencias de un hijo
  Future<void> cargarHistorialAsistencias(
    String accessToken,
    String estudianteId, {
    int page = 1,
    int limit = 20,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
    bool append = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _acudienteService.getHistorialAsistencias(
        accessToken,
        estudianteId,
        page: page,
        limit: limit,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estado: estado,
      );

      if (result != null) {
        if (append) {
          _historialAsistencias.addAll(result.asistencias);
        } else {
          _historialAsistencias = result.asistencias;
        }
        _totalAsistencias = result.total;
      } else {
        _errorMessage = 'Error al cargar historial de asistencias';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando historial: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga las estadísticas de un hijo
  Future<void> cargarEstadisticas(String accessToken, String estudianteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final estadisticas = await _acudienteService.getEstadisticas(accessToken, estudianteId);
      if (estadisticas != null) {
        _estadisticas = estadisticas;
      } else {
        _errorMessage = 'Error al cargar estadísticas';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando estadísticas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga las notificaciones del acudiente
  Future<void> cargarNotificaciones(
    String accessToken, {
    int page = 1,
    int limit = 20,
    bool soloNoLeidas = false,
    bool append = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _acudienteService.getNotificaciones(
        accessToken,
        page: page,
        limit: limit,
        soloNoLeidas: soloNoLeidas,
      );

      if (result != null) {
        if (append) {
          _notificaciones.addAll(result.notificaciones);
        } else {
          _notificaciones = result.notificaciones;
        }
        _notificacionesNoLeidas = result.noLeidas;
        _totalNotificaciones = result.total;
      } else {
        _errorMessage = 'Error al cargar notificaciones';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando notificaciones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza el conteo de notificaciones no leídas
  Future<void> actualizarConteoNoLeidas(String accessToken) async {
    try {
      final count = await _acudienteService.contarNoLeidas(accessToken);
      _notificacionesNoLeidas = count;
      notifyListeners();
    } catch (e) {
      debugPrint('Error actualizando conteo: $e');
    }
  }

  /// Marca una notificación como leída
  Future<bool> marcarNotificacionComoLeida(String accessToken, String notificacionId) async {
    try {
      final success = await _acudienteService.marcarComoLeida(accessToken, notificacionId);
      if (success) {
        // Actualizar la notificación localmente
        final index = _notificaciones.indexWhere((n) => n.id == notificacionId);
        if (index != -1) {
          _notificaciones[index] = _notificaciones[index].copyWith(leida: true);
          if (_notificacionesNoLeidas > 0) {
            _notificacionesNoLeidas--;
          }
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      debugPrint('Error marcando notificación: $e');
      return false;
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<int> marcarTodasComoLeidas(String accessToken) async {
    try {
      final count = await _acudienteService.marcarTodasComoLeidas(accessToken);
      if (count > 0) {
        // Actualizar todas las notificaciones localmente
        _notificaciones = _notificaciones.map((n) => n.copyWith(leida: true)).toList();
        _notificacionesNoLeidas = 0;
        notifyListeners();
      }
      return count;
    } catch (e) {
      debugPrint('Error marcando todas: $e');
      return 0;
    }
  }

  /// Registra un dispositivo para notificaciones push
  Future<bool> registrarDispositivo(
    String accessToken,
    String token,
    String plataforma, {
    String? modelo,
  }) async {
    try {
      return await _acudienteService.registrarDispositivo(
        accessToken,
        token,
        plataforma,
        modelo: modelo,
      );
    } catch (e) {
      debugPrint('Error registrando dispositivo: $e');
      return false;
    }
  }

  /// Limpia el error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia todos los datos
  void clearData() {
    _hijos = [];
    _hijoSeleccionado = null;
    _historialAsistencias = [];
    _totalAsistencias = 0;
    _estadisticas = null;
    _notificaciones = [];
    _notificacionesNoLeidas = 0;
    _totalNotificaciones = 0;
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtiene resumen para el dashboard
  Map<String, dynamic> getResumenDashboard() {
    int totalFaltasHoy = 0;
    int totalFaltasSemana = 0;
    int totalFaltasMes = 0;

    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final inicioMes = DateTime(ahora.year, ahora.month, 1);

    for (final hijo in _hijos) {
      totalFaltasSemana += hijo.estadisticasResumen.ausentes;
      // Nota: Para datos precisos, necesitaríamos cargar las asistencias con filtros
    }

    return {
      'totalHijos': _hijos.length,
      'faltasHoy': totalFaltasHoy,
      'faltasSemana': totalFaltasSemana,
      'faltasMes': totalFaltasMes,
      'notificacionesNoLeidas': _notificacionesNoLeidas,
    };
  }
}
