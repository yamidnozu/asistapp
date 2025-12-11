// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grupo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Grupo _$GrupoFromJson(Map<String, dynamic> json) => Grupo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      grado: json['grado'].toString(),
      seccion: json['seccion'] as String?,
      periodoId: json['periodoId'] as String?,
      institucionId: json['institucionId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : _dateTimeFromJson(json['createdAt'] as String),
      periodoAcademico: json['periodoAcademico'] == null
          ? PeriodoAcademico(
              id: json['periodoId'] as String? ?? '',
              nombre: '',
              fechaInicio: DateTime.now(),
              fechaFin: DateTime.now(),
              activo: false,
            )
          : PeriodoAcademico.fromJson(
              json['periodoAcademico'] as Map<String, dynamic>),
      count: json['_count'] == null
          ? null
          : GrupoCount.fromJson(json['_count'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GrupoToJson(Grupo instance) => <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'grado': instance.grado,
      'seccion': instance.seccion,
      'periodoId': instance.periodoId,
      'institucionId': instance.institucionId,
      'createdAt': instance.createdAt == null
          ? null
          : _dateTimeToJson(instance.createdAt!),
      'periodoAcademico': instance.periodoAcademico,
      '_count': instance.count,
    };

GrupoCount _$GrupoCountFromJson(Map<String, dynamic> json) => GrupoCount(
      estudiantesGrupos: (json['estudiantesGrupos'] as num?)?.toInt() ?? 0,
      horarios: (json['horarios'] as num?)?.toInt() ?? 0,
      asistencias: (json['asistencias'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$GrupoCountToJson(GrupoCount instance) =>
    <String, dynamic>{
      'estudiantesGrupos': instance.estudiantesGrupos,
      'horarios': instance.horarios,
      'asistencias': instance.asistencias,
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
