import 'package:json_annotation/json_annotation.dart';

part 'institution_config.g.dart';

@JsonSerializable()
class InstitutionConfig {
  final String id;
  final String institucionId;
  final bool notificacionesActivas;
  final String canalNotificacion;
  final String modoNotificacionAsistencia;
  final String? horaDisparoNotificacion;

  InstitutionConfig({
    required this.id,
    required this.institucionId,
    this.notificacionesActivas = false,
    this.canalNotificacion = 'NONE',
    this.modoNotificacionAsistencia = 'MANUAL_ONLY',
    this.horaDisparoNotificacion,
  });

  factory InstitutionConfig.fromJson(Map<String, dynamic> json) => _$InstitutionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InstitutionConfigToJson(this);
}
