import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Widget flotante para mostrar logs de errores y debugging
/// Aparece en la parte inferior de la pantalla sin interferir con la UI principal
class ErrorLoggerWidget extends StatefulWidget {
  ErrorLoggerWidget() : super(key: errorLoggerKey);

  @override
  State<ErrorLoggerWidget> createState() => ErrorLoggerWidgetState();
}

class ErrorLoggerWidgetState extends State<ErrorLoggerWidget> {
  final List<String> _logs = [];
  bool _isExpanded = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // No capturar errores de Flutter automáticamente para evitar setState durante build
  }

  void addLog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _addLog(message);
      }
    });
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19); // HH:MM:SS
      _logs.add('[$timestamp] $message');
      if (_logs.length > 50) {
        _logs.removeAt(0); // Mantener solo los últimos 50 logs
      }
      _isVisible = true;
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Positioned(
      bottom: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _isExpanded ? 300 : 60,
          height: _isExpanded ? 200 : 60,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: _isExpanded ? _buildExpandedView() : _buildCollapsedView(),
        ),
      ),
    );
  }

  Widget _buildCollapsedView() {
    final errorCount = _logs.where((log) => log.contains('ERROR')).length;
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              errorCount > 0 ? Icons.error : Icons.bug_report,
              color: errorCount > 0 ? AppColors.error : AppColors.warning,
              size: 24,
            ),
            if (errorCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  errorCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Logs de Debug',
                style: AppTextStyles.labelLarge,
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearLogs,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.clear_all, size: 16),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = false),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16),
                ),
              ),
            ],
          ),
        ),
        // Logs
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No hay logs',
                      style: AppTextStyles.bodySmall,
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[_logs.length - 1 - index]; // Mostrar los más recientes primero
                      final isError = log.contains('ERROR');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontSize: 10,
                            color: isError ? AppColors.error : AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// Función global para agregar logs desde cualquier parte de la app
final GlobalKey<ErrorLoggerWidgetState> errorLoggerKey = GlobalKey<ErrorLoggerWidgetState>();

void addDebugLog(String message) {
  debugPrint(message);
  errorLoggerKey.currentState?.addLog(message);
}