import 'package:flutter/material.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/form_widgets.dart';
import '../../../widgets/components/clarity_components.dart';

/// Step 3: Detalles Específicos por Rol (Profesor o Estudiante)
class RoleSpecificDetailsStep extends StatelessWidget {
  final String userRole;

  // Campos para Profesor
  final TextEditingController? tituloController;
  final TextEditingController? especialidadController;

  // Campos para Estudiante
  final TextEditingController? nombreResponsableController;
  final TextEditingController? telefonoResponsableController;

  final GlobalKey<FormFieldState<String>>? tituloFieldKey;
  final GlobalKey<FormFieldState<String>>? especialidadFieldKey;
  final GlobalKey<FormFieldState<String>>? nombreResponsableFieldKey;
  final GlobalKey<FormFieldState<String>>? telefonoResponsableFieldKey;

  // Para gestión de acudientes (solo en edición de estudiante)
  final String? estudianteId;
  final VoidCallback? onGestionarAcudientes;

  const RoleSpecificDetailsStep({
    super.key,
    required this.userRole,
    this.tituloController,
    this.especialidadController,
    this.nombreResponsableController,
    this.telefonoResponsableController,
    this.tituloFocusNode,
    this.especialidadFocusNode,
    this.nombreResponsableFocusNode,
    this.telefonoResponsableFocusNode,
    this.tituloFieldKey,
    this.especialidadFieldKey,
    this.nombreResponsableFieldKey,
    this.telefonoResponsableFieldKey,
    this.estudianteId,
    this.onGestionarAcudientes,
  });

  final FocusNode? tituloFocusNode;
  final FocusNode? especialidadFocusNode;
  final FocusNode? nombreResponsableFocusNode;
  final FocusNode? telefonoResponsableFocusNode;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (userRole == 'profesor') {
      return _buildProfesorDetails(context, spacing);
    } else if (userRole == 'estudiante') {
      return _buildEstudianteDetails(context, spacing);
    } else if (userRole == 'admin_institucion') {
      return _buildAdminInstitucionDetails(context, spacing);
    } else {
      // super_admin u otros roles no tienen detalles adicionales
      return _buildNoAdditionalDetails(context);
    }
  }

  Widget _buildAdminInstitucionDetails(BuildContext context, dynamic spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información del Cargo',
          style: context.textStyles.headlineSmall,
        ),
        SizedBox(height: spacing.md),
        Text(
          'Complete los datos del cargo administrativo (opcional)',
          style: context.textStyles.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: spacing.lg),
        if (tituloController != null) ...[
          ClaritySection(
            title: 'Cargo Institucional',
            child: CustomTextFormField(
              fieldKey: tituloFieldKey,
              focusNode: tituloFocusNode,
              controller: tituloController!,
              labelText: 'Cargo / Título',
              hintText: 'Director, Rector, Coordinador, etc.',
              validator: (value) {
                // El cargo es opcional para admin_institucion
                return null;
              },
            ),
          ),
        ] else ...[
          ClarityCard(
            leading: Icon(
              Icons.check_circle,
              color: context.colors.success,
              size: 48,
            ),
            title: const Text('Información Completa'),
            subtitle: const Text(
              'Puede proceder a guardar el usuario.',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfesorDetails(BuildContext context, dynamic spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Académica',
          style: context.textStyles.headlineSmall,
        ),
        SizedBox(height: spacing.md),
        Text(
          'Complete los datos académicos del profesor',
          style: context.textStyles.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: spacing.lg),
        ClaritySection(
          title: 'Credenciales Académicas',
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: CustomTextFormField(
                                fieldKey: tituloFieldKey,
                                focusNode: tituloFocusNode,
                                controller: tituloController!,
                                labelText: 'Título Académico',
                                hintText: 'Licenciado en..., Magíster en...',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El título académico es requerido';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'El título debe tener al menos 3 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: spacing.md),
                            Expanded(
                              child: CustomTextFormField(
                                fieldKey: especialidadFieldKey,
                                focusNode: especialidadFocusNode,
                                controller: especialidadController!,
                                labelText: 'Especialidad',
                                hintText: 'Matemáticas, Física, etc.',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'La especialidad es requerida';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'La especialidad debe tener al menos 3 caracteres';
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
                              fieldKey: tituloFieldKey,
                              controller: tituloController!,
                              labelText: 'Título Académico',
                              hintText: 'Licenciado en..., Magíster en...',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El título académico es requerido';
                                }
                                if (value.trim().length < 3) {
                                  return 'El título debe tener al menos 3 caracteres';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: spacing.md),
                            CustomTextFormField(
                              fieldKey: especialidadFieldKey,
                              controller: especialidadController!,
                              labelText: 'Especialidad',
                              hintText: 'Matemáticas, Física, etc.',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'La especialidad es requerida';
                                }
                                if (value.trim().length < 3) {
                                  return 'La especialidad debe tener al menos 3 caracteres';
                                }
                                return null;
                              },
                            ),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstudianteDetails(BuildContext context, dynamic spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección de Acudientes (usuarios con acceso al sistema)
        Text(
          'Acudientes',
          style: context.textStyles.headlineSmall,
        ),
        SizedBox(height: spacing.md),
        Text(
          'Gestione los acudientes, padres o tutores que tendrán acceso a la plataforma para ver el seguimiento del estudiante.',
          style: context.textStyles.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: spacing.lg),

        // Mensaje si es modo creación
        if (estudianteId == null) ...[
          Container(
            padding: EdgeInsets.all(spacing.md),
            decoration: BoxDecoration(
              color: context.colors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: context.colors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber,
                    color: context.colors.warning, size: 24),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    'Para gestionar acudientes, primero debe guardar el estudiante. Después de crearlo, podrá asignar acudientes desde la pantalla de detalle o editando nuevamente.',
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Botón para abrir gestión de acudientes
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGestionarAcudientes,
              icon: const Icon(Icons.family_restroom),
              label: const Text('Gestionar Acudientes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.info,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: spacing.md),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoAdditionalDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen',
          style: context.textStyles.headlineSmall,
        ),
        SizedBox(height: context.spacing.md),
        ClarityCard(
          leading: Icon(
            Icons.check_circle,
            color: context.colors.success,
            size: 48,
          ),
          title: const Text('Información Completa'),
          subtitle: const Text(
            'Este tipo de usuario no requiere información adicional. Puede proceder a guardar.',
          ),
        ),
      ],
    );
  }
}
