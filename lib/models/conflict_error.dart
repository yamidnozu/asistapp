import 'dart:convert';

/// Clase para representar errores de conflicto de horarios
class ConflictError {
  final String code;
  final String reason;
  final String message;
  final Map<String, dynamic>? meta;

  ConflictError({
    required this.code,
    required this.reason,
    required this.message,
    this.meta,
  });

  /// Crea una instancia desde la respuesta de error del backend
  factory ConflictError.fromBackendError(String errorMessage) {
    try {
      // El mensaje de error viene formateado como: "409 - mensaje - código - razón - {meta}"
      final parts = errorMessage.split(' - ');
      if (parts.length >= 4) {
        final code = parts[2];
        final reason = parts[3];
        final message = parts[1];

        Map<String, dynamic>? meta;
        if (parts.length > 4) {
          try {
            final metaString = parts.sublist(4).join(' - ');
            if (metaString.startsWith('{') && metaString.endsWith('}')) {
              meta = Map<String, dynamic>.from(
                jsonDecode(metaString) as Map
              );
            }
          } catch (_) {
            // Si no se puede parsear el meta, continuar sin él
          }
        }

        return ConflictError(
          code: code,
          reason: reason,
          message: message,
          meta: meta,
        );
      }
    } catch (_) {
      // Si el parsing falla, crear un error genérico
    }

    // Fallback para errores que no siguen el formato esperado
    return ConflictError(
      code: 'CONFLICT_ERROR',
      reason: 'unknown_conflict',
      message: errorMessage,
      meta: null,
    );
  }

  /// Obtiene los IDs de horarios en conflicto
  List<String> get conflictingHorarioIds {
    if (meta != null && meta!['conflictingHorarioIds'] is List) {
      return List<String>.from(meta!['conflictingHorarioIds']);
    }
    return [];
  }

  /// Verifica si es un conflicto de grupo
  bool get isGrupoConflict => reason == 'grupo_conflict';

  /// Verifica si es un conflicto de profesor
  bool get isProfesorConflict => reason == 'profesor_conflict';

  /// Obtiene un mensaje de usuario amigable basado en el tipo de conflicto
  String get userFriendlyMessage {
    switch (reason) {
      case 'grupo_conflict':
        return 'El grupo ya tiene una clase programada en este horario.';
      case 'profesor_conflict':
        return 'El profesor ya tiene una clase programada en este horario.';
      default:
        return message;
    }
  }

  /// Obtiene sugerencias específicas para resolver el conflicto
  List<String> get suggestions {
    switch (reason) {
      case 'grupo_conflict':
        return [
          'Cambia la hora de la clase',
          'Selecciona un día diferente',
          'Elige otra materia disponible',
          'Verifica los horarios existentes del grupo'
        ];
      case 'profesor_conflict':
        return [
          'Cambia la hora de la clase',
          'Selecciona un día diferente',
          'Elige otro profesor disponible',
          'Verifica los horarios existentes del profesor'
        ];
      default:
        return [
          'Cambia la hora de la clase',
          'Selecciona un día diferente',
          'Elige otro profesor disponible',
          'Verifica los horarios existentes'
        ];
    }
  }

  @override
  String toString() {
    return 'ConflictError(code: $code, reason: $reason, message: $message, meta: $meta)';
  }
}