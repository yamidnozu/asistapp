import 'grupo.dart';
import 'materia.dart';

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
  });

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      id: json['id'],
      periodoId: json['periodoId'],
      grupoId: json['grupoId'],
      materiaId: json['materiaId'],
      profesorId: json['profesorId'],
      diaSemana: json['diaSemana'],
      horaInicio: json['horaInicio'],
      horaFin: json['horaFin'],
      institucionId: json['institucionId'],
      createdAt: DateTime.parse(json['createdAt']),
      grupo: Grupo.fromJson(json['grupo']),
      materia: Materia.fromJson(json['materia']),
      periodoAcademico: PeriodoAcademico.fromJson(json['periodoAcademico']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'periodoId': periodoId,
      'grupoId': grupoId,
      'materiaId': materiaId,
      'profesorId': profesorId,
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'institucionId': institucionId,
      'createdAt': createdAt.toIso8601String(),
      'grupo': grupo.toJson(),
      'materia': materia.toJson(),
      'periodoAcademico': periodoAcademico.toJson(),
    };
  }

  String get diaSemanaNombre {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[diaSemana - 1];
  }

  String get horarioFormato => '$horaInicio - $horaFin';

  String get descripcion => '${materia.nombre} - ${grupo.nombreCompleto}';
}