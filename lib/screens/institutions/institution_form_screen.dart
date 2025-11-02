import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/institution.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import '../../theme/theme_extensions.dart';

class InstitutionFormScreen extends StatefulWidget {
  final Institution? institution;

  const InstitutionFormScreen({super.key, this.institution});

  @override
  State<InstitutionFormScreen> createState() => _InstitutionFormScreenState();
}

class _InstitutionFormScreenState extends State<InstitutionFormScreen> {
  final _formKey = GlobalKey<FormState>();
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
    final textStyles = context.textStyles;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Editar Institución' : 'Nueva Institución',
                    style: textStyles.headlineMedium.bold,
                  ),
                  SizedBox(height: spacing.lg),
                  _buildFormCard(),
                  SizedBox(height: spacing.xl),
                  _buildActionButtons(),
                ],
              ),
            ),
          );
  }

  Widget _buildFormCard() {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la Institución',
              style: textStyles.headlineMedium.withColor(colors.primary),
            ),
            SizedBox(height: spacing.lg),
            _buildTextField(
              key: const Key('nombreInstitucionField'),
              controller: _nombreController,
              label: 'Nombre de la Institución',
              hint: 'Ingrese el nombre completo',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                if (value.trim().length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
              prefixIcon: Icons.business,
            ),
            SizedBox(height: spacing.lg),
            _buildTextField(
              controller: _direccionController,
              label: 'Dirección',
              hint: 'Dirección completa de la institución',
              maxLines: 3,
              prefixIcon: Icons.location_on,
            ),
            SizedBox(height: spacing.lg),
            _buildTextField(
              controller: _telefonoController,
              label: 'Teléfono',
              hint: '+56912345678',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone,
            ),
            SizedBox(height: spacing.lg),
            _buildTextField(
              key: const Key('emailInstitucionField'),
              controller: _emailController,
              label: 'Email',
              hint: 'contacto@institucion.cl',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Ingrese un email válido';
                  }
                }
                return null;
              },
              prefixIcon: Icons.email,
            ),
            SizedBox(height: spacing.lg),
            SwitchListTile(
              title: Text('Institución Activa', style: textStyles.titleMedium),
              subtitle: Text('Determina si la institución está operativa', style: textStyles.bodySmall),
              value: _activa,
              onChanged: (value) => setState(() => _activa = value),
              activeColor: colors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    Key? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;
    return TextFormField(
      key: key,
      controller: controller,
      style: textStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: textStyles.bodyMedium.withColor(colors.textSecondary),
        hintStyle: textStyles.bodyMedium.withColor(colors.textMuted),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: colors.textSecondary) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.borderRadius),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.borderRadius),
          borderSide: BorderSide(color: colors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.borderRadius),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.borderRadius),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.borderRadius),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        filled: true,
        fillColor: colors.surface,
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildActionButtons() {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('cancelButton'),
            onPressed: _isLoading ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: spacing.lg),
              side: BorderSide(color: colors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(spacing.borderRadius),
              ),
            ),
            child: Text('Cancelar', style: textStyles.labelLarge.withColor(colors.primary)),
          ),
        ),
        SizedBox(width: spacing.lg),
        Expanded(
          child: ElevatedButton(
            key: const Key('formSaveButton'),
            onPressed: _isLoading ? null : _saveInstitution,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: spacing.lg),
              backgroundColor: colors.primary,
              
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(spacing.borderRadius),
              ),
            ),
            child: Text(isEditing ? 'Actualizar' : 'Crear', style: textStyles.button),
          ),
        ),
      ],
    );
  }
}