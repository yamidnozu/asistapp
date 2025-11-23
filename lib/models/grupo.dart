import 'package:json_annotation/json_annotation.dart';

part 'grupo.g.dart';

@JsonSerializable()
class Grupo {
  final String id;
  final String nombre;
  final String grado;
  final String? seccion;
  final String periodoId;
  final String institucionId;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  final PeriodoAcademico periodoAcademico;
  @JsonKey(name: '_count')
  final GrupoCount count;

  Grupo({
    required this.id,
    required this.nombre,
    required this.grado,
    this.seccion,
    required this.periodoId,
    required this.institucionId,
    required this.createdAt,
    required this.periodoAcademico,
    required this.count,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) => _$GrupoFromJson(json);
  Map<String, dynamic> toJson() => _$GrupoToJson(this);

  int get estudiantesGruposCount => count.estudiantesGrupos;
  int get horariosCount => count.horarios;
  String get nombreCompleto => seccion != null ? '$grado $seccion' : grado;
}

DateTime _dateTimeFromJson(String date) => DateTime.parse(date);
String _dateTimeToJson(DateTime date) => date.toIso8601String();

@JsonSerializable()
class GrupoCount {
  final int estudiantesGrupos;
  final int horarios;

  GrupoCount({
    required this.estudiantesGrupos,
    required this.horarios,
  });

  factory GrupoCount.fromJson(Map<String, dynamic> json) => _$GrupoCountFromJson(json);
  Map<String, dynamic> toJson() => _$GrupoCountToJson(this);
}

@JsonSerializable()
class PeriodoAcademico {
  final String id;
  final String nombre;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime fechaInicio;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime fechaFin;
  final bool activo;

  PeriodoAcademico({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.activo,
  });

  factory PeriodoAcademico.fromJson(Map<String, dynamic> json) => _$PeriodoAcademicoFromJson(json);
  Map<String, dynamic> toJson() => _$PeriodoAcademicoToJson(this);
}