import 'grupo.dart';
import 'materia.dart';
import 'user.dart';

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

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      id: json['id'] as String? ?? '',
      periodoId: json['periodoId'] as String? ?? '',
      grupoId: json['grupoId'] as String? ?? '',
      materiaId: json['materiaId'] as String? ?? '',
      profesorId: json['profesorId'],
      diaSemana: json['diaSemana'] as int? ?? 1,
      horaInicio: json['horaInicio'] as String? ?? '08:00',
      horaFin: json['horaFin'] as String? ?? '10:00',
      institucionId: json['institucionId'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
      grupo: json['grupo'] != null ? Grupo.fromJson(json['grupo']) : Grupo(
        id: json['grupoId'] ?? '',
        nombre: 'Grupo desconocido',
        grado: 'N/A',
        periodoId: json['periodoId'] ?? '',
        institucionId: json['institucionId'] ?? '',
        createdAt: DateTime.now(),
        periodoAcademico: PeriodoAcademico(
          id: json['periodoId'] ?? '',
          nombre: 'Periodo desconocido',
          fechaInicio: DateTime.now(),
          fechaFin: DateTime.now(),
          activo: false,
        ),
        count: GrupoCount(estudiantesGrupos: 0, horarios: 0),
      ),
      materia: json['materia'] != null ? Materia.fromJson(json['materia']) : Materia(
        id: json['materiaId'] ?? '',
        nombre: 'Materia desconocida',
        codigo: null,
        institucionId: json['institucionId'] ?? '',
        createdAt: DateTime.now(),
      ),
      periodoAcademico: json['periodoAcademico'] != null ? PeriodoAcademico.fromJson(json['periodoAcademico']) : PeriodoAcademico(
        id: json['periodoId'] ?? '',
        nombre: 'Periodo desconocido',
        fechaInicio: DateTime.now(),
        fechaFin: DateTime.now(),
        activo: false,
      ),
      profesor: json['profesor'] != null ? User.fromJson(json['profesor']) : null,
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
      if (profesor != null) 'profesor': profesor!.toJson(),
    };
  }

  String get diaSemanaNombre {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[diaSemana - 1];
  }

  String get horarioFormato => '$horaInicio - $horaFin';

  String get descripcion => '${materia.nombre} - ${grupo.nombreCompleto}${profesor != null ? ' (${profesor!.nombreCompleto})' : ''}';
}