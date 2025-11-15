class Materia {
  final String id;
  final String nombre;
  final String? codigo;
  final String institucionId;
  final DateTime createdAt;

  Materia({
    required this.id,
    required this.nombre,
    this.codigo,
    required this.institucionId,
    required this.createdAt,
  });

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      codigo: json['codigo'],
      institucionId: json['institucionId'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'institucionId': institucionId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get nombreConCodigo => codigo != null ? '$codigo - $nombre' : nombre;
}