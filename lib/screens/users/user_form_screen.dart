import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/dashboard_widgets.dart';
import '../../widgets/form_widgets.dart';

class UserFormScreen extends StatefulWidget {
  final String userRole; // 'profesor' o 'estudiante'

  const UserFormScreen({super.key, required this.userRole});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _identificacionController = TextEditingController();
  final _tituloController = TextEditingController();
  final _especialidadController = TextEditingController();
  final _nombreResponsableController = TextEditingController();
  final _telefonoResponsableController = TextEditingController();

  bool _isLoading = false;
  bool _activo = true;

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _identificacionController.dispose();
    _tituloController.dispose();
    _especialidadController.dispose();
    _nombreResponsableController.dispose();
    _telefonoResponsableController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final createRequest = CreateUserRequest(
        email: _emailController.text.trim(),
        password: 'TempPass123!', // TODO: Implementar generación de contraseña segura o pedir al usuario
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : null,
        identificacion: _identificacionController.text.trim(),
        rol: widget.userRole,
        titulo: widget.userRole == 'profesor' ? _tituloController.text.trim() : null,
        especialidad: widget.userRole == 'profesor' ? _especialidadController.text.trim() : null,
        nombreResponsable: widget.userRole == 'estudiante' ? _nombreResponsableController.text.trim().isNotEmpty ? _nombreResponsableController.text.trim() : null : null,
        telefonoResponsable: widget.userRole == 'estudiante' ? _telefonoResponsableController.text.trim().isNotEmpty ? _telefonoResponsableController.text.trim() : null : null,
        institucionId: authProvider.selectedInstitutionId,
      );

      final success = await userProvider.createUser(
        authProvider.accessToken!,
        createRequest,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.userRole == 'profesor' ? 'Profesor' : 'Estudiante'} creado exitosamente',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.go('/users');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al crear ${widget.userRole == 'profesor' ? 'profesor' : 'estudiante'}: ${e.toString()}',
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
      backgroundColor: colors.background,
      appBar: DashboardAppBar(
        title: 'Crear ${widget.userRole == 'profesor' ? 'Profesor' : 'Estudiante'}',
        backgroundColor: colors.primary,
        actions: [
          DashboardAppBarActions(
            userRole: 'Admin Institución',
            roleIcon: Icons.admin_panel_settings,
            onLogout: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final responsive = ResponsiveUtils.getResponsiveValues(constraints);
              return DashboardBody(
                userGreeting: UserGreetingWidget(
                  userName: authProvider.user?['nombres'] ?? 'Admin',
                  responsive: responsive,
                ),
                dashboardOptions: _buildFormContent(colors, spacing, textStyles, constraints),
                responsive: responsive,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFormContent(AppColors colors, AppSpacing spacing, AppTextStyles textStyles, BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              hintText: '${widget.userRole}@ejemplo.com',
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

            // Teléfono e Identificación
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
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
                        ),
                        SizedBox(width: spacing.md),
                        Expanded(
                          child: CustomTextFormField(
                            controller: _identificacionController,
                            labelText: 'Identificación',
                            hintText: 'Cédula o documento',
                            validator: (value) {
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
                        SizedBox(height: spacing.md),
                        CustomTextFormField(
                          controller: _identificacionController,
                          labelText: 'Identificación',
                          hintText: 'Cédula o documento',
                          validator: (value) {
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

            if (widget.userRole == 'profesor') ...[
              Text(
                'Información Académica',
                style: textStyles.headlineMedium.bold,
              ),
              SizedBox(height: spacing.lg),

              // Título y Especialidad
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              controller: _tituloController,
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
                              controller: _especialidadController,
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
                            controller: _tituloController,
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
                            controller: _especialidadController,
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
              SizedBox(height: spacing.lg),
            ],

            if (widget.userRole == 'estudiante') ...[
              Text(
                'Información del Responsable',
                style: textStyles.headlineMedium.bold,
              ),
              SizedBox(height: spacing.lg),

              // Nombre del Responsable
              CustomTextFormField(
                controller: _nombreResponsableController,
                labelText: 'Nombre del Responsable',
                hintText: 'Padre, madre o tutor',
                validator: (value) {
                  // El responsable es opcional para estudiantes
                  return null;
                },
              ),
              SizedBox(height: spacing.md),

              // Teléfono del Responsable
              CustomTextFormField(
                controller: _telefonoResponsableController,
                labelText: 'Teléfono del Responsable',
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
            ],

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
                    onPressed: _isLoading ? null : _createUser,
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
                        : Text('Crear ${widget.userRole == 'profesor' ? 'Profesor' : 'Estudiante'}', style: textStyles.button),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}