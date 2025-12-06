import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/asistencia_service.dart';
import '../models/asistencia_estudiante.dart';

enum AsistenciaState {
  initial,
  loading,
  loaded,
  error,
}

class AsistenciaProvider with ChangeNotifier {
  final AsistenciaService _asistenciaService;

  AsistenciaProvider({AsistenciaService? asistenciaService})
      : _asistenciaService = asistenciaService ?? AsistenciaService();

  AsistenciaState _state = AsistenciaState.initial;
  String? _errorMessage;
  List<AsistenciaEstudiante> _asistencias = [];
  String? _selectedHorarioId;

  // Getters
  AsistenciaState get state => _state;
  String? get errorMessage => _errorMessage;
  List<AsistenciaEstudiante> get asistencias => _asistencias;
  String? get selectedHorarioId => _selectedHorarioId;

  bool get isLoading => _state == AsistenciaState.loading;
  bool get hasError => _state == AsistenciaState.error;
  bool get isLoaded => _state == AsistenciaState.loaded;

  // Estadísticas computadas
  int get totalEstudiantes => _asistencias.length;
  int get presentes => _asistencias.where((a) => a.estaPresente).length;
  int get ausentes => _asistencias.where((a) => a.estaAusente).length;
  int get tardanzas => _asistencias.where((a) => a.tieneTardanza).length;
  int get justificados => _asistencias.where((a) => a.estaJustificado).length;
  int get sinRegistrar => _asistencias.where((a) => a.sinRegistrar).length;

  /// Carga las asistencias para un horario específico
  Future<void> fetchAsistencias(String accessToken, String horarioId, {DateTime? date}) async {
    try {
      debugPrint('AsistenciaProvider: Loading asistencias for horario: $horarioId');
      _setState(AsistenciaState.loading);

      final asistencias = await _asistenciaService.getAsistencias(
        accessToken: accessToken,
        horarioId: horarioId,
        date: date,
      );

      _asistencias = asistencias;
      _selectedHorarioId = horarioId;
      _setState(AsistenciaState.loaded);
      debugPrint('AsistenciaProvider: Loaded ${asistencias.length} asistencias');
    } catch (e) {
      debugPrint('AsistenciaProvider: Error loading asistencias: $e');
      _setState(AsistenciaState.error, e.toString());
    }
  }

  /// Registra la asistencia mediante código QR y refresca la lista
  Future<bool> registrarAsistencia(String accessToken, String horarioId, String qrCode) async {
    try {
      debugPrint('AsistenciaProvider: Registrando asistencia con QR: $qrCode');
      _setState(AsistenciaState.loading);

      final success = await _asistenciaService.registrarAsistencia(
        accessToken: accessToken,
        horarioId: horarioId,
        codigoQr: qrCode,
      );

      if (success) {
        // Recargar la lista de asistencias
        await fetchAsistencias(accessToken, horarioId);
      }

      _setState(AsistenciaState.loaded);
      return success;
    } catch (e) {
      debugPrint('AsistenciaProvider: Error registrando asistencia: $e');
      _setState(AsistenciaState.error, e.toString());
      rethrow;
    }
  }

  /// Registra asistencia manual para un estudiante específico
  /// Ahora acepta estado personalizado para registro inteligente
  Future<bool> registrarAsistenciaManual(
    String accessToken, 
    String horarioId, 
    String estudianteId, {
    String? estado,
    String? observacion,
    bool? justificada,
  }) async {
    try {
      debugPrint('AsistenciaProvider: Registrando asistencia manual ($estado) para estudiante: $estudianteId');
      _setState(AsistenciaState.loading);

      final success = await _asistenciaService.registrarAsistenciaManual(
        accessToken: accessToken,
        horarioId: horarioId,
        estudianteId: estudianteId,
        estado: estado,
        observacion: observacion,
        justificada: justificada,
      );

      if (success) {
        // Recargar la lista de asistencias
        await fetchAsistencias(accessToken, horarioId);
      }

      _setState(AsistenciaState.loaded);
      return success;
    } catch (e) {
      debugPrint('AsistenciaProvider: Error registrando asistencia manual: $e');
      _setState(AsistenciaState.error, e.toString());
      rethrow;
    }
  }

  /// Actualiza el estado de una asistencia
  Future<bool> updateAsistencia(String accessToken, String asistenciaId, String estado, {String? observacion, bool? justificada}) async {
    try {
      debugPrint('AsistenciaProvider: Actualizando asistencia $asistenciaId a estado: $estado');
      _setState(AsistenciaState.loading);

      final success = await _asistenciaService.updateAsistencia(
        accessToken: accessToken,
        asistenciaId: asistenciaId,
        estado: estado,
        observacion: observacion,
        justificada: justificada,
      );

      if (success) {
        // Recargar la lista de asistencias
        if (_selectedHorarioId != null) {
          await fetchAsistencias(accessToken, _selectedHorarioId!);
        }
      }

      _setState(AsistenciaState.loaded);
      return success;
    } catch (e) {
      debugPrint('AsistenciaProvider: Error actualizando asistencia: $e');
      _setState(AsistenciaState.error, e.toString());
      rethrow;
    }
  }

  /// Busca estudiantes por nombre o identificación
  List<AsistenciaEstudiante> searchEstudiantes(String query) {
    if (query.isEmpty) return _asistencias;
    final lowercaseQuery = query.toLowerCase();
    return _asistencias.where((asistencia) {
      return asistencia.nombreCompleto.toLowerCase().contains(lowercaseQuery) ||
             asistencia.identificacion.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Obtiene estadísticas de asistencia como mapa
  Map<String, int> getEstadisticas() {
    return {
      'total': totalEstudiantes,
      'presentes': presentes,
      'ausentes': ausentes,
      'tardanzas': tardanzas,
      'justificados': justificados,
      'sinRegistrar': sinRegistrar,
    };
  }

  /// Obtiene el porcentaje de asistencia
  double getPorcentajeAsistencia() {
    if (totalEstudiantes == 0) return 0.0;
    return (presentes + justificados) / totalEstudiantes;
  }

  /// Limpia todos los datos
  void clearData() {
    _asistencias = [];
    _selectedHorarioId = null;
    _setState(AsistenciaState.initial);
  }

  /// Selecciona un horario para trabajar con él
  void selectHorario(String horarioId) {
    _selectedHorarioId = horarioId;
    notifyListeners();
  }

  /// Dispara notificaciones manuales
  Future<Map<String, dynamic>> triggerManualNotifications({
    required String accessToken,
    required String institutionId,
    String? classId,
    String scope = 'LAST_DAY',
  }) async {
    try {
      debugPrint('AsistenciaProvider: Disparando notificaciones manuales...');
      return await _asistenciaService.triggerManualNotifications(
        accessToken: accessToken,
        institutionId: institutionId,
        classId: classId,
        scope: scope,
      );
    } catch (e) {
      debugPrint('AsistenciaProvider: Error disparando notificaciones: $e');
      rethrow;
    }
  }

  /// Método helper para cambiar el estado
  void _setState(AsistenciaState newState, [String? errorMessage]) {
    _state = newState;
    _errorMessage = errorMessage;
    notifyListeners();
  }
}
