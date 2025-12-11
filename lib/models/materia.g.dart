// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'materia.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Materia _$MateriaFromJson(Map<String, dynamic> json) => Materia(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String?,
      institucionId: json['institucionId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MateriaToJson(Materia instance) => <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'codigo': instance.codigo,
      'institucionId': instance.institucionId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
