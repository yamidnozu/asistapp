import 'package:json_annotation/json_annotation.dart';

part 'institution_config.g.dart';

@JsonSerializable()
class InstitutionConfig {
  final String? id;
  final String? institucionId;
  final bool notificacionesActivas;
  final String canalNotificacion;
  final String modoNotificacionAsistencia;
  final String? horaDisparoNotificacion;
  final bool notificarAusenciaTotalDiaria;

  InstitutionConfig({
    this.id,
    this.institucionId,
    this.notificacionesActivas = false,
    this.canalNotificacion = 'PUSH', // PUSH (app) | WHATSAPP | BOTH
    this.modoNotificacionAsistencia =
        'MANUAL_ONLY', // MANUAL_ONLY | INSTANT | END_OF_DAY
    this.horaDisparoNotificacion,
    this.notificarAusenciaTotalDiaria = false,
  });

  factory InstitutionConfig.fromJson(Map<String, dynamic> json) =>
      _$InstitutionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InstitutionConfigToJson(this);
}
