// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'institution_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstitutionConfig _$InstitutionConfigFromJson(Map<String, dynamic> json) =>
    InstitutionConfig(
      id: json['id'] as String?,
      institucionId: json['institucionId'] as String?,
      notificacionesActivas: json['notificacionesActivas'] as bool? ?? false,
      canalNotificacion: json['canalNotificacion'] as String? ?? 'NONE',
      modoNotificacionAsistencia:
          json['modoNotificacionAsistencia'] as String? ?? 'MANUAL_ONLY',
      horaDisparoNotificacion: json['horaDisparoNotificacion'] as String?,
    );

Map<String, dynamic> _$InstitutionConfigToJson(InstitutionConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'institucionId': instance.institucionId,
      'notificacionesActivas': instance.notificacionesActivas,
      'canalNotificacion': instance.canalNotificacion,
      'modoNotificacionAsistencia': instance.modoNotificacionAsistencia,
      'horaDisparoNotificacion': instance.horaDisparoNotificacion,
    };
