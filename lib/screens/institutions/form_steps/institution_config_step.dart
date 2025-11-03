import 'package:flutter/material.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/components/clarity_components.dart';

/// Step 3: Configuración y Estado
class InstitutionConfigStep extends StatelessWidget {
  final bool activa;
  final ValueChanged<bool> onActivaChanged;
  final bool isEditMode;

  const InstitutionConfigStep({
    super.key,
    required this.activa,
    required this.onActivaChanged,
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
          'Establezca el estado operativo de la institución',
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
                  Icon(Icons.warning_amber_rounded, color: colors.warning, size: 20),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      'Importante',
                      style: textStyles.bodyMedium.semiBold.withColor(colors.warning),
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

        if (!isEditMode) ...[
          SizedBox(height: spacing.lg),
          Container(
            padding: EdgeInsets.all(spacing.md),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: colors.info, size: 20),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    'Después de crear la institución, podrá asignarle administradores y usuarios.',
                    style: textStyles.bodySmall.copyWith(
                      color: colors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
