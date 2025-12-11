import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';

class MultiStepFormScaffold extends StatefulWidget {
  final String title;
  final List<Step> steps;
  final Future<void> Function() onSave;
  final String nextLabel;
  final String previousLabel;
  final String submitLabel;
  final String cancelLabel;
  final GlobalKey<FormState>? formKey;

  const MultiStepFormScaffold({
    super.key,
    required this.title,
    required this.steps,
    required this.onSave,
    this.formKey,
    this.nextLabel = 'Siguiente',
    this.previousLabel = 'Anterior',
    this.submitLabel = 'Guardar',
    this.cancelLabel = 'Cancelar',
  });

  @override
  State<MultiStepFormScaffold> createState() => _MultiStepFormScaffoldState();
}

class _MultiStepFormScaffoldState extends State<MultiStepFormScaffold> {
  int _currentStep = 0;
  bool _isLoading = false;

  void _onStepContinue() async {
    final isLast = _currentStep == widget.steps.length - 1;
    if (!(_validateCurrentStep())) {
      return;
    }
    if (!isLast) {
      setState(() => _currentStep++);
    } else {
      setState(() => _isLoading = true);
      await widget.onSave();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateCurrentStep() {
    final currentForm = widget.formKey?.currentState;
    if (currentForm != null) return currentForm.validate();
    return true;
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        key: widget.formKey,
        child: Stepper(
          currentStep: _currentStep,
          steps: widget.steps,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          onStepTapped: (index) => setState(() => _currentStep = index),
          controlsBuilder: (context, details) {
            final isLast = details.currentStep == widget.steps.length - 1;
            return Padding(
              padding: EdgeInsets.only(top: spacing.lg),
              child: Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: Text(widget.previousLabel))),
                  SizedBox(width: spacing.md),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Text(isLast
                                  ? widget.submitLabel
                                  : widget.nextLabel))),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
