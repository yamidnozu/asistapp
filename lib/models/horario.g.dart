// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'horario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Horario _$HorarioFromJson(Map<String, dynamic> json) => Horario(
      id: json['id'] as String,
      periodoId: json['periodoId'] as String,
      grupoId: json['grupoId'] as String,
      materiaId: json['materiaId'] as String,
      profesorId: json['profesorId'] as String?,
      diaSemana: (json['diaSemana'] as num).toInt(),
      horaInicio: json['horaInicio'] as String,
      horaFin: json['horaFin'] as String,
      institucionId: json['institucionId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      grupo: Grupo.fromJson(json['grupo'] as Map<String, dynamic>),
      materia: Materia.fromJson(json['materia'] as Map<String, dynamic>),
      periodoAcademico: PeriodoAcademico.fromJson(
          json['periodoAcademico'] as Map<String, dynamic>),
      profesor: json['profesor'] == null
          ? null
          : User.fromJson(json['profesor'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$HorarioToJson(Horario instance) => <String, dynamic>{
      'id': instance.id,
      'periodoId': instance.periodoId,
      'grupoId': instance.grupoId,
      'materiaId': instance.materiaId,
      'profesorId': instance.profesorId,
      'diaSemana': instance.diaSemana,
      'horaInicio': instance.horaInicio,
      'horaFin': instance.horaFin,
      'institucionId': instance.institucionId,
      'createdAt': instance.createdAt.toIso8601String(),
      'grupo': instance.grupo,
      'materia': instance.materia,
      'periodoAcademico': instance.periodoAcademico,
      'profesor': instance.profesor,
    };
