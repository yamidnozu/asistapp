import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/institution_provider.dart';
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
  String? _selectedInstitutionId; // Institución seleccionada para admin_institucion

  @override
  void initState() {
    super.initState();
    // No cargar usuario aquí, se hace en didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserIfEditing();
    _loadInstitutionsIfNeeded();
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

  Future<void> _loadInstitutionsIfNeeded() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['rol'] as String?;
    
    // Solo cargar instituciones si el usuario actual es super_admin y está creando/editando admin_institucion
    if (userRole == 'super_admin' && widget.userRole == 'admin_institucion') {
      final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);
      
      // Solo cargar si no hay instituciones ya cargadas
      if (institutionProvider.institutions.isEmpty) {
        await institutionProvider.loadInstitutions(
          authProvider.accessToken!,
          page: 1,
          limit: 100, // Cargar todas para el dropdown
        );
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

    // Preseleccionar institución si existe
    if (user.instituciones.isNotEmpty) {
      _selectedInstitutionId = user.instituciones.first.id;
    }

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

    // Validación adicional para admin_institucion
    if (widget.userRole == 'admin_institucion' && _selectedInstitutionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Debe seleccionar una institución',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

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
          identificacion: widget.userRole == 'estudiante' ? _identificacionController.text.trim() : null,
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
                '${_getRoleDisplayName(widget.userRole)} actualizado exitosamente',
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
          identificacion: widget.userRole == 'estudiante' ? _identificacionController.text.trim() : null,
          rol: widget.userRole,
          titulo: widget.userRole == 'profesor' ? _tituloController.text.trim() : null,
          especialidad: widget.userRole == 'profesor' ? _especialidadController.text.trim() : null,
          nombreResponsable: widget.userRole == 'estudiante' ? _nombreResponsableController.text.trim().isNotEmpty ? _nombreResponsableController.text.trim() : null : null,
          telefonoResponsable: widget.userRole == 'estudiante' ? _telefonoResponsableController.text.trim().isNotEmpty ? _telefonoResponsableController.text.trim() : null : null,
          institucionId: widget.userRole == 'admin_institucion' ? _selectedInstitutionId : authProvider.selectedInstitutionId,
          rolEnInstitucion: widget.userRole == 'admin_institucion' ? 'admin' : null,
        );

        final success = await userProvider.createUser(
          authProvider.accessToken!,
          createRequest,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_getRoleDisplayName(widget.userRole)} creado exitosamente',
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
              'Error al ${_user != null ? 'actualizar' : 'crear'} ${_getRoleDisplayName(widget.userRole)}: ${e.toString()}',
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

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'profesor':
        return 'Profesor';
      case 'estudiante':
        return 'Estudiante';
      case 'admin_institucion':
        return 'Administrador de Institución';
      case 'super_admin':
        return 'Super Administrador';
      default:
        return 'Usuario';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;
    final title = _user != null ? 'Editar Usuario' : 'Crear ${_getRoleDisplayName(widget.userRole)}';

    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando usuario...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
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
                            key: const Key('user_form_nombres'),
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
                            key: const Key('user_form_apellidos'),
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
                          key: const Key('nombresUsuarioField'),
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
                          key: const Key('apellidosUsuarioField'),
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
              key: const Key('emailUsuarioField'),
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

            // Dropdown de Institución (solo para admin_institucion creado por super_admin)
            if (widget.userRole == 'admin_institucion') ...[
              Consumer2<AuthProvider, InstitutionProvider>(
                builder: (context, authProvider, institutionProvider, child) {
                  final userRole = authProvider.user?['rol'] as String?;
                  final isSuperAdmin = userRole == 'super_admin';
                  
                  if (!isSuperAdmin) return const SizedBox.shrink();
                  
                  return CustomDropdownFormField<String>(
                    key: const Key('institucionDropdown'),
                    value: _selectedInstitutionId,
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
                    onChanged: (value) {
                      setState(() {
                        _selectedInstitutionId = value;
                      });
                    },
                  );
                },
              ),
              SizedBox(height: spacing.md),
            ],

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
                            key: const Key('user_form_identificacion'),
                            controller: _identificacionController,
                            labelText: 'Identificación',
                            hintText: 'Cédula o documento',
                            validator: (value) {
                              // Identificación es opcional para admin_institucion y super_admin
                              if (widget.userRole == 'admin_institucion' || widget.userRole == 'super_admin') {
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
                          key: const Key('user_form_identificacion'),
                          controller: _identificacionController,
                          labelText: 'Identificación',
                          hintText: 'Cédula o documento',
                          validator: (value) {
                            // Identificación es opcional para admin_institucion y super_admin
                            if (widget.userRole == 'admin_institucion' || widget.userRole == 'super_admin') {
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
                      key: const Key('cancelButton'),
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
                      key: const Key('formSaveButton'),
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
                          : Text(_user != null ? 'Actualizar' : 'Crear', style: textStyles.button),
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