import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'institution_config.dart';

part 'institution.g.dart';

@JsonSerializable()
class Institution {
  final String id;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? email;
  final bool activa;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campos para compatibilidad con roles de usuario
  final String? role; // Rol del usuario en esta institución
  final Map<String, dynamic>? metadata;
  final InstitutionConfig? configuraciones;

  Institution({
    required this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.email,
    required this.activa,
    this.createdAt,
    this.updatedAt,
    this.role,
    this.metadata,
    this.configuraciones,
  });

  factory Institution.fromJson(Map<String, dynamic> json) =>
      _$InstitutionFromJson(json);

  Map<String, dynamic> toJson() => _$InstitutionToJson(this);

  String get name => nombre;

  // --- GETTERS PARA CONFIGURACIÓN DE NOTIFICACIONES ---

  /// Retorna true si las notificaciones están activas
  bool get notificacionesActivas =>
      configuraciones?.notificacionesActivas ?? false;

  /// Retorna true si solo se envía cuando el profesor da click (modo manual)
  bool get isModoManual =>
      configuraciones?.modoNotificacionAsistencia == 'MANUAL_ONLY';

  /// Texto amigable para mostrar en la lista de instituciones
  String get notificationConfigSummary {
    if (configuraciones == null || !configuraciones!.notificacionesActivas) {
      return 'Notificaciones desactivadas';
    }

    // Mapear canal de notificación
    String canal;
    switch (configuraciones!.canalNotificacion) {
      case 'WHATSAPP':
        canal = 'WhatsApp';
        break;
      case 'PUSH':
        canal = 'App';
        break;
      case 'BOTH':
        canal = 'WhatsApp + App';
        break;
      default:
        canal = 'Sin configurar';
    }

    // Mapear modo de notificación
    switch (configuraciones!.modoNotificacionAsistencia) {
      case 'INSTANT':
        return '$canal: Inmediato';
      case 'MANUAL_ONLY':
        return '$canal: Manual';
      case 'END_OF_DAY':
        final hora =
            configuraciones!.horaDisparoNotificacion?.substring(0, 5) ??
                '18:00';
        return '$canal: $hora';
      default:
        return '$canal: No configurado';
    }
  }

  /// Color para el badge en la UI según estado de notificaciones
  Color? get notificationStatusColor {
    if (configuraciones == null || !configuraciones!.notificacionesActivas) {
      return null; // Gris/Default
    }
    return const Color(0xFF16A34A); // Verde (Success)
  }

  Institution copyWith({
    String? id,
    String? nombre,
    String? direccion,
    String? telefono,
    String? email,
    bool? activa,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? role,
    Map<String, dynamic>? metadata,
    InstitutionConfig? configuraciones,
  }) {
    return Institution(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      activa: activa ?? this.activa,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
      metadata: metadata ?? this.metadata,
      configuraciones: configuraciones ?? this.configuraciones,
    );
  }

  @override
  String toString() {
    return 'Institution(id: $id, nombre: $nombre, activa: $activa)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Institution && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
