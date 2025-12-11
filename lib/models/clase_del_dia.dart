import 'package:json_annotation/json_annotation.dart';
import 'institution_config.dart';

part 'clase_del_dia.g.dart';

@JsonSerializable()
class ClaseDelDia {
  final String id;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final GrupoSimple grupo;
  final MateriaSimple materia;
  final PeriodoAcademicoSimple periodoAcademico;
  final Institucion institucion;

  ClaseDelDia({
    required this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.grupo,
    required this.materia,
    required this.periodoAcademico,
    required this.institucion,
  });

  factory ClaseDelDia.fromJson(Map<String, dynamic> json) =>
      _$ClaseDelDiaFromJson(json);

  Map<String, dynamic> toJson() => _$ClaseDelDiaToJson(this);

  String get diaSemanaNombre {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return dias[diaSemana - 1];
  }

  String get horarioFormato => '$horaInicio - $horaFin';

  String get descripcion => '${materia.nombre} - ${grupo.nombreCompleto}';
}

// Versiones simplificadas para respuestas de clases del día
@JsonSerializable()
class GrupoSimple {
  final String id;
  final String nombre;
  final String grado;
  final String? seccion;

  GrupoSimple({
    required this.id,
    required this.nombre,
    required this.grado,
    this.seccion,
  });

  factory GrupoSimple.fromJson(Map<String, dynamic> json) =>
      _$GrupoSimpleFromJson(json);

  Map<String, dynamic> toJson() => _$GrupoSimpleToJson(this);

  String get nombreCompleto => seccion != null ? '$grado $seccion' : grado;
}

@JsonSerializable()
class MateriaSimple {
  final String id;
  final String nombre;
  final String? codigo;

  MateriaSimple({
    required this.id,
    required this.nombre,
    this.codigo,
  });

  factory MateriaSimple.fromJson(Map<String, dynamic> json) =>
      _$MateriaSimpleFromJson(json);

  Map<String, dynamic> toJson() => _$MateriaSimpleToJson(this);

  String get nombreConCodigo => codigo != null ? '$codigo - $nombre' : nombre;
}

@JsonSerializable()
class PeriodoAcademicoSimple {
  final String id;
  final String nombre;
  final bool activo;

  PeriodoAcademicoSimple({
    required this.id,
    required this.nombre,
    required this.activo,
  });

  factory PeriodoAcademicoSimple.fromJson(Map<String, dynamic> json) =>
      _$PeriodoAcademicoSimpleFromJson(json);

  Map<String, dynamic> toJson() => _$PeriodoAcademicoSimpleToJson(this);
}

@JsonSerializable()
class Institucion {
  final String id;
  final String nombre;
  final InstitutionConfig? configuraciones;

  Institucion({
    required this.id,
    required this.nombre,
    this.configuraciones,
  });

  factory Institucion.fromJson(Map<String, dynamic> json) =>
      _$InstitucionFromJson(json);

  Map<String, dynamic> toJson() => _$InstitucionToJson(this);

  /// Helper para saber si el modo de notificación es MANUAL_ONLY
  bool get isModoManual =>
      configuraciones?.modoNotificacionAsistencia == 'MANUAL_ONLY';

  /// Helper para saber si las notificaciones están activas
  bool get notificacionesActivas =>
      configuraciones?.notificacionesActivas ?? false;
}
