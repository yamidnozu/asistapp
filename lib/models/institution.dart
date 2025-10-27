class Institution {
  final String id;
  final String name;
  final String? description;
  final String? role; // Rol del usuario en esta institución
  final Map<String, dynamic>? metadata;

  Institution({
    required this.id,
    required this.name,
    this.description,
    this.role,
    this.metadata,
  });
  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'] as String,
      name: json['nombre'] as String? ?? json['name'] as String? ?? 'Institución sin nombre', // Soporta tanto 'nombre' como 'name'
      description: json['description'] as String?,
      role: json['rolEnInstitucion'] as String? ?? json['role'] as String?, // Soporta tanto 'rolEnInstitucion' como 'role'
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name, // Mantener 'name' para compatibilidad con otros usos
      'nombre': name, // Agregar 'nombre' por si se necesita
      if (description != null) 'description': description,
      if (role != null) 'role': role,
      if (role != null) 'rolEnInstitucion': role, // Agregar 'rolEnInstitucion' por si se necesita
      if (metadata != null) 'metadata': metadata,
    };
  }
  Institution copyWith({
    String? id,
    String? name,
    String? description,
    String? role,
    Map<String, dynamic>? metadata,
  }) {
    return Institution(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      role: role ?? this.role,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Institution(id: $id, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Institution && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}