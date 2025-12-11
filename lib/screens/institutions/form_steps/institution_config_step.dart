import 'package:flutter/material.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/components/clarity_components.dart';

/// Step 3: Configuración y Estado
class InstitutionConfigStep extends StatelessWidget {
  final bool activa;
  final ValueChanged<bool> onActivaChanged;

  final bool notificacionesActivas;
  final ValueChanged<bool> onNotificacionesActivasChanged;

  final String canalNotificacion;
  final ValueChanged<String?> onCanalNotificacionChanged;

  final String modoNotificacionAsistencia;
  final ValueChanged<String?> onModoNotificacionAsistenciaChanged;

  final String? horaDisparoNotificacion;
  final ValueChanged<String?> onHoraDisparoNotificacionChanged;

  final bool isEditMode;

  const InstitutionConfigStep({
    super.key,
    required this.activa,
    required this.onActivaChanged,
    required this.notificacionesActivas,
    required this.onNotificacionesActivasChanged,
    required this.canalNotificacion,
    required this.onCanalNotificacionChanged,
    required this.modoNotificacionAsistencia,
    required this.onModoNotificacionAsistenciaChanged,
    this.horaDisparoNotificacion,
    required this.onHoraDisparoNotificacionChanged,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración',
          style: textStyles.headlineSmall,
        ),
        SizedBox(height: spacing.md),
        Text(
          'Establezca el estado operativo y las notificaciones',
          style: textStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: spacing.lg),

        ClarityCard(
          leading: Icon(
            activa ? Icons.check_circle : Icons.cancel,
            color: activa ? colors.success : colors.error,
            size: 48,
          ),
          title: Text(
            'Estado de la Institución',
            style: textStyles.bodyLarge.semiBold,
          ),
          subtitle: Text(
            activa ? 'Institución operativa' : 'Institución inactiva',
            style: textStyles.bodyMedium.withColor(
              activa ? colors.success : colors.error,
            ),
          ),
          trailing: Switch(
            value: activa,
            onChanged: onActivaChanged,
            activeColor: colors.success,
          ),
        ),

        SizedBox(height: spacing.lg),

        // Notificaciones Section
        Text(
          'Notificaciones',
          style: textStyles.titleMedium,
        ),
        SizedBox(height: spacing.md),

        ClarityCard(
          leading: Icon(
            notificacionesActivas
                ? Icons.notifications_active
                : Icons.notifications_off,
            color:
                notificacionesActivas ? colors.primary : colors.textSecondary,
            size: 32,
          ),
          title: Text(
            'Activar Notificaciones',
            style: textStyles.bodyLarge.semiBold,
          ),
          subtitle: Text(
            notificacionesActivas
                ? 'Las notificaciones se enviarán según la configuración'
                : 'No se enviarán notificaciones',
            style: textStyles.bodyMedium.withColor(colors.textSecondary),
          ),
          trailing: Switch(
            value: notificacionesActivas,
            onChanged: onNotificacionesActivasChanged,
            activeColor: colors.primary,
          ),
        ),

        if (notificacionesActivas) ...[
          SizedBox(height: spacing.md),
          DropdownButtonFormField<String>(
            value: canalNotificacion,
            decoration: const InputDecoration(
              labelText: 'Canal de Notificación',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'WHATSAPP', child: Text('WhatsApp')),
              DropdownMenuItem(value: 'SMS', child: Text('SMS')),
              DropdownMenuItem(value: 'NONE', child: Text('Ninguno')),
            ],
            onChanged: onCanalNotificacionChanged,
          ),
          SizedBox(height: spacing.md),
          DropdownButtonFormField<String>(
            value: modoNotificacionAsistencia,
            decoration: const InputDecoration(
              labelText: 'Modo de Notificación de Asistencia',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                  value: 'INSTANT', child: Text('Instantáneo (Al registrar)')),
              DropdownMenuItem(
                  value: 'END_OF_DAY', child: Text('Fin del Día (Resumen)')),
              DropdownMenuItem(
                  value: 'MANUAL_ONLY', child: Text('Solo Manual')),
            ],
            onChanged: onModoNotificacionAsistenciaChanged,
          ),
          if (modoNotificacionAsistencia == 'END_OF_DAY') ...[
            SizedBox(height: spacing.md),
            InkWell(
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: horaDisparoNotificacion != null
                      ? TimeOfDay(
                          hour:
                              int.parse(horaDisparoNotificacion!.split(':')[0]),
                          minute:
                              int.parse(horaDisparoNotificacion!.split(':')[1]))
                      : const TimeOfDay(hour: 18, minute: 0),
                );
                if (picked != null) {
                  final formatted =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
                  onHoraDisparoNotificacionChanged(formatted);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Hora de Disparo',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  horaDisparoNotificacion ?? 'Seleccionar hora',
                  style: textStyles.bodyMedium,
                ),
              ),
            ),
          ],
        ],

        SizedBox(height: spacing.lg),

        Container(
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: colors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: colors.warning, size: 20),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      'Importante',
                      style: textStyles.bodyMedium.semiBold
                          .withColor(colors.warning),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.sm),
              Text(
                activa
                    ? 'Los usuarios podrán acceder y usar los servicios de esta institución.'
                    : 'Si desactiva la institución, los usuarios no podrán iniciar sesión ni acceder a sus datos.',
                style: textStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
