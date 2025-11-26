import 'package:json_annotation/json_annotation.dart';

part 'materia.g.dart';

@JsonSerializable()
class Materia {
  final String id;
  final String nombre;
  final String? codigo;
  final String? institucionId;
  final DateTime? createdAt;

  Materia({
    required this.id,
    required this.nombre,
    this.codigo,
    this.institucionId,
    this.createdAt,
  });

  factory Materia.fromJson(Map<String, dynamic> json) => _$MateriaFromJson(json);

  Map<String, dynamic> toJson() => _$MateriaToJson(this);

  String get nombreConCodigo => codigo != null ? '$codigo - $nombre' : nombre;
}