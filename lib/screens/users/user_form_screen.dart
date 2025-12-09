// ignore_for_file: prefer_const_constructors

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/institution_provider.dart';
import '../../theme/theme_extensions.dart';
import '../../services/user_form_service.dart';
import '../../services/user_service.dart';
import '../../services/form_validation_service.dart';
import '../../widgets/gestionar_acudientes_sheet.dart';
import 'form_steps/index.dart';

/// Resultado de la operación de guardado de usuario
class _SaveResult {
  final bool success;
  final String? tempPassword;

  _SaveResult({required this.success, this.tempPassword});
}

class UserFormScreen extends StatefulWidget {
  final String userRole; // 'profesor', 'estudiante', 'admin_institucion', etc.
  final String?
      initialInstitutionId; // Optional: preselect institution for admin creation

  const UserFormScreen({
    super.key,
    required this.userRole,
    this.initialInstitutionId,
  });

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  // Servicios
  final UserFormService _userFormService = UserFormService();
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
  final GlobalKey<FormFieldState<String>> _emailFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _institutionFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _nombresFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _apellidosFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _telefonoFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _identificacionFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _tituloFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _especialidadFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _nombreResponsableFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _telefonoResponsableFieldKey =
      GlobalKey<FormFieldState<String>>();
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
  List<String> _selectedInstitutionIds =
      []; // Instituciones seleccionadas para admin_institucion (edición puede tener varias)
  // Indica si el formulario está editando al usuario de la sesión
  bool _isSelfEditing = false;

  String? _emailError;

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
    // Ejecutar la carga de datos después del primer frame para evitar que
    // ChangeNotifier.notifyListeners() sea llamado durante la fase de build,
    // lo que provocaba la excepción: "setState() or markNeedsBuild() called during build.".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A veces un postFrameCallback aún puede coincidir con fases de build
      // en flujos complejos (navegación rápida). Encapsulamos en un
      // microtask para garantizar que la llamada ocurra completamente
      // fuera del ciclo de construcción y evitar notifyListeners durante build.
      Future.microtask(() {
        _loadUserIfEditing();
        _loadInstitutionsIfNeeded();
      });
    });
  }

  Future<void> _loadUserIfEditing() async {
    // Evitar cargar múltiples veces
    if (_user != null || _isInitialLoading) return;

    final uri = GoRouterState.of(context).uri;
    final queryParams = uri.queryParameters;

    // Captura el context antes del await
    final navigator = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    setState(() => _isInitialLoading = true);

    try {
      final user =
          await _userFormService.loadUserForEditing(context, queryParams);
      if (user != null && mounted) {
        // Detectar si estamos editando al usuario de la sesión
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final sessionUserId = authProvider.user?['id']?.toString();
        setState(() {
          _user = user;
          _isSelfEditing = sessionUserId != null && sessionUserId == user.id;
        });
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

  Future<void> _loadInstitutionsIfNeeded() async {
    await _userFormService.loadInstitutionsIfNeeded(context, widget.userRole);
    if (!mounted) return;
    // Preselect institution if provided
    if (widget.initialInstitutionId != null &&
        _selectedInstitutionIds.isEmpty) {
      final institutionProvider =
          Provider.of<InstitutionProvider>(context, listen: false);
      final exists = institutionProvider.institutions
          .any((i) => i.id == widget.initialInstitutionId);
      if (exists) _selectedInstitutionIds = [widget.initialInstitutionId!];
    }
  }

  void _fillFormWithUserData() {
    final user = _user!;
    _userFormService.fillFormWithUserData(
      user,
      _nombresController,
      _apellidosController,
      _emailController,
      _telefonoController,
      _identificacionController,
      _tituloController,
      _especialidadController,
      _nombreResponsableController,
      _telefonoResponsableController,
      (value) => setState(() => _activo = value),
      (ids) => setState(() => _selectedInstitutionIds = ids),
    );
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
    if (!_userFormService.validateAllSteps(_stepKeys)) {
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
      setState(() => _currentStep = _findFirstInvalidStep());
      _focusFirstInvalidField(_currentStep, context);
      return;
    }

    // Validación adicional para admin_institucion
    if (widget.userRole == 'admin_institucion' &&
        _selectedInstitutionIds.isEmpty) {
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
      final result = await _performSaveOperation(authProvider);

      if (result.success) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${_userFormService.getRoleDisplayName(widget.userRole)} ${_user != null ? 'actualizado' : 'creado'} exitosamente',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            backgroundColor: theme.colorScheme.primary,
          ),
        );

        // Mostrar contraseña temporal solo en creación
        if (_user == null && result.tempPassword != null) {
          await _showPasswordDialog(result.tempPassword!);
        }

        navigator.go('/users');
      }
    } catch (e) {
      if (!mounted) return;
      if (e is EmailAlreadyExistsException) {
        setState(() => _emailError = e.message);
        setState(() => _autoValidateMode = AutovalidateMode.always);
        setState(() => _currentStep = 0); // Ir al step 1
        _emailFocus.requestFocus();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Error al ${_user != null ? 'actualizar' : 'crear'} ${_userFormService.getRoleDisplayName(widget.userRole)}: ${e.toString()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onError,
              ),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<_SaveResult> _performSaveOperation(AuthProvider authProvider) async {
    if (_user != null) {
      // Modo edición
      final updateRequest = _userFormService.createUpdateRequest(
        email: _emailController.text,
        nombres: _nombresController.text,
        apellidos: _apellidosController.text,
        telefono: _telefonoController.text,
        identificacion: _identificacionController.text,
        userRole: widget.userRole,
        titulo: _tituloController.text,
        especialidad: _especialidadController.text,
        nombreResponsable: _nombreResponsableController.text,
        telefonoResponsable: _telefonoResponsableController.text,
        activo: _activo,
      );
      final success = await _userFormService.saveUser(
        context: context,
        user: _user,
        createRequest: null,
        updateRequest: updateRequest,
        userRole: widget.userRole,
      );

      // Si la actualización básica del usuario fue exitosa, sincronizar las
      // relaciones de instituciones si se trata de un admin_institucion.
      if (success && widget.userRole == 'admin_institucion') {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final token = authProvider.accessToken;
        if (token != null) {
          try {
            // IDs actuales en la entidad cargada
            final existingIds =
                _user?.instituciones?.map((i) => i.id).toSet() ?? <String>{};
            final selectedIds = _selectedInstitutionIds.toSet();

            // Asignar los que están en selectedIds pero no en existingIds
            final toAssign = selectedIds.difference(existingIds);
            for (final instId in toAssign) {
              await userProvider.assignAdminToInstitution(
                  token, instId, _user!.id);
            }

            // Remover los que estaban y ya no están seleccionados
            final toRemove = existingIds.difference(selectedIds);
            for (final instId in toRemove) {
              await userProvider.removeAdminFromInstitution(
                  token, instId, _user!.id);
            }
          } catch (e) {
            debugPrint('Error sincronizando instituciones del usuario: $e');
            // No hacer fallar la operación principal, ya que el usuario fue actualizado.
          }
        }
      }

      return _SaveResult(success: success);
    } else {
      // Modo creación - generar contraseña temporal una sola vez
      final tempPassword = _userFormService.generateRandomPassword();
      final createRequest = _userFormService.createUserRequestWithPassword(
        email: _emailController.text,
        password: tempPassword,
        nombres: _nombresController.text,
        apellidos: _apellidosController.text,
        telefono: _telefonoController.text,
        identificacion: _identificacionController.text,
        userRole: widget.userRole,
        titulo: _tituloController.text,
        especialidad: _especialidadController.text,
        nombreResponsable: _nombreResponsableController.text,
        telefonoResponsable: _telefonoResponsableController.text,
        selectedInstitutionId: _selectedInstitutionIds.isNotEmpty
            ? _selectedInstitutionIds.first
            : null,
        authProvider: authProvider,
      );

      final success = await _userFormService.saveUser(
        context: context,
        user: null,
        createRequest: createRequest,
        updateRequest: null,
        userRole: widget.userRole,
      );

      return _SaveResult(
          success: success, tempPassword: success ? tempPassword : null);
    }
  }

  Future<void> _showPasswordDialog(String tempPassword) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Contraseña temporal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Se ha creado el usuario. Esta es la contraseña temporal (se mostrará sólo ahora):'),
              const SizedBox(height: 12),
              SelectableText(tempPassword,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'Asegúrate de copiarla y entregarla al usuario. No se podrá volver a visualizar.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await Clipboard.setData(ClipboardData(text: tempPassword));
                if (!mounted) return;
                navigator.pop();
              },
              child: const Text('Copiar y Cerrar'),
            ),
          ],
        );
      },
    );
  }

  /// Abre el bottom sheet para gestionar acudientes del estudiante
  void _openGestionarAcudientes() {
    if (_user == null || _user!.estudiante?.id == null) return;

    GestionarAcudientesSheet.show(
      context,
      _user!.estudiante!.id,
      _user!.nombreCompleto,
    );
  }

  int _findFirstInvalidStep() {
    for (var i = 0; i < _stepKeys.length; i++) {
      final valid = _stepKeys[i].currentState?.validate() ?? true;
      if (!valid) {
        return i;
      }
    }
    return 0;
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
      case 'acudiente':
        return 'Acudiente';
      default:
        return 'Usuario';
    }
  }

  void _focusFirstInvalidField(int step, BuildContext context) {
    FormValidationService.focusFirstInvalidField(
      step,
      widget.userRole,
      {
        'email': _emailController,
        'nombres': _nombresController,
        'apellidos': _apellidosController,
        'telefono': _telefonoController,
        'identificacion': _identificacionController,
        'titulo': _tituloController,
        'especialidad': _especialidadController,
        'telefonoResponsable': _telefonoResponsableController,
      },
      {
        'email': _emailFocus,
        'nombres': _nombresFocus,
        'apellidos': _apellidosFocus,
        'telefono': _telefonoFocus,
        'identificacion': _identificacionFocus,
        'titulo': _tituloFocus,
        'especialidad': _especialidadFocus,
        'telefonoResponsable': _telefonoResponsableFocus,
      },
      {
        'email': _emailFieldKey,
        'nombres': _nombresFieldKey,
        'apellidos': _apellidosFieldKey,
        'telefono': _telefonoFieldKey,
        'identificacion': _identificacionFieldKey,
        'titulo': _tituloFieldKey,
        'especialidad': _especialidadFieldKey,
        'telefonoResponsable': _telefonoResponsableFieldKey,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;
    final title = _user != null
        ? 'Editar Usuario'
        : 'Crear ${_getRoleDisplayName(widget.userRole)}';

    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: colors.primary,
          foregroundColor: colors.white,
        ),
        body: Center(
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                            borderRadius:
                                BorderRadius.circular(spacing.borderRadius),
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
                          borderRadius:
                              BorderRadius.circular(spacing.borderRadius),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(colors.white),
                              ),
                            )
                          : Text(
                              isLastStep
                                  ? (_user != null ? 'Actualizar' : 'Crear')
                                  : 'Siguiente',
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
                            borderRadius:
                                BorderRadius.circular(spacing.borderRadius),
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
          child: Builder(
            builder: (ctx) {
              final sessionRole = Provider.of<AuthProvider>(ctx, listen: false)
                  .user?['rol'] as String?;
              // Permitir editar instituciones sólo si: (a) el role del formulario no es
              // 'admin_institucion' y no es un admin autoeditando su perfil, o (b)
              // si se trata de admin_institucion, sólo permitir a super_admin hacerlo.
              bool canEditInstitutions;
              if (widget.userRole == 'admin_institucion') {
                canEditInstitutions = sessionRole == 'super_admin';
              } else {
                canEditInstitutions =
                    !(_isSelfEditing && sessionRole == 'admin_institucion');
              }
              // Debug: imprimir el estado de permisos para ayudar a diagnosticar
              debugPrint(
                  'UserFormScreen: sessionRole=$sessionRole, userRole=${widget.userRole}, isSelfEditing=$_isSelfEditing, canEditInstitutions=$canEditInstitutions');

              return UserAccountStep(
                emailController: _emailController,
                userRole: widget.userRole,
                // Para edición permitimos seleccionar múltiples instituciones
                selectedInstitutionIds: _selectedInstitutionIds,
                selectedInstitutionNames:
                    _user != null && (_user!.instituciones?.isNotEmpty ?? false)
                        ? _user!.instituciones!.map((i) => i.nombre).toList()
                        : const [],
                onInstitutionChanged: (ids) =>
                    setState(() => _selectedInstitutionIds = ids),
                // Control de bloqueo: el campo queda deshabilitado si no se permite editar instituciones
                disableInstitution: !canEditInstitutions,
                emailFocusNode: _emailFocus,
                institutionFocusNode: _institutionFocus,
                isEditMode: _user != null,
                emailFieldKey: _emailFieldKey,
                institutionFieldKey: _institutionFieldKey,
                errorEmail: _emailError,
              );
            },
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
            // El switch de 'activo' debe ser de solo lectura si el usuario de sesión es
            // admin_institucion y está editando su propia cuenta.
            // Evaluamos el rol directamente desde AuthProvider en tiempo de build.
            activoEditable: !(_isSelfEditing &&
                (Provider.of<AuthProvider>(context, listen: false)
                        .user?['rol'] ==
                    'admin_institucion')),
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
        state: _currentStep > 1
            ? StepState.complete
            : (_currentStep == 1 ? StepState.indexed : StepState.disabled),
      ),
    ];

    // Step 3: Detalles específicos por rol (solo para profesor y estudiante)
    if (widget.userRole == 'profesor' || widget.userRole == 'estudiante') {
      steps.add(
        Step(
          title: const Text('Detalles'),
          subtitle: Text(
              widget.userRole == 'profesor' ? 'Info académica' : 'Responsable'),
          content: Form(
            key: _stepKeys[2],
            child: RoleSpecificDetailsStep(
              userRole: widget.userRole,
              tituloController: (widget.userRole == 'profesor' ||
                      widget.userRole == 'admin_institucion')
                  ? _tituloController
                  : null,
              especialidadController: widget.userRole == 'profesor'
                  ? _especialidadController
                  : null,
              nombreResponsableController: widget.userRole == 'estudiante'
                  ? _nombreResponsableController
                  : null,
              telefonoResponsableController: widget.userRole == 'estudiante'
                  ? _telefonoResponsableController
                  : null,
              tituloFocusNode: _tituloFocus,
              especialidadFocusNode: _especialidadFocus,
              nombreResponsableFocusNode: _nombreResponsableFocus,
              telefonoResponsableFocusNode: _telefonoResponsableFocus,
              tituloFieldKey: _tituloFieldKey,
              especialidadFieldKey: _especialidadFieldKey,
              nombreResponsableFieldKey: _nombreResponsableFieldKey,
              telefonoResponsableFieldKey: _telefonoResponsableFieldKey,
              // Para gestión de acudientes (solo disponible en edición de estudiante)
              estudianteId: (widget.userRole == 'estudiante' && _user != null)
                  ? _user!.estudiante?.id
                  : null,
              onGestionarAcudientes: (widget.userRole == 'estudiante' &&
                      _user != null &&
                      _user!.estudiante?.id != null)
                  ? () => _openGestionarAcudientes()
                  : null,
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
    debugPrint('🔔 _onStepContinue CALLED! currentStep=$_currentStep');
    final totalSteps = _getTotalSteps();
    debugPrint('🔔 totalSteps=$totalSteps');

    // Validar solo el step actual antes de continuar
    final stepState = _stepKeys[_currentStep].currentState;
    debugPrint('🔔 stepState for step $_currentStep: $stepState');
    final currentStepValid = stepState?.validate() ?? true;
    debugPrint('🔔 validation result: $currentStepValid');
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
}
