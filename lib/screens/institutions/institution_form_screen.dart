import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/institution.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import '../../theme/theme_extensions.dart';
import 'form_steps/index.dart';

class InstitutionFormScreen extends StatefulWidget {
  final Institution? institution;

  const InstitutionFormScreen({super.key, this.institution});

  @override
  State<InstitutionFormScreen> createState() => _InstitutionFormScreenState();
}

class _InstitutionFormScreenState extends State<InstitutionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();

  bool _activa = true;
  bool _isLoading = false;

  bool get isEditing => widget.institution != null;

  @override
  void initState() {
    super.initState();
    if (widget.institution != null) {
      _loadInstitutionData();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadInstitutionData() {
    final institution = widget.institution!;
    _nombreController.text = institution.nombre;
    _direccionController.text = institution.direccion ?? '';
    _telefonoController.text = institution.telefono ?? '';
    _emailController.text = institution.email ?? '';
    _activa = institution.activa;
  }

  Future<void> _saveInstitution() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);

      final institutionData = {
        'nombre': _nombreController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'email': _emailController.text.trim(),
        'activa': _activa,
      };

      bool success;
      if (widget.institution == null) {
        // Crear nueva institución
        success = await institutionProvider.createInstitution(
          authProvider.accessToken!,
          institutionData,
        );
      } else {
        // Actualizar institución existente
        success = await institutionProvider.updateInstitution(
          authProvider.accessToken!,
          widget.institution!.id,
          nombre: institutionData['nombre'] as String?,
          direccion: institutionData['direccion'] as String?,
          telefono: institutionData['telefono'] as String?,
          email: institutionData['email'] as String?,
          activa: institutionData['activa'] as bool?,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.institution == null
                  ? 'Institución creada correctamente'
                  : 'Institución actualizada correctamente',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onError),
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
    final spacing = context.spacing;
    final colors = context.colors;
    final textStyles = context.textStyles;
    final title = isEditing ? 'Editar Institución' : 'Nueva Institución';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: colors.primary,
        foregroundColor: colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            final isLastStep = details.currentStep == 2; // 3 steps total (0, 1, 2)
            
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
                              isLastStep ? (isEditing ? 'Actualizar' : 'Crear') : 'Siguiente',
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
          steps: [
            // Step 1: Información Básica
            Step(
              title: const Text('Información'),
              subtitle: const Text('Datos básicos'),
              content: InstitutionBasicInfoStep(
                nombreController: _nombreController,
                emailController: _emailController,
              ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),

            // Step 2: Contacto y Ubicación
            Step(
              title: const Text('Contacto'),
              subtitle: const Text('Ubicación y teléfono'),
              content: InstitutionContactStep(
                direccionController: _direccionController,
                telefonoController: _telefonoController,
              ),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : (_currentStep == 1 ? StepState.indexed : StepState.disabled),
            ),

            // Step 3: Configuración
            Step(
              title: const Text('Configuración'),
              subtitle: const Text('Estado'),
              content: InstitutionConfigStep(
                activa: _activa,
                onActivaChanged: (value) => setState(() => _activa = value),
                isEditMode: isEditing,
              ),
              isActive: _currentStep >= 2,
              state: _currentStep == 2 ? StepState.indexed : StepState.disabled,
            ),
          ],
        ),
      ),
    );
  }

  void _onStepContinue() {
    // Validar el step actual antes de continuar
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Último step: guardar
      _saveInstitution();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
}