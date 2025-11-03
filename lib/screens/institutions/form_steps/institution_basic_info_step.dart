import 'package:flutter/material.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/form_widgets.dart';

/// Step 1: Información Básica de la Institución
class InstitutionBasicInfoStep extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController emailController;

  const InstitutionBasicInfoStep({
    super.key,
    required this.nombreController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Básica',
          style: context.textStyles.headlineSmall,
        ),
        SizedBox(height: spacing.md),
        Text(
          'Ingrese los datos fundamentales de la institución',
          style: context.textStyles.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: spacing.lg),

        CustomTextFormField(
          key: const Key('nombreInstitucionField'),
          controller: nombreController,
          labelText: 'Nombre de la Institución',
          hintText: 'Ingrese el nombre completo',
          prefixIcon: const Icon(Icons.business),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es obligatorio';
            }
            if (value.trim().length < 3) {
              return 'El nombre debe tener al menos 3 caracteres';
            }
            return null;
          },
        ),
        SizedBox(height: spacing.md),

        CustomTextFormField(
          key: const Key('emailInstitucionField'),
          controller: emailController,
          labelText: 'Email Institucional',
          hintText: 'contacto@institucion.com',
          prefixIcon: const Icon(Icons.email),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Ingrese un email válido';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
