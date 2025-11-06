/// Modelo que representa la información de asistencia de un estudiante
/// Corresponde a la respuesta del endpoint GET /horarios/:horarioId/asistencias
class AsistenciaEstudiante {
  final String estudianteId;
  final String nombres;
  final String apellidos;
  final String identificacion;
  final String? estado; // null si no ha registrado asistencia
  final DateTime? fechaRegistro;

  AsistenciaEstudiante({
    required this.estudianteId,
    required this.nombres,
    required this.apellidos,
    required this.identificacion,
    this.estado,
    this.fechaRegistro,
  });

  /// Crea una instancia desde un JSON del backend
  factory AsistenciaEstudiante.fromJson(Map<String, dynamic> json) {
    return AsistenciaEstudiante(
      estudianteId: json['estudiante']['id'] as String,
      nombres: json['estudiante']['nombres'] as String,
      apellidos: json['estudiante']['apellidos'] as String,
      identificacion: json['estudiante']['identificacion'] as String,
      estado: json['estado'] as String?,
      fechaRegistro: json['fechaRegistro'] != null
          ? DateTime.parse(json['fechaRegistro'] as String)
          : null,
    );
  }

  /// Convierte la instancia a JSON
  Map<String, dynamic> toJson() {
    return {
      'estudiante': {
        'id': estudianteId,
        'nombres': nombres,
        'apellidos': apellidos,
        'identificacion': identificacion,
      },
      'estado': estado,
      'fechaRegistro': fechaRegistro?.toIso8601String(),
    };
  }

  /// Obtiene el nombre completo del estudiante
  String get nombreCompleto => '$nombres $apellidos';

  /// Verifica si el estudiante está presente
  bool get estaPresente => estado == 'PRESENTE';

  /// Verifica si el estudiante está ausente
  bool get estaAusente => estado == 'AUSENTE';

  /// Verifica si el estudiante tiene tardanza
  bool get tieneTardanza => estado == 'TARDANZA';

  /// Verifica si el estudiante está justificado
  bool get estaJustificado => estado == 'JUSTIFICADO';

  /// Verifica si el estudiante no ha registrado asistencia
  bool get sinRegistrar => estado == null;

  /// Obtiene el color correspondiente al estado de asistencia
  String getEstadoColor() {
    switch (estado) {
      case 'PRESENTE':
        return '#4CAF50'; // Verde
      case 'AUSENTE':
        return '#F44336'; // Rojo
      case 'TARDANZA':
        return '#FF9800'; // Naranja
      case 'JUSTIFICADO':
        return '#2196F3'; // Azul
      default:
        return '#9E9E9E'; // Gris para sin registrar
    }
  }

  /// Obtiene el texto descriptivo del estado
  String getEstadoTexto() {
    switch (estado) {
      case 'PRESENTE':
        return 'Presente';
      case 'AUSENTE':
        return 'Ausente';
      case 'TARDANZA':
        return 'Tardanza';
      case 'JUSTIFICADO':
        return 'Justificado';
      default:
        return 'Sin registrar';
    }
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