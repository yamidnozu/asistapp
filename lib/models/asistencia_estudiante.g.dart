// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asistencia_estudiante.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AsistenciaEstudiante _$AsistenciaEstudianteFromJson(
        Map<String, dynamic> json) =>
    AsistenciaEstudiante(
      id: json['id'] as String?,
      estudianteId: json['estudianteId'] as String,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      identificacion: json['identificacion'] as String,
      estado: json['estado'] as String?,
      observaciones: json['observaciones'] as String?,
      fechaRegistro: json['fechaRegistro'] == null
          ? null
          : DateTime.parse(json['fechaRegistro'] as String),
    );

Map<String, dynamic> _$AsistenciaEstudianteToJson(
        AsistenciaEstudiante instance) =>
    <String, dynamic>{
      'id': instance.id,
      'estudianteId': instance.estudianteId,
      'nombres': instance.nombres,
      'apellidos': instance.apellidos,
      'identificacion': instance.identificacion,
      'estado': instance.estado,
      'observaciones': instance.observaciones,
      'fechaRegistro': instance.fechaRegistro?.toIso8601String(),
    };
