/// Modelo para notificaciones in-app

class NotificacionInApp {
  final String id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final String? estudianteId;
  final String? materiaId;
  final DateTime createdAt;
  final Map<String, dynamic>? datos;

  NotificacionInApp({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    this.estudianteId,
    this.materiaId,
    required this.createdAt,
    this.datos,
  });

  factory NotificacionInApp.fromJson(Map<String, dynamic> json) {
    return NotificacionInApp(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipo: json['tipo'] as String,
      leida: json['leida'] as bool? ?? false,
      estudianteId: json['estudianteId'] as String?,
      materiaId: json['materiaId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      datos: json['datos'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'leida': leida,
      'estudianteId': estudianteId,
      'materiaId': materiaId,
      'createdAt': createdAt.toIso8601String(),
      'datos': datos,
    };
  }

  NotificacionInApp copyWith({
    String? id,
    String? titulo,
    String? mensaje,
    String? tipo,
    bool? leida,
    String? estudianteId,
    String? materiaId,
    DateTime? createdAt,
    Map<String, dynamic>? datos,
  }) {
    return NotificacionInApp(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      tipo: tipo ?? this.tipo,
      leida: leida ?? this.leida,
      estudianteId: estudianteId ?? this.estudianteId,
      materiaId: materiaId ?? this.materiaId,
      createdAt: createdAt ?? this.createdAt,
      datos: datos ?? this.datos,
    );
  }

  /// Obtiene el ícono apropiado para el tipo de notificación
  String get iconName {
    switch (tipo) {
      case 'ausencia':
        return 'warning';
      case 'tardanza':
        return 'schedule';
      case 'justificado':
        return 'check_circle';
      case 'sistema':
        return 'info';
      default:
        return 'notifications';
    }
  }

  /// Obtiene el tiempo relativo desde la creación
  String get tiempoRelativo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Ahora';
    } else if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
