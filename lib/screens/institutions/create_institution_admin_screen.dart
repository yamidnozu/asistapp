import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/institution.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/form_widgets.dart';

class CreateInstitutionAdminScreen extends StatefulWidget {
  final Institution institution;

  const CreateInstitutionAdminScreen({
    super.key,
    required this.institution,
  });

  @override
  State<CreateInstitutionAdminScreen> createState() => _CreateInstitutionAdminScreenState();
}

class _CreateInstitutionAdminScreenState extends State<CreateInstitutionAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _isLoading = false;
  bool _activo = true;

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _saveAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final createRequest = CreateUserRequest(
        email: _emailController.text.trim(),
        password: 'TempPass123!', // Contraseña temporal que debe ser cambiada por el usuario
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : null,
        rol: 'admin_institucion',
        institucionId: widget.institution.id,
        rolEnInstitucion: 'admin', // Rol específico dentro de la institución
      );

      final success = await userProvider.createUser(
        authProvider.accessToken!,
        createRequest,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Administrador de institución creado exitosamente',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.go('/institutions');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al crear administrador: ${e.toString()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Administrador - ${widget.institution.nombre}'),
        backgroundColor: colors.primary,
        foregroundColor: colors.getTextColorForBackground(colors.primary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: spacing.lg),

              Text(
                'Información Personal',
                style: textStyles.headlineMedium.bold,
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
                              controller: _nombresController,
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
                              controller: _apellidosController,
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
                            controller: _nombresController,
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
                          SizedBox(height: spacing.md),
                          CustomTextFormField(
                            controller: _apellidosController,
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
              SizedBox(height: spacing.md),

              // Email
              CustomTextFormField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'admin@ejemplo.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El email es requerido';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Ingrese un email válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: spacing.md),

              // Teléfono
              CustomTextFormField(
                controller: _telefonoController,
                labelText: 'Teléfono',
                hintText: '+57 300 123 4567',
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
              SizedBox(height: spacing.lg),

              // Información de la institución
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.borderRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.all(spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Institución Asignada',
                        style: textStyles.titleMedium.bold,
                      ),
                      SizedBox(height: spacing.sm),
                      Row(
                        children: [
                          Icon(Icons.business, color: colors.primary),
                          SizedBox(width: spacing.sm),
                          Expanded(
                            child: Text(
                              widget.institution.nombre,
                              style: textStyles.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: spacing.lg),

              // Estado activo
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.borderRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.all(spacing.md),
                  child: Row(
                    children: [
                      Icon(
                        _activo ? Icons.check_circle : Icons.cancel,
                        color: _activo ? colors.success : colors.error,
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: Text(
                          'Usuario Activo',
                          style: textStyles.bodyLarge,
                        ),
                      ),
                      Switch(
                        value: _activo,
                        onChanged: (value) {
                          setState(() => _activo = value);
                        },
                        activeColor: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: spacing.xl),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: spacing.md),
                        side: BorderSide(color: colors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(spacing.borderRadius),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: textStyles.button.withColor(colors.primary),
                      ),
                    ),
                  ),
                  SizedBox(width: spacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAdmin,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: spacing.md),
                        backgroundColor: colors.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(spacing.borderRadius),
                        ),
                      ),
                      child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text('Crear Administrador', style: textStyles.button),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}