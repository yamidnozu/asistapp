import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/test_flow_manager.dart';

class TestRunnerScreen extends StatefulWidget {
  const TestRunnerScreen({super.key});

  @override
  State<TestRunnerScreen> createState() => _TestRunnerScreenState();
}

class _TestRunnerScreenState extends State<TestRunnerScreen> {
  bool _isRunning = false;
  String _currentStep = '';
  final List<String> _logs = [];
  final ScrollController _logController = ScrollController();

  static const List<_TestStep> _stepDefinitions = [
    _TestStep('1. Login Super Admin', TestFlowManager.step1LoginSuperAdmin),
    _TestStep('2. Crear Institución', TestFlowManager.step2CrearInstitucion),
    _TestStep('3. Crear Admin Institución',
        TestFlowManager.step3CrearAdminInstitucion),
    _TestStep('4. Crear Profesores', TestFlowManager.step4CrearProfesores),
    _TestStep('5. Crear Estudiantes', TestFlowManager.step5CrearEstudiantes),
    _TestStep('6. Crear Materias', TestFlowManager.step6CrearMaterias),
    _TestStep('7. Crear Grupos', TestFlowManager.step7CrearGrupos),
    _TestStep('8. Crear Horarios', TestFlowManager.step8CrearHorarios),
    _TestStep(
        '9. Verificar Asistencias', TestFlowManager.step9VerificarAsistencias),
    _TestStep(
        '10. Verificar Dashboards', TestFlowManager.step10VerificarDashboards),
  ];

  void _addLog(String message) {
    setState(() => _logs.add('[${DateTime.now().toIso8601String()}] $message'));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logController.hasClients) {
        _logController.animateTo(
          _logController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _executeFlow(
      Future<void> Function(BuildContext) flow, String label) async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _currentStep = label;
    });

    _addLog('Iniciando: $label');

    try {
      await flow(context);
      _addLog('✅ $label completado');
    } catch (error, stack) {
      debugPrintStack(label: label, stackTrace: stack);
      _addLog('❌ $label falló: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _currentStep = '';
        });
      }
    }
  }

  Future<void> _runFullFlow() =>
      _executeFlow(TestFlowManager.ejecutarFlujoCompleto, 'Flujo completo');

  Future<void> _runUITests() =>
      _executeFlow(TestFlowManager.ejecutarPruebasUI, 'Pruebas de UI');

  Future<void> _runStep(_TestStep step) =>
      _executeFlow(step.handler, step.title);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.instance;
    final textStyles = AppTextStyles.instance;
    final spacing = AppSpacing.instance;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.white,
        elevation: 0,
        title: const Text('Flujo de Pruebas'),
      ),
      body: Padding(
        padding: EdgeInsets.all(spacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Herramientas de Testing',
              style: textStyles.displayMedium,
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Ejecuta flujos completos de pruebas para validar todas las funcionalidades clave.',
              style: textStyles.bodyLarge,
            ),
            SizedBox(height: spacing.xl),
            if (_currentStep.isNotEmpty)
              Container(
                padding: EdgeInsets.all(spacing.md),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(spacing.borderRadius),
                  border:
                      Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: Text(
                        _currentStep,
                        style: textStyles.bodyMedium
                            .copyWith(color: colors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            if (_currentStep.isNotEmpty) SizedBox(height: spacing.lg),
            Text(
              'Flujos de prueba',
              style: textStyles.headlineSmall,
            ),
            SizedBox(height: spacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runFullFlow,
                icon: Icon(_isRunning ? Icons.hourglass_top : Icons.play_arrow),
                label: Text(
                    _isRunning ? 'Ejecutando...' : 'Ejecutar flujo completo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.white,
                  padding: EdgeInsets.symmetric(vertical: spacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isRunning ? null : _runUITests,
                icon: const Icon(Icons.visibility),
                label: const Text('Probar solo UI'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.primary),
                  foregroundColor: colors.primary,
                  padding: EdgeInsets.symmetric(vertical: spacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing.xl),
            Text(
              'Pasos individuales',
              style: textStyles.headlineSmall,
            ),
            SizedBox(height: spacing.md),
            Expanded(
              flex: 2,
              child: ListView.separated(
                itemCount: _stepDefinitions.length,
                separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                itemBuilder: (context, index) => _buildStepButton(
                  _stepDefinitions[index],
                  colors,
                  spacing,
                  textStyles,
                ),
              ),
            ),
            if (_logs.isNotEmpty) ...[
              SizedBox(height: spacing.xl),
              Text(
                'Logs de ejecución',
                style: textStyles.headlineSmall,
              ),
              SizedBox(height: spacing.md),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: ListView.builder(
                    controller: _logController,
                    padding: EdgeInsets.all(spacing.md),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final color = log.contains('✅')
                          ? colors.success
                          : log.contains('❌')
                              ? colors.error
                              : colors.textPrimary;
                      return Padding(
                        padding: EdgeInsets.only(bottom: spacing.xs),
                        child: Text(
                          log,
                          style: textStyles.bodySmall.copyWith(
                            fontFamily: 'monospace',
                            color: color,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepButton(_TestStep step, AppColors colors, AppSpacing spacing,
      AppTextStyles textStyles) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: _isRunning ? null : () => _runStep(step),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
                vertical: spacing.md, horizontal: spacing.lg),
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.borderRadius),
            ),
          ),
          child: Text(
            step.title,
            style: textStyles.bodyMedium.copyWith(
              color: _isRunning ? colors.textSecondary : colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TestStep {
  final String title;
  final Future<void> Function(BuildContext) handler;

  const _TestStep(this.title, this.handler);
}
