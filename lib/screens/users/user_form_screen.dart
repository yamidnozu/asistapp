import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/form_widgets.dart';

class UserFormScreen extends StatefulWidget {
  final String userRole; // 'profesor' o 'estudiante'

  const UserFormScreen({
    super.key, 
    required this.userRole,
  });

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
  bool _isInitialLoading = false;
  bool _activo = true;
  User? _user; // Usuario cargado para edición

  @override
  void initState() {
    super.initState();
    // No cargar usuario aquí, se hace en didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserIfEditing();
  }

  Future<void> _loadUserIfEditing() async {
    // Evitar cargar múltiples veces
    if (_user != null || _isInitialLoading) return;

    final uri = GoRouterState.of(context).uri;
    final queryParams = uri.queryParameters;
    
    final isEdit = queryParams['edit'] == 'true';
    final userId = queryParams['userId'];

    if (isEdit && userId != null) {
      setState(() => _isInitialLoading = true);
      
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        await userProvider.loadUserById(
          authProvider.accessToken!,
          userId,
        );
        
        final user = userProvider.selectedUser;
        if (user != null && mounted) {
          setState(() => _user = user);
          _fillFormWithUserData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al cargar usuario: ${e.toString()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          // Volver a la lista si no se puede cargar el usuario
          context.go('/users');
        }
      } finally {
        if (mounted) {
          setState(() => _isInitialLoading = false);
        }
      }
    }
  }

  void _fillFormWithUserData() {
    final user = _user!;
    _nombresController.text = user.nombres;
    _apellidosController.text = user.apellidos;
    _emailController.text = user.email;
    _telefonoController.text = user.telefono ?? '';
    _activo = user.activo;

    if (user.estudiante != null) {
      _identificacionController.text = user.estudiante!.identificacion;
      _nombreResponsableController.text = user.estudiante!.nombreResponsable ?? '';
      _telefonoResponsableController.text = user.estudiante!.telefonoResponsable ?? '';
    }

    // Para profesores, los campos específicos no están disponibles en el modelo User actual
    // Se podrían cargar desde una API adicional si es necesario
  }

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

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (_user != null) {
        // Modo edición
        final updateRequest = UpdateUserRequest(
          email: _emailController.text.trim(),
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : null,
          identificacion: _identificacionController.text.trim(),
          nombreResponsable: widget.userRole == 'estudiante' ? _nombreResponsableController.text.trim().isNotEmpty ? _nombreResponsableController.text.trim() : null : null,
          telefonoResponsable: widget.userRole == 'estudiante' ? _telefonoResponsableController.text.trim().isNotEmpty ? _telefonoResponsableController.text.trim() : null : null,
          activo: _activo,
        );

        final success = await userProvider.updateUser(
          authProvider.accessToken!,
          _user!.id,
          updateRequest,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.userRole == 'profesor' ? 'Profesor' : 'Estudiante'} actualizado exitosamente',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          context.go('/users');
        }
      } else {
        // Modo creación
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al ${_user != null ? 'actualizar' : 'crear'} ${widget.userRole == 'profesor' ? 'profesor' : 'estudiante'}: ${e.toString()}',
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

    if (_isInitialLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando usuario...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      onPressed: _isLoading ? null : _saveUser,
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
                          : Text('${_user != null ? 'Actualizar' : 'Crear'}', style: textStyles.button),
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