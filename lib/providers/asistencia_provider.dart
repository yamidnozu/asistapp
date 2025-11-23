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
      final success = await _asistenciaService.registrarAsistencia(
        accessToken: accessToken,
        horarioId: horarioId,
        codigoQr: qrCode,
      );

      if (success && _selectedHorarioId == horarioId) {
        // Refrescar la lista de asistencias
        debugPrint('AsistenciaProvider: Refrescando lista de asistencias...');
        await fetchAsistencias(accessToken, horarioId);
      }

      return success;
    } catch (e) {
      debugPrint('AsistenciaProvider: Error registrando asistencia con QR: $e');
      return false;
    }
  }

  /// Registra asistencia manual para un estudiante
  Future<bool> registrarAsistenciaManual(String accessToken, String horarioId, String estudianteId) async {
    try {
      debugPrint('AsistenciaProvider: Registrando asistencia manual para estudiante: $estudianteId');
      final success = await _asistenciaService.registrarAsistenciaManual(
        accessToken: accessToken,
        horarioId: horarioId,
        estudianteId: estudianteId,
      );

      if (success && _selectedHorarioId == horarioId) {
        // Refrescar la lista de asistencias
        debugPrint('AsistenciaProvider: Refrescando lista de asistencias...');
        await fetchAsistencias(accessToken, horarioId);
      }

      return success;
    } catch (e) {
      debugPrint('AsistenciaProvider: Error registrando asistencia manual: $e');
      return false;
    }
  }

  /// Actualiza una asistencia existente
  Future<bool> updateAsistencia({
    required String accessToken,
    required String asistenciaId,
    required String estado,
    String? observacion,
    bool? justificada,
  }) async {
    try {
      debugPrint('AsistenciaProvider: Actualizando asistencia: $asistenciaId');
      final success = await _asistenciaService.updateAsistencia(
        accessToken: accessToken,
        asistenciaId: asistenciaId,
        estado: estado,
        observacion: observacion,
        justificada: justificada,
      );

      if (success && _selectedHorarioId != null) {
        // Refrescar la lista de asistencias
        debugPrint('AsistenciaProvider: Refrescando lista de asistencias...');
        await fetchAsistencias(accessToken, _selectedHorarioId!);
      }

      return success;
    } catch (e) {
      debugPrint('AsistenciaProvider: Error actualizando asistencia: $e');
      return false;
    }
  }

  /// Refresca los datos del horario actualmente seleccionado
  Future<void> refreshAsistencias(String accessToken) async {
    if (_selectedHorarioId != null) {
      await fetchAsistencias(accessToken, _selectedHorarioId!);
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

  /// Método helper para cambiar el estado
  void _setState(AsistenciaState newState, [String? errorMessage]) {
    _state = newState;
    _errorMessage = errorMessage;
    notifyListeners();
  }
}