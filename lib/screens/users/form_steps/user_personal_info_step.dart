import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/form_widgets.dart';

/// Formatter para campos de teléfono que permite +, números, espacios, guiones y paréntesis
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Solo permite: +, números (0-9), espacios, guiones y paréntesis
    final newText = newValue.text.replaceAll(RegExp(r'[^\+0-9\s\-\(\)]'), '');

    // Solo permite un + al inicio
    String formatted = newText;
    if (formatted.contains('+')) {
      final firstPlus = formatted.indexOf('+');
      if (firstPlus > 0) {
        // Si hay un + pero no al inicio, lo removemos
        formatted = formatted.replaceAll('+', '');
      } else {
        // Remover cualquier + adicional después del primero
        formatted = '+${formatted.substring(1).replaceAll('+', '')}';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length
            .clamp(0, newValue.selection.end.clamp(0, formatted.length)),
      ),
    );
  }
}

/// Step 2: Información Personal (Nombres, Apellidos, Teléfono, Identificación)
class UserPersonalInfoStep extends StatelessWidget {
  final TextEditingController nombresController;
  final TextEditingController apellidosController;
  final TextEditingController telefonoController;
  final TextEditingController identificacionController;
  final String userRole;
  final bool activo;
  final ValueChanged<bool> onActivoChanged;
  final bool activoEditable;
  final FocusNode? nombresFocusNode;
  final FocusNode? apellidosFocusNode;
  final FocusNode? telefonoFocusNode;
  final FocusNode? identificacionFocusNode;
  final GlobalKey<FormFieldState<String>>? nombresFieldKey;
  final GlobalKey<FormFieldState<String>>? apellidosFieldKey;
  final GlobalKey<FormFieldState<String>>? telefonoFieldKey;
  final GlobalKey<FormFieldState<String>>? identificacionFieldKey;

  const UserPersonalInfoStep({
    super.key,
    required this.nombresController,
    required this.apellidosController,
    required this.telefonoController,
    required this.identificacionController,
    required this.userRole,
    required this.activo,
    required this.onActivoChanged,
    this.activoEditable = true,
    this.nombresFocusNode,
    this.apellidosFocusNode,
    this.telefonoFocusNode,
    this.identificacionFocusNode,
    this.nombresFieldKey,
    this.apellidosFieldKey,
    this.telefonoFieldKey,
    this.identificacionFieldKey,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Personal',
          style: context.textStyles.headlineSmall,
        ),
        SizedBox(height: spacing.md),
        Text(
          'Ingrese los datos personales del usuario',
          style: context.textStyles.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: spacing.lg),

        // Nombres y Apellidos
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return isWide
                ? Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          key: const Key('user_form_nombres'),
                          fieldKey: nombresFieldKey,
                          focusNode: nombresFocusNode,
                          controller: nombresController,
                          labelText: 'Nombres',
                          hintText: 'Ingrese los nombres',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Los nombres son requeridos';
                            }
                            if (value.trim().length < 2) {
                              return 'Los nombres deben tener al menos 2 caracteres';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: CustomTextFormField(
                          key: const Key('user_form_apellidos'),
                          fieldKey: apellidosFieldKey,
                          focusNode: apellidosFocusNode,
                          controller: apellidosController,
                          labelText: 'Apellidos',
                          hintText: 'Ingrese los apellidos',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Los apellidos son requeridos';
                            }
                            if (value.trim().length < 2) {
                              return 'Los apellidos deben tener al menos 2 caracteres';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      CustomTextFormField(
                        key: const Key('nombresUsuarioField'),
                        fieldKey: nombresFieldKey,
                        focusNode: nombresFocusNode,
                        controller: nombresController,
                        labelText: 'Nombres',
                        hintText: 'Ingrese los nombres',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Los nombres son requeridos';
                          }
                          if (value.trim().length < 2) {
                            return 'Los nombres deben tener al menos 2 caracteres';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: spacing.inputSpacing),
                      CustomTextFormField(
                        key: const Key('apellidosUsuarioField'),
                        fieldKey: apellidosFieldKey,
                        focusNode: apellidosFocusNode,
                        controller: apellidosController,
                        labelText: 'Apellidos',
                        hintText: 'Ingrese los apellidos',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Los apellidos son requeridos';
                          }
                          if (value.trim().length < 2) {
                            return 'Los apellidos deben tener al menos 2 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                  );
          },
        ),
        SizedBox(height: spacing.inputSpacing),

        // Teléfono e Identificación
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return isWide
                ? Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          key: const Key('user_form_telefono'),
                          fieldKey: telefonoFieldKey,
                          controller: telefonoController,
                          labelText: 'Teléfono',
                          hintText: '+57 300 123 4567',
                          keyboardType: TextInputType.phone,
                          maxLength: 20,
                          inputFormatters: [
                            PhoneInputFormatter(),
                            LengthLimitingTextInputFormatter(20),
                          ],
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
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: CustomTextFormField(
                          key: const Key('user_form_identificacion'),
                          fieldKey: identificacionFieldKey,
                          controller: identificacionController,
                          labelText: 'Identificación',
                          hintText: 'Cédula o documento',
                          validator: (value) {
                            // Identificación es opcional para admin_institucion y super_admin
                            if (userRole == 'admin_institucion' ||
                                userRole == 'super_admin') {
                              return null;
                            }

                            if (value == null || value.trim().isEmpty) {
                              return 'La identificación es requerida';
                            }
                            if (value.trim().length < 5) {
                              return 'La identificación debe tener al menos 5 caracteres';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      CustomTextFormField(
                        key: const Key('user_form_telefono'),
                        fieldKey: telefonoFieldKey,
                        focusNode: telefonoFocusNode,
                        controller: telefonoController,
                        labelText: 'Teléfono',
                        hintText: '+57 300 123 4567',
                        keyboardType: TextInputType.phone,
                        maxLength: 20,
                        inputFormatters: [
                          PhoneInputFormatter(),
                          LengthLimitingTextInputFormatter(20),
                        ],
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
                      CustomTextFormField(
                        key: const Key('user_form_identificacion'),
                        fieldKey: identificacionFieldKey,
                        focusNode: identificacionFocusNode,
                        controller: identificacionController,
                        labelText: 'Identificación',
                        hintText: 'Cédula o documento',
                        validator: (value) {
                          // Identificación es opcional para admin_institucion y super_admin
                          if (userRole == 'admin_institucion' ||
                              userRole == 'super_admin') {
                            return null;
                          }

                          if (value == null || value.trim().isEmpty) {
                            return 'La identificación es requerida';
                          }
                          if (value.trim().length < 5) {
                            return 'La identificación debe tener al menos 5 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                  );
          },
        ),
        SizedBox(height: spacing.lg),

        // Estado Activo
        SwitchListTile(
          title: const Text('Usuario Activo'),
          subtitle: Text(
            activo
                ? 'El usuario puede iniciar sesión'
                : 'El usuario está deshabilitado',
            style: context.textStyles.bodySmall.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          value: activo,
          onChanged: activoEditable ? onActivoChanged : null,
          activeColor: context.colors.success,
        ),
      ],
    );
  }
}
