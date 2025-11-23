import 'package:json_annotation/json_annotation.dart';
import '../constants/attendance.dart';

part 'asistencia_estudiante.g.dart';

/// Modelo que representa la información de asistencia de un estudiante
/// Corresponde a la respuesta del endpoint GET /horarios/:horarioId/asistencias
@JsonSerializable()
class AsistenciaEstudiante {
  final String? id; // ID de la asistencia específica (puede ser null si no registrada)
  final String estudianteId;
  final String nombres;
  final String apellidos;
  final String identificacion;
  final String? estado; // null si no ha registrado asistencia
  final String? observacion; // Comentarios adicionales sobre la asistencia
  final DateTime? fechaRegistro;

  AsistenciaEstudiante({
    this.id,
    required this.estudianteId,
    required this.nombres,
    required this.apellidos,
    required this.identificacion,
    this.estado,
    this.observacion,
    this.fechaRegistro,
  });

  /// Crea una instancia desde un JSON del backend
  factory AsistenciaEstudiante.fromJson(Map<String, dynamic> json) => _$AsistenciaEstudianteFromJson(json);

  /// Convierte la instancia a JSON
  Map<String, dynamic> toJson() => _$AsistenciaEstudianteToJson(this);

  /// Obtiene el nombre completo del estudiante
  String get nombreCompleto => '$nombres $apellidos';

  /// Obtiene la inicial del estudiante para mostrar en avatares
  String get inicial {
    // Primero intentar usar la primera letra de nombres
    if (nombres.isNotEmpty) {
      return nombres[0].toUpperCase();
    }
    
    // Si nombres está vacío, usar la primera letra del nombre completo
    if (nombreCompleto.isNotEmpty && nombreCompleto != ' ') {
      return nombreCompleto[0].toUpperCase();
    }
    
    // Último recurso
    return '?';
  }

  /// Verifica si el estudiante está presente
  bool get estaPresente => estado == AttendanceStatus.presente;

  /// Verifica si el estudiante está ausente
  bool get estaAusente => estado == AttendanceStatus.ausente;

  /// Verifica si el estudiante tiene tardanza
  bool get tieneTardanza => estado == AttendanceStatus.tardanza;

  /// Verifica si el estudiante está justificado
  bool get estaJustificado => estado == AttendanceStatus.justificado;

  /// Verifica si el estudiante no ha registrado asistencia
  bool get sinRegistrar => estado == null;

  /// Obtiene el color correspondiente al estado de asistencia
  String getEstadoColor() {
    if (estado == null) return '#9E9E9E'; // Gris para sin registrar
    return AttendanceStatus.getColor(estado!);
  }

  /// Obtiene el texto descriptivo del estado
  String getEstadoTexto() {
    if (estado == null) return 'Sin registrar';
    return AttendanceStatus.getName(estado!);
  }

  @override
  String toString() {
    return 'AsistenciaEstudiante(estudianteId: $estudianteId, nombre: $nombreCompleto, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AsistenciaEstudiante && other.estudianteId == estudianteId;
  }

  @override
  int get hashCode => estudianteId.hashCode;
}