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

  factory Institution.fromJson(Map<String, dynamic> json) => _$InstitutionFromJson(json);

  Map<String, dynamic> toJson() => _$InstitutionToJson(this);

  String get name => nombre;

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