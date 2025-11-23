import 'package:flutter/material.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/form_widgets.dart';

/// Step 2: Información de Contacto y Ubicación
class InstitutionContactStep extends StatelessWidget {
  final TextEditingController direccionController;
  final TextEditingController telefonoController;

  const InstitutionContactStep({
    super.key,
    required this.direccionController,
    required this.telefonoController,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contacto y Ubicación',
          style: context.textStyles.headlineSmall,
        ),
        SizedBox(height: spacing.md),
        Text(
          'Información para contactar y localizar la institución',
          style: context.textStyles.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: spacing.lg),

        CustomTextFormField(
          key: const Key('direccionInstitucionField'),
          controller: direccionController,
          labelText: 'Dirección',
          hintText: 'Dirección completa de la institución',
          prefixIcon: const Icon(Icons.location_on),
          maxLines: 3,
          validator: (value) {
            // La dirección es opcional
            return null;
          },
        ),
        SizedBox(height: spacing.md),

        CustomTextFormField(
          key: const Key('telefonoInstitucionField'),
          controller: telefonoController,
          labelText: 'Teléfono',
          hintText: '+57 300 123 4567',
          prefixIcon: const Icon(Icons.phone),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]+$');
              if (!phoneRegex.hasMatch(value.trim())) {
                return 'Ingrese un teléfono válido';
              }
            }
            return null;
          },
        ),

        SizedBox(height: spacing.md),
        Container(
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: context.colors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: context.colors.info, size: 20),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  'Estos datos serán visibles para los usuarios de la institución.',
                  style: context.textStyles.bodySmall.copyWith(
                    color: context.colors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
