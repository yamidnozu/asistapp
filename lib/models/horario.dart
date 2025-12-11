import 'package:json_annotation/json_annotation.dart';
import 'grupo.dart';
import 'materia.dart';
import 'user.dart';

part 'horario.g.dart';

@JsonSerializable()
class Horario {
  final String id;
  final String periodoId;
  final String grupoId;
  final String materiaId;
  final String? profesorId;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final String institucionId;
  final DateTime createdAt;
  final Grupo grupo;
  final Materia materia;
  final PeriodoAcademico periodoAcademico;
  final User? profesor;

  Horario({
    required this.id,
    required this.periodoId,
    required this.grupoId,
    required this.materiaId,
    this.profesorId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.institucionId,
    required this.createdAt,
    required this.grupo,
    required this.materia,
    required this.periodoAcademico,
    this.profesor,
  });

  factory Horario.fromJson(Map<String, dynamic> json) =>
      _$HorarioFromJson(json);

  Map<String, dynamic> toJson() => _$HorarioToJson(this);

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

  String get descripcion =>
      '${materia.nombre} - ${grupo.nombreCompleto}${profesor != null ? ' (${profesor!.nombreCompleto})' : ''}';
}
