/// Constantes para estados y tipos de asistencia en AsistApp
/// Central para evitar strings mágicos en toda la aplicación

class AttendanceStatus {
  static const String presente = 'PRESENTE';
  static const String ausente = 'AUSENTE';
  static const String tardanza = 'TARDANZA';
  static const String justificado = 'JUSTIFICADO';

  /// Verifica si un string es un estado de asistencia válido
  static bool isValid(String status) {
    return [presente, ausente, tardanza, justificado].contains(status);
  }

  /// Obtiene el nombre legible de un estado de asistencia
  static String getName(String status) {
    switch (status) {
      case presente:
        return 'Presente';
      case ausente:
        return 'Ausente';
      case tardanza:
        return 'Tardanza';
      case justificado:
        return 'Justificado';
      default:
        return 'Desconocido';
    }
  }

  /// Obtiene el color asociado a un estado de asistencia
  static String getColor(String status) {
    switch (status) {
      case presente:
        return '#4CAF50'; // Verde
      case ausente:
        return '#F44336'; // Rojo
      case tardanza:
        return '#FF9800'; // Naranja
      case justificado:
        return '#2196F3'; // Azul
      default:
        return '#9E9E9E'; // Gris
    }
  }
}

class AttendanceType {
  static const String manual = 'MANUAL';
  static const String qr = 'QR';
  static const String automatico = 'AUTOMATICO';

  /// Verifica si un string es un tipo de registro válido
  static bool isValid(String type) {
    return [manual, qr, automatico].contains(type);
  }

  /// Obtiene el nombre legible de un tipo de registro
  static String getName(String type) {
    switch (type) {
      case manual:
        return 'Manual';
      case qr:
        return 'Código QR';
      case automatico:
        return 'Automático';
      default:
        return 'Desconocido';
    }
  }
}
