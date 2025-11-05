import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/institution_provider.dart';
import '../../theme/theme_extensions.dart';
import 'form_steps/index.dart';

class UserFormScreen extends StatefulWidget {
  final String userRole; // 'profesor', 'estudiante', 'admin_institucion', etc.

  const UserFormScreen({
    super.key, 
    required this.userRole,
  });

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  // Focus nodes for form fields to allow focusing first invalid field
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _institutionFocus = FocusNode();

  final FocusNode _nombresFocus = FocusNode();
  final FocusNode _apellidosFocus = FocusNode();
  final FocusNode _telefonoFocus = FocusNode();
  final FocusNode _identificacionFocus = FocusNode();

  final FocusNode _tituloFocus = FocusNode();
  final FocusNode _especialidadFocus = FocusNode();
  final FocusNode _nombreResponsableFocus = FocusNode();
  final FocusNode _telefonoResponsableFocus = FocusNode();
  // GlobalKeys for form fields to allow Scrollable.ensureVisible
  final GlobalKey<FormFieldState<String>> _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _institutionFieldKey = GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _nombresFieldKey = GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _apellidosFieldKey = GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _telefonoFieldKey = GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _identificacionFieldKey = GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _tituloFieldKey = GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _especialidadFieldKey = GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _nombreResponsableFieldKey = GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _telefonoResponsableFieldKey = GlobalKey<FormFieldState<String>>();
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
    // Crear claves por step para validar individualmente
    final total = _getTotalSteps();
    _stepKeys = List.generate(total, (_) => GlobalKey<FormState>());
  }

  late List<GlobalKey<FormState>> _stepKeys;


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
      // Captura el context antes del await
      final navigator = GoRouter.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);

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
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar usuario: ${e.toString()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onError,
              ),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        // Volver a la lista si no se puede cargar el usuario
        navigator.go('/users');
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
    // dispose focus nodes
    _emailFocus.dispose();
    _institutionFocus.dispose();
    _nombresFocus.dispose();
    _apellidosFocus.dispose();
    _telefonoFocus.dispose();
    _identificacionFocus.dispose();
    _tituloFocus.dispose();
    _especialidadFocus.dispose();
    _nombreResponsableFocus.dispose();
    _telefonoResponsableFocus.dispose();

    // dispose controllers
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
    final navigator = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    // Antes de guardar, validar todos los steps
    for (var i = 0; i < _stepKeys.length; i++) {
      final valid = _stepKeys[i].currentState?.validate() ?? true;
      if (!valid) {
        setState(() => _autoValidateMode = AutovalidateMode.always);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Corrige los campos marcados antes de guardar',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
        // mover al step con error y enfocar
        setState(() => _currentStep = i);
        _focusFirstInvalidField(i, context);
        return;
      }
    }

    // Validación adicional para admin_institucion
    if (widget.userRole == 'admin_institucion' && _selectedInstitutionId == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Debe seleccionar una institución',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onError,
            ),
          ),
          backgroundColor: theme.colorScheme.error,
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

        if (success) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '${_getRoleDisplayName(widget.userRole)} actualizado exitosamente',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
          navigator.go('/users');
        }
      } else {
        // Modo creación
        final String tempPassword = _generateRandomPassword();

        final createRequest = CreateUserRequest(
          email: _emailController.text.trim(),
          password: tempPassword,
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

        if (success) {
          // Mostrar Snackbar de éxito
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '${_getRoleDisplayName(widget.userRole)} creado exitosamente',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              backgroundColor: theme.colorScheme.primary,
            ),
          );

          // Mostrar diálogo con la contraseña generada (se mostrará solo una vez)
          await showDialog<void>(
            // ignore: use_build_context_synchronously
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: Text('Contraseña temporal'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Se ha creado el usuario. Esta es la contraseña temporal (se mostrará sólo ahora):'),
                    SizedBox(height: 12),
                    SelectableText(tempPassword, style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 12),
                    Text(
                      'Asegúrate de copiarla y entregarla al usuario. No se podrá volver a visualizar.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      // Capturar NavigatorState antes del await para evitar usar BuildContext después de un async gap
                      final navigator = Navigator.of(context);
                      await Clipboard.setData(ClipboardData(text: tempPassword));
                      // Intentar cerrar el diálogo usando la instancia capturada
                      try {
                        navigator.pop();
                      } catch (_) {
                        // Si ya no es posible cerrar, ignora
                      }
                    },
                    child: const Text('Copiar y Cerrar'),
                  ),
                ],
              );
            },
          );

          // Finalmente navegar a la lista de usuarios
          if (!mounted) return;
          navigator.go('/users');
        }
      }
    } catch (e) {
      // Evitar usar context a través de un async gap: comprobar mounted y luego usar ScaffoldMessenger
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error al ${_user != null ? 'actualizar' : 'crear'} ${_getRoleDisplayName(widget.userRole)}: ${e.toString()}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onError,
            ),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
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

  void _focusFirstInvalidField(int step, BuildContext context) {
    // Prioridad: enfocar el campo más probable que esté inválido en el paso
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]+$');

    if (step == 0) {
      // Step Cuenta
      final email = _emailController.text.trim();
      if (email.isEmpty || !emailRegex.hasMatch(email)) {
        FocusScope.of(context).requestFocus(_emailFocus);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _emailFieldKey.currentContext;
          if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
        });
        return;
      }

      if (widget.userRole == 'admin_institucion' && _selectedInstitutionId == null) {
        FocusScope.of(context).requestFocus(_institutionFocus);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _institutionFieldKey.currentContext;
          if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
        });
        return;
      }
    } else if (step == 1) {
      // Step Info Personal
      final nombres = _nombresController.text.trim();
      final apellidos = _apellidosController.text.trim();
      final telefono = _telefonoController.text.trim();
      final identificacion = _identificacionController.text.trim();

      if (nombres.isEmpty || nombres.length < 2) {
        FocusScope.of(context).requestFocus(_nombresFocus);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _nombresFieldKey.currentContext;
          if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
        });
        return;
      }
      if (apellidos.isEmpty || apellidos.length < 2) {
        FocusScope.of(context).requestFocus(_apellidosFocus);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _apellidosFieldKey.currentContext;
          if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
        });
        return;
      }
      if (telefono.isNotEmpty && !phoneRegex.hasMatch(telefono)) {
        FocusScope.of(context).requestFocus(_telefonoFocus);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _telefonoFieldKey.currentContext;
          if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
        });
        return;
      }
      if (!(widget.userRole == 'admin_institucion' || widget.userRole == 'super_admin')) {
        if (identificacion.isEmpty || identificacion.length < 5) {
          FocusScope.of(context).requestFocus(_identificacionFocus);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _identificacionFieldKey.currentContext;
            if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
          });
          return;
        }
      }
    } else if (step == 2) {
      // Step detalles por rol
      if (widget.userRole == 'profesor') {
        final titulo = _tituloController.text.trim();
        final especialidad = _especialidadController.text.trim();
        if (titulo.isEmpty || titulo.length < 3) {
          FocusScope.of(context).requestFocus(_tituloFocus);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _tituloFieldKey.currentContext;
            if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
          });
          return;
        }
        if (especialidad.isEmpty || especialidad.length < 3) {
          FocusScope.of(context).requestFocus(_especialidadFocus);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _especialidadFieldKey.currentContext;
            if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
          });
          return;
        }
      } else if (widget.userRole == 'estudiante') {
        final telefonoResp = _telefonoResponsableController.text.trim();
        if (telefonoResp.isNotEmpty && !phoneRegex.hasMatch(telefonoResp)) {
          FocusScope.of(context).requestFocus(_telefonoResponsableFocus);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _telefonoResponsableFieldKey.currentContext;
            if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
          });
          return;
        }
      }
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
          backgroundColor: colors.primary,
          foregroundColor: colors.white,
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

    // Determinar cuántos pasos necesitamos
    final int totalSteps = _getTotalSteps();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: colors.primary,
        foregroundColor: colors.white,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autoValidateMode,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            final isLastStep = details.currentStep == totalSteps - 1;
            
            return Padding(
              padding: EdgeInsets.only(top: spacing.lg),
              child: Row(
                children: [
                  if (details.currentStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: spacing.md),
                          side: BorderSide(color: colors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(spacing.borderRadius),
                          ),
                        ),
                        child: Text(
                          'Anterior',
                          style: textStyles.button.withColor(colors.primary),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.md),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('formSaveButton'),
                      onPressed: _isLoading ? null : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: spacing.md),
                        backgroundColor: colors.primary,
                        foregroundColor: colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(spacing.borderRadius),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isLastStep ? (_user != null ? 'Actualizar' : 'Crear') : 'Siguiente',
                              style: textStyles.button.withColor(colors.white),
                            ),
                    ),
                  ),
                  if (details.currentStep == 0) ...[
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: spacing.md),
                          side: BorderSide(color: colors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(spacing.borderRadius),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: textStyles.button.withColor(colors.error),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: _buildSteps(),
        ),
      ),
    );
  }

  int _getTotalSteps() {
    // Step 1: Cuenta, Step 2: Info Personal, Step 3: Detalles específicos (si aplica)
    if (widget.userRole == 'profesor' || widget.userRole == 'estudiante') {
      return 3;
    }
    return 2; // Solo cuenta e info personal para admin
  }

  List<Step> _buildSteps() {
  final steps = <Step>[
      // Step 1: Información de Cuenta
      Step(
        title: const Text('Cuenta'),
        subtitle: const Text('Email y acceso'),
        content: Form(
          key: _stepKeys[0],
          child: UserAccountStep(
            emailController: _emailController,
            userRole: widget.userRole,
            selectedInstitutionId: _selectedInstitutionId,
            onInstitutionChanged: (value) => setState(() => _selectedInstitutionId = value),
            emailFocusNode: _emailFocus,
            institutionFocusNode: _institutionFocus,
            isEditMode: _user != null,
            emailFieldKey: _emailFieldKey,
            institutionFieldKey: _institutionFieldKey,
          ),
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),

      // Step 2: Información Personal
      Step(
        title: const Text('Info Personal'),
        subtitle: const Text('Datos básicos'),
        content: Form(
          key: _stepKeys[1],
          child: UserPersonalInfoStep(
            nombresController: _nombresController,
            apellidosController: _apellidosController,
            telefonoController: _telefonoController,
            identificacionController: _identificacionController,
            userRole: widget.userRole,
            activo: _activo,
            onActivoChanged: (value) => setState(() => _activo = value),
            nombresFocusNode: _nombresFocus,
            apellidosFocusNode: _apellidosFocus,
            telefonoFocusNode: _telefonoFocus,
            identificacionFocusNode: _identificacionFocus,
             nombresFieldKey: _nombresFieldKey,
             apellidosFieldKey: _apellidosFieldKey,
             telefonoFieldKey: _telefonoFieldKey,
             identificacionFieldKey: _identificacionFieldKey,
          ),
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : (_currentStep == 1 ? StepState.indexed : StepState.disabled),
      ),
    ];

    // Step 3: Detalles específicos por rol (solo para profesor y estudiante)
    if (widget.userRole == 'profesor' || widget.userRole == 'estudiante') {
      steps.add(
        Step(
          title: const Text('Detalles'),
          subtitle: Text(widget.userRole == 'profesor' ? 'Info académica' : 'Responsable'),
          content: Form(
            key: _stepKeys[2],
            child: RoleSpecificDetailsStep(
              userRole: widget.userRole,
              tituloController: widget.userRole == 'profesor' ? _tituloController : null,
              especialidadController: widget.userRole == 'profesor' ? _especialidadController : null,
              nombreResponsableController: widget.userRole == 'estudiante' ? _nombreResponsableController : null,
              telefonoResponsableController: widget.userRole == 'estudiante' ? _telefonoResponsableController : null,
              tituloFocusNode: _tituloFocus,
              especialidadFocusNode: _especialidadFocus,
              nombreResponsableFocusNode: _nombreResponsableFocus,
              telefonoResponsableFocusNode: _telefonoResponsableFocus,
              tituloFieldKey: _tituloFieldKey,
              especialidadFieldKey: _especialidadFieldKey,
              nombreResponsableFieldKey: _nombreResponsableFieldKey,
              telefonoResponsableFieldKey: _telefonoResponsableFieldKey,
            ),
          ),
          isActive: _currentStep >= 2,
          state: _currentStep == 2 ? StepState.indexed : StepState.disabled,
        ),
      );
    }

    return steps;
  }


  void _onStepContinue() {
    final totalSteps = _getTotalSteps();
    
    // Validar solo el step actual antes de continuar
    final currentStepValid = _stepKeys[_currentStep].currentState?.validate() ?? true;
    if (!currentStepValid) {
      // Activar autovalidación para mostrar los errores inmediatamente
      setState(() => _autoValidateMode = AutovalidateMode.always);

      final messenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Corrige los campos marcados antes de continuar',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
          backgroundColor: theme.colorScheme.primary,
        ),
      );

  // Enfocar el primer campo inválido del step actual
  _focusFirstInvalidField(_currentStep, context);

      return;
    }

    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Último step: guardar
      _saveUser();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  String _generateRandomPassword({int length = 12}) {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*()';
    final Random random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}