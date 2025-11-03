import 'package:flutter/material.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/form_widgets.dart';
import '../../../providers/institution_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Step 1: Información de Cuenta (Email, Institución si aplica)
class UserAccountStep extends StatefulWidget {
  final TextEditingController emailController;
  final String userRole;
  final String? selectedInstitutionId;
  final ValueChanged<String?> onInstitutionChanged;
  final bool isEditMode;
  final FocusNode? emailFocusNode;
  final FocusNode? institutionFocusNode;
  final GlobalKey<FormFieldState<String>>? emailFieldKey;
  final GlobalKey<FormFieldState<String>>? institutionFieldKey;

  const UserAccountStep({
    super.key,
    required this.emailController,
    required this.userRole,
    required this.selectedInstitutionId,
    required this.onInstitutionChanged,
    this.isEditMode = false,
    this.emailFocusNode,
    this.institutionFocusNode,
    this.emailFieldKey,
    this.institutionFieldKey,
  });

  @override
  State<UserAccountStep> createState() => _UserAccountStepState();
}

class _UserAccountStepState extends State<UserAccountStep> {
  bool _isReloading = false;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de la Cuenta',
          style: context.textStyles.headlineSmall,
        ),
        SizedBox(height: spacing.md),
        Text(
          'Configure las credenciales de acceso del usuario',
          style: context.textStyles.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: spacing.lg),

        // Email
        CustomTextFormField(
          key: const Key('emailUsuarioField'),
          fieldKey: widget.emailFieldKey,
          focusNode: widget.emailFocusNode,
          controller: widget.emailController,
          labelText: 'Email',
          hintText: '${widget.userRole}@ejemplo.com',
          keyboardType: TextInputType.emailAddress,
          enabled: !widget.isEditMode, // No editable en modo edición
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El email es requerido';
              }
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Ingrese un email válido';
              }
              return null;
            },
        ),
        SizedBox(height: spacing.md),

        // Dropdown de Institución (solo para admin_institucion creado por super_admin)
        if (widget.userRole == 'admin_institucion') ...[
          Consumer2<AuthProvider, InstitutionProvider>(
            builder: (context, authProvider, institutionProvider, child) {
              // Mostrar dropdown cuando se crea un admin_institucion.
              // Si la lista de instituciones está vacía, mostrar un mensaje y un botón para recargar.
              if (institutionProvider.institutions.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No se encontraron instituciones.',
                      style: context.textStyles.bodyMedium.copyWith(color: context.colors.textSecondary),
                    ),
                    SizedBox(height: spacing.sm),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isReloading
                              ? null
                              : () async {
                                  final token = authProvider.accessToken;
                                  if (token != null) {
                                    setState(() => _isReloading = true);
                                    try {
                                      await institutionProvider.loadInstitutions(token, page: 1, limit: 100);
                                    } finally {
                                      if (mounted) setState(() => _isReloading = false);
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('No hay sesión activa para recargar instituciones')),
                                    );
                                  }
                                },
                          child: _isReloading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Recargar instituciones'),
                        ),
                        SizedBox(width: spacing.md),
                        TextButton(
                          onPressed: () {},
                          child: Text('Contactar soporte', style: context.textStyles.bodySmall.withColor(context.colors.info)),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return CustomDropdownFormField<String>(
                key: const Key('institucionDropdown'),
                fieldKey: widget.institutionFieldKey,
                focusNode: widget.institutionFocusNode,
                value: widget.selectedInstitutionId,
                labelText: 'Institución',
                hintText: 'Seleccione una institución',
                items: institutionProvider.institutions.map((institution) {
                  return DropdownMenuItem<String>(
                    value: institution.id,
                    child: Text(institution.nombre),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Debe seleccionar una institución';
                  }
                  return null;
                },
                onChanged: widget.onInstitutionChanged,
              );
            },
          ),
          SizedBox(height: spacing.md),
        ],

        if (!widget.isEditMode) ...[
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
                    'Se generará una contraseña temporal. El usuario deberá cambiarla en su primer acceso.',
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.info,
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
