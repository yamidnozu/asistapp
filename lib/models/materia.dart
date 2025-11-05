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
      id: json['id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      institucionId: json['institucionId'],
      createdAt: DateTime.parse(json['createdAt']),
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