// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clase_del_dia.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClaseDelDia _$ClaseDelDiaFromJson(Map<String, dynamic> json) => ClaseDelDia(
      id: json['id'] as String,
      diaSemana: (json['diaSemana'] as num).toInt(),
      horaInicio: json['horaInicio'] as String,
      horaFin: json['horaFin'] as String,
      grupo: GrupoSimple.fromJson(json['grupo'] as Map<String, dynamic>),
      materia: MateriaSimple.fromJson(json['materia'] as Map<String, dynamic>),
      periodoAcademico: PeriodoAcademicoSimple.fromJson(
          json['periodoAcademico'] as Map<String, dynamic>),
      institucion:
          Institucion.fromJson(json['institucion'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClaseDelDiaToJson(ClaseDelDia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'diaSemana': instance.diaSemana,
      'horaInicio': instance.horaInicio,
      'horaFin': instance.horaFin,
      'grupo': instance.grupo,
      'materia': instance.materia,
      'periodoAcademico': instance.periodoAcademico,
      'institucion': instance.institucion,
    };

GrupoSimple _$GrupoSimpleFromJson(Map<String, dynamic> json) => GrupoSimple(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      grado: json['grado'] as String,
      seccion: json['seccion'] as String?,
    );

Map<String, dynamic> _$GrupoSimpleToJson(GrupoSimple instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'grado': instance.grado,
      'seccion': instance.seccion,
    };

MateriaSimple _$MateriaSimpleFromJson(Map<String, dynamic> json) =>
    MateriaSimple(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String?,
    );

Map<String, dynamic> _$MateriaSimpleToJson(MateriaSimple instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'codigo': instance.codigo,
    };

PeriodoAcademicoSimple _$PeriodoAcademicoSimpleFromJson(
        Map<String, dynamic> json) =>
    PeriodoAcademicoSimple(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      activo: json['activo'] as bool,
    );

Map<String, dynamic> _$PeriodoAcademicoSimpleToJson(
        PeriodoAcademicoSimple instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'activo': instance.activo,
    };

Institucion _$InstitucionFromJson(Map<String, dynamic> json) => Institucion(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );

Map<String, dynamic> _$InstitucionToJson(Institucion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
    };
