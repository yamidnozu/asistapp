import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/institution.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
// theme extensions not required after switching to MultiStepFormScaffold
import '../../widgets/common/multi_step_form_scaffold.dart';
import 'form_steps/index.dart';

class InstitutionFormScreen extends StatefulWidget {
  final Institution? institution;

  const InstitutionFormScreen({super.key, this.institution});

  @override
  State<InstitutionFormScreen> createState() => _InstitutionFormScreenState();
}

class _InstitutionFormScreenState extends State<InstitutionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  // MultiStepFormScaffold manages the current step internally now.
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();

  bool _activa = true;
  // Loading is managed by the MultiStepFormScaffold; avoid duplicating state

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

  // MultiStepFormScaffold handles loading UI

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

      final token = authProvider.accessToken;
      if (token == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para crear una institución')));
        return;
      }

      bool success;
      if (widget.institution == null) {
        // Crear nueva institución
        success = await institutionProvider.createInstitution(
          token,
          institutionData,
        );
      } else {
        // Actualizar institución existente
        success = await institutionProvider.updateInstitution(
          token,
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
      // Nothing to do - scaffold will hide the spinner when onSave future resolves
    }
  }

  @override
  Widget build(BuildContext context) {
  // spacing intentionally unused; MultiStepFormScaffold handles button spacing
    final title = isEditing ? 'Editar Institución' : 'Nueva Institución';

    return MultiStepFormScaffold(
      title: title,
      formKey: _formKey,
      onSave: _saveInstitution,
      submitLabel: isEditing ? 'Actualizar' : 'Crear',
      steps: [
        // Step 1: Información Básica
        Step(
          title: const Text('Información'),
          subtitle: const Text('Datos básicos'),
          content: InstitutionBasicInfoStep(
            nombreController: _nombreController,
            emailController: _emailController,
          ),
        ),

            // Step 2: Contacto y Ubicación
            Step(
              title: const Text('Contacto'),
              subtitle: const Text('Ubicación y teléfono'),
              content: InstitutionContactStep(
                direccionController: _direccionController,
                telefonoController: _telefonoController,
              ),
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
            ),
        ],
    );
  }

  // Control de pasos ahora centralizado por MultiStepFormScaffold
}