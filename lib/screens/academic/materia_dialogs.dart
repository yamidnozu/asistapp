import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/materia.dart';
import '../../providers/auth_provider.dart';
import '../../providers/materia_provider.dart';
import '../../services/academic/materia_service.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/components/index.dart';

// Diálogo para crear materia
class CreateMateriaDialog extends StatefulWidget {
  const CreateMateriaDialog({super.key});

  @override
  State<CreateMateriaDialog> createState() => _CreateMateriaDialogState();
}

class _CreateMateriaDialogState extends State<CreateMateriaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();

  // ClarityFormDialog provides internal loading UI

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<bool> _createMateria() async {
    if (!_formKey.currentState!.validate()) return false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).colorScheme;

    try {
      final token = authProvider.accessToken;
      if (token == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para crear una materia')));
        return false;
      }

      final success = await materiaProvider.createMateria(
        token,
        CreateMateriaRequest(
          nombre: _nombreController.text.trim(),
          codigo: _codigoController.text.trim().isEmpty ? null : _codigoController.text.trim(),
        ),
      );

      if (success && mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Materia creada correctamente')));
        return true;
      } else if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(materiaProvider.errorMessage ?? 'Error al crear materia'), backgroundColor: colors.error));
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: colors.error));
    }
    return false;
  }

  // createMateria removed here, it belongs to the Create dialog state

  // _createMateria moved to the Create dialog class

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return ClarityFormDialog(
      title: Text('Crear Materia', style: textStyles.headlineMedium),
      formKey: _formKey,
      onSave: _createMateria,
      saveLabel: 'Crear',
      cancelLabel: 'Cancelar',
      children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Materia',
                hintText: 'Ej: Matemáticas, Lenguaje, Ciencias',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _codigoController,
              decoration: const InputDecoration(
                labelText: 'Código (opcional)',
                hintText: 'Ej: MAT101, LEN201',
              ),
            ),
      ],
    );
  }
}

// Diálogo para editar materia
class EditMateriaDialog extends StatefulWidget {
  final Materia materia;

  const EditMateriaDialog({super.key, required this.materia});

  @override
  State<EditMateriaDialog> createState() => _EditMateriaDialogState();
}

class _EditMateriaDialogState extends State<EditMateriaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _codigoController;

  // ClarityFormDialog provides internal loading UI

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.materia.nombre);
    _codigoController = TextEditingController(text: widget.materia.codigo ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return ClarityFormDialog(
      title: Text('Editar Materia', style: textStyles.headlineMedium),
      formKey: _formKey,
      onSave: _updateMateria,
      saveLabel: 'Actualizar',
      cancelLabel: 'Cancelar',
  children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Materia',
                hintText: 'Ej: Matemáticas, Lenguaje, Ciencias',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _codigoController,
              decoration: const InputDecoration(
                labelText: 'Código (opcional)',
                hintText: 'Ej: MAT101, LEN201',
              ),
            ),
      ],
    );
  }

  // createMateria belongs to CreateMateriaDialog

  Future<bool> _updateMateria() async {
    if (!_formKey.currentState!.validate()) return false;
    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).colorScheme;


    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);

      final token = authProvider.accessToken;
      if (token == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para editar una materia')));
        return false;
      }

      final success = await materiaProvider.updateMateria(
        token,
        widget.materia.id,
        UpdateMateriaRequest(
          nombre: _nombreController.text.trim(),
          codigo: _codigoController.text.trim().isEmpty ? null : _codigoController.text.trim(),
        ),
      );

      if (success && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Materia actualizada correctamente')),
        );
        return true;
      } else if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(materiaProvider.errorMessage ?? 'Error al actualizar materia'),
            backgroundColor: colors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    } finally {}
    return false;
  }
}
