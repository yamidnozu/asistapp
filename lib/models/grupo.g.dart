// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grupo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Grupo _$GrupoFromJson(Map<String, dynamic> json) => Grupo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      grado: json['grado'] as String,
      seccion: json['seccion'] as String?,
      periodoId: json['periodoId'] as String,
      institucionId: json['institucionId'] as String,
      createdAt: _dateTimeFromJson(json['createdAt'] as String),
      periodoAcademico: PeriodoAcademico.fromJson(
          json['periodoAcademico'] as Map<String, dynamic>),
      count: GrupoCount.fromJson(json['_count'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GrupoToJson(Grupo instance) => <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'grado': instance.grado,
      'seccion': instance.seccion,
      'periodoId': instance.periodoId,
      'institucionId': instance.institucionId,
      'createdAt': _dateTimeToJson(instance.createdAt),
      'periodoAcademico': instance.periodoAcademico,
      '_count': instance.count,
    };

GrupoCount _$GrupoCountFromJson(Map<String, dynamic> json) => GrupoCount(
      estudiantesGrupos: (json['estudiantesGrupos'] as num).toInt(),
      horarios: (json['horarios'] as num).toInt(),
    );

Map<String, dynamic> _$GrupoCountToJson(GrupoCount instance) =>
    <String, dynamic>{
      'estudiantesGrupos': instance.estudiantesGrupos,
      'horarios': instance.horarios,
    };

PeriodoAcademico _$PeriodoAcademicoFromJson(Map<String, dynamic> json) =>
    PeriodoAcademico(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      fechaInicio: _dateTimeFromJson(json['fechaInicio'] as String),
      fechaFin: _dateTimeFromJson(json['fechaFin'] as String),
      activo: json['activo'] as bool,
    );

Map<String, dynamic> _$PeriodoAcademicoToJson(PeriodoAcademico instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'fechaInicio': _dateTimeToJson(instance.fechaInicio),
      'fechaFin': _dateTimeToJson(instance.fechaFin),
      'activo': instance.activo,
    };
