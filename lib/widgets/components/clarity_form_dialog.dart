import 'package:flutter/material.dart';
// No theme extensions used directly here; leave default theme in AlertDialog

/// ClarityFormDialog
/// Un wrapper reutilizable alrededor de un [AlertDialog] con un [Form].
///
/// Parámetros principales:
/// - title: Título del diálogo (String o Widget)
/// - formKey: Opcional. Si no se provee, se crea uno interno.
/// - children: Lista de campos/widgets dentro del formulario
/// - onSave: función asíncrona que devuelve true si la operación fue exitosa
/// - saveLabel / cancelLabel: etiquetas para los botones
class ClarityFormDialog extends StatefulWidget {
  final Widget title;
  final GlobalKey<FormState>? formKey;
  final List<Widget> children;
  final Future<bool> Function()? onSave;
  final String saveLabel;
  final String cancelLabel;

  const ClarityFormDialog({
    super.key,
    required this.title,
    this.formKey,
    this.onSave,
    this.saveLabel = 'Guardar',
    this.cancelLabel = 'Cancelar',
    required this.children,
  });

  @override
  State<ClarityFormDialog> createState() => _ClarityFormDialogState();
}

class _ClarityFormDialogState extends State<ClarityFormDialog> {
  late final GlobalKey<FormState> _formKey;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? GlobalKey<FormState>();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.onSave == null) return;

    setState(() => _isSaving = true);
    try {
      final success = await widget.onSave!();
      if (success && mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // theme helpers are available via context but not needed here

    return AlertDialog(
      title: widget.title,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.children,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.saveLabel),
        ),
      ],
    );
  }
}
