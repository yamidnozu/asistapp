class Institution {
  final String id;
  final String nombre;
  final String codigo;
  final String? direccion;
  final String? telefono;
  final String? email;
  final bool activa;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campos para compatibilidad con roles de usuario
  final String? role; // Rol del usuario en esta institución
  final Map<String, dynamic>? metadata;

  Institution({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.direccion,
    this.telefono,
    this.email,
    this.activa = true,
    this.createdAt,
    this.updatedAt,
    this.role,
    this.metadata,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? json['name'] as String? ?? 'Institución sin nombre',
      codigo: json['codigo'] as String? ?? '',
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      activa: json['activa'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      role: json['rolEnInstitucion'] as String? ?? json['role'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      'activa': activa,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (role != null) 'role': role,
      if (role != null) 'rolEnInstitucion': role,
      if (metadata != null) 'metadata': metadata,
    };
  }

  // Getters para compatibilidad
  String get name => nombre;

  Institution copyWith({
    String? id,
    String? nombre,
    String? codigo,
    String? direccion,
    String? telefono,
    String? email,
    bool? activa,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? role,
    Map<String, dynamic>? metadata,
  }) {
    return Institution(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      activa: activa ?? this.activa,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Institution(id: $id, nombre: $nombre, codigo: $codigo, activa: $activa)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Institution && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}