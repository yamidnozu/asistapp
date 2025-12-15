import 'package:flutter/material.dart';
import '../utils/test_flow_manager.dart';
import '../theme/theme_extensions.dart';

/// Pantalla de pruebas para ejecutar flujos completos de testing
class TestRunnerScreen extends StatefulWidget {
  const TestRunnerScreen({super.key});

  @override
  State<TestRunnerScreen> createState() => _TestRunnerScreenState();
}

class _TestRunnerScreenState extends State<TestRunnerScreen> {
  bool _isRunning = false;
  String _currentStep = '';
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().split('.')[0]}] $message');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _runFullFlow() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
      _currentStep = 'Iniciando flujo completo...';
    });

    _addLog('🚀 Iniciando Flujo Completo de Pruebas');

    try {
      await TestFlowManager.ejecutarFlujoCompleto(context);
      _addLog('🎉 Flujo completado exitosamente');
    } catch (e) {
      _addLog('❌ Error en el flujo: $e');
    } finally {
      setState(() {
        _isRunning = false;
        _currentStep = '';
      });
    }
  }

  Future<void> _runUITests() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
      _currentStep = 'Probando UI...';
    });

    _addLog('🎨 Iniciando Pruebas de UI');

    try {
      await TestFlowManager.ejecutarPruebasUI(context);
      _addLog('✅ Pruebas de UI completadas');
    } catch (e) {
      _addLog('❌ Error en pruebas UI: $e');
    } finally {
      setState(() {
        _isRunning = false;
        _currentStep = '';
      });
    }
  }

  Future<void> _runIndividualStep(
      String stepName, Future<void> Function() stepFunction) async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _currentStep = stepName;
    });

    _addLog('🧪 Ejecutando: $stepName');

    try {
      await stepFunction();
      _addLog('✅ $stepName completado');
    } catch (e) {
      _addLog('❌ Error en $stepName: $e');
    } finally {
      setState(() {
        _isRunning = false;
        _currentStep = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        title: Text(
          'Flujo de Pruebas',
          style: textStyles.titleLarge,
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(spacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y descripción
            Text(
              'Herramientas de Testing',
              style: textStyles.displayMedium,
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Ejecuta flujos completos de pruebas para validar todas las funcionalidades de la aplicación.',
              style: textStyles.bodyLarge.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: spacing.xl),

            // Estado actual
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

            // Botones de acción
            Text(
              'Flujos de Prueba',
              style: textStyles.headlineSmall,
            ),
            SizedBox(height: spacing.md),

            // Botón flujo completo
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runFullFlow,
                icon: Icon(_isRunning ? Icons.hourglass_top : Icons.play_arrow),
                label: Text(
                    _isRunning ? 'Ejecutando...' : 'Ejecutar Flujo Completo'),
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

            // Botón pruebas UI
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isRunning ? null : _runUITests,
                icon: const Icon(Icons.visibility),
                label: const Text('Probar Solo UI'),
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

            // Pasos individuales
            Text(
              'Pasos Individuales',
              style: textStyles.headlineSmall,
            ),
            SizedBox(height: spacing.md),

            Expanded(
              child: ListView(
                children: [
                  _buildStepButton('1. Login Super Admin',
                      () => TestFlowManager.step1LoginSuperAdmin(context)),
                  _buildStepButton('2. Crear Institución',
                      () => TestFlowManager.step2CrearInstitucion(context)),
                  _buildStepButton(
                      '3. Crear Admin Institución',
                      () =>
                          TestFlowManager.step3CrearAdminInstitucion(context)),
                  _buildStepButton('4. Crear Profesores',
                      () => TestFlowManager.step4CrearProfesores(context)),
                  _buildStepButton('5. Crear Estudiantes',
                      () => TestFlowManager.step5CrearEstudiantes(context)),
                  _buildStepButton('6. Crear Materias',
                      () => TestFlowManager.step6CrearMaterias(context)),
                  _buildStepButton('7. Crear Grupos',
                      () => TestFlowManager.step7CrearGrupos(context)),
                  _buildStepButton('8. Crear Horarios',
                      () => TestFlowManager.step8CrearHorarios(context)),
                  _buildStepButton('9. Verificar Asistencias',
                      () => TestFlowManager.step9VerificarAsistencias(context)),
                  _buildStepButton('10. Verificar Dashboards',
                      () => TestFlowManager.step10VerificarDashboards(context)),
                ],
              ),
            ),

            SizedBox(height: spacing.xl),

            // Logs
            if (_logs.isNotEmpty) ...[
              Text(
                'Logs de Ejecución',
                style: textStyles.headlineSmall,
              ),
              SizedBox(height: spacing.md),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(spacing.md),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: spacing.xs),
                        child: Text(
                          _logs[index],
                          style: textStyles.bodySmall.copyWith(
                            fontFamily: 'monospace',
                            color: _logs[index].contains('✅')
                                ? colors.success
                                : _logs[index].contains('❌')
                                    ? colors.error
                                    : colors.textPrimary,
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

  Widget _buildStepButton(String title, Future<void> Function() onPressed) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed:
              _isRunning ? null : () => _runIndividualStep(title, onPressed),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
                vertical: spacing.md, horizontal: spacing.lg),
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.borderRadius),
            ),
          ),
          child: Text(
            title,
            style: textStyles.bodyMedium.copyWith(
              color: _isRunning ? colors.textSecondary : colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
