import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _asistencias = [];
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAsistencias();
  }

  Future<void> _loadAsistencias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token == null) {
        setState(() {
          _errorMessage = 'No se pudo obtener el token de autenticación';
          _isLoading = false;
        });
        return;
      }

      // TODO: Implementar llamada al backend GET /estudiantes/dashboard/asistencia
      // Por ahora, datos de ejemplo
      await Future.delayed(const Duration(seconds: 1)); // Simular carga

      setState(() {
        _asistencias = [
          {
            'fecha': '2024-01-15',
            'hora': '07:00',
            'materia': {'nombre': 'Matemáticas'},
            'profesor': {'nombres': 'Juan', 'apellidos': 'Pérez'},
            'estado': 'presente',
            'tipo': 'qr',
          },
          {
            'fecha': '2024-01-15',
            'hora': '08:00',
            'materia': {'nombre': 'Física'},
            'profesor': {'nombres': 'Laura', 'apellidos': 'Gómez'},
            'estado': 'presente',
            'tipo': 'manual',
          },
          {
            'fecha': '2024-01-14',
            'hora': '07:00',
            'materia': {'nombre': 'Química'},
            'profesor': {'nombres': 'Laura', 'apellidos': 'Gómez'},
            'estado': 'ausente',
            'tipo': 'qr',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar asistencias: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.colors.primary,
              onPrimary: context.colors.onPrimary,
              surface: context.colors.surface,
              onSurface: context.colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAsistencias(); // Recargar datos para la nueva fecha
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    _loadAsistencias();
  }

  void _nextMonth() {
    final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    if (nextMonth.isBefore(DateTime.now()) || nextMonth.month == DateTime.now().month) {
      setState(() {
        _selectedDate = nextMonth;
      });
      _loadAsistencias();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Asistencia', style: textStyles.headlineMedium),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: _previousMonth,
            tooltip: 'Mes anterior',
          ),
          TextButton(
            onPressed: () => _selectDate(context),
            child: Text(
              '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
              style: textStyles.titleMedium.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            tooltip: 'Mes siguiente',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildAttendanceContent(),
    );
  }

  Widget _buildErrorState() {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.error),
          SizedBox(height: spacing.lg),
          Text(
            'Error al cargar asistencia',
            style: textStyles.headlineSmall.copyWith(color: colors.error),
          ),
          SizedBox(height: spacing.sm),
          Text(
            _errorMessage ?? 'Ocurrió un error desconocido',
            style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.xl),
          ElevatedButton.icon(
            onPressed: _loadAsistencias,
            icon: Icon(Icons.refresh),
            label: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent() {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    if (_asistencias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: colors.textMuted),
            SizedBox(height: spacing.lg),
            Text(
              'No hay registros de asistencia',
              style: textStyles.headlineSmall.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Los registros aparecerán aquí cuando marques asistencia',
              style: textStyles.bodyMedium.copyWith(color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Calcular estadísticas
    final total = _asistencias.length;
    final presentes = _asistencias.where((a) => a['estado'] == 'presente').length;
    final ausentes = _asistencias.where((a) => a['estado'] == 'ausente').length;
    final porcentajeAsistencia = total > 0 ? (presentes / total * 100).round() : 0;

    return RefreshIndicator(
      onRefresh: _loadAsistencias,
      child: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          // Estadísticas
          Card(
            child: Padding(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                children: [
                  Text(
                    'Estadísticas de Asistencia',
                    style: textStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total', total.toString(), colors.textPrimary),
                      _buildStatItem('Presente', presentes.toString(), colors.success),
                      _buildStatItem('Ausente', ausentes.toString(), colors.error),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  LinearProgressIndicator(
                    value: porcentajeAsistencia / 100,
                    backgroundColor: colors.error.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.success),
                  ),
                  SizedBox(height: spacing.sm),
                  Text(
                    '$porcentajeAsistencia% de asistencia',
                    style: textStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.xl),

          // Lista de asistencias
          Text(
            'Historial de Asistencia',
            style: textStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: spacing.md),
          ..._asistencias.map((asistencia) => _buildAttendanceCard(asistencia)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    final textStyles = context.textStyles;

    return Column(
      children: [
        Text(
          value,
          style: textStyles.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: textStyles.bodySmall.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> asistencia) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    final materia = asistencia['materia'] as Map<String, dynamic>;
    final profesor = asistencia['profesor'] as Map<String, dynamic>;
    final estado = asistencia['estado'] as String;
    final tipo = asistencia['tipo'] as String;

    final isPresente = estado == 'presente';
    final statusColor = isPresente ? colors.success : colors.error;
    final statusIcon = isPresente ? Icons.check_circle : Icons.cancel;
    final statusText = isPresente ? 'Presente' : 'Ausente';

    return Card(
      margin: EdgeInsets.only(bottom: spacing.md),
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(spacing.borderRadius),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 28,
              ),
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        materia['nombre'] ?? 'Sin nombre',
                        style: textStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(spacing.borderRadius / 2),
                        ),
                        child: Text(
                          statusText,
                          style: textStyles.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    'Prof. ${profesor['nombres']} ${profesor['apellidos']}',
                    style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
                  ),
                  SizedBox(height: spacing.xs),
                  Row(
                    children: [
                      Icon(
                        tipo == 'qr' ? Icons.qr_code : Icons.edit,
                        size: 16,
                        color: colors.textMuted,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${asistencia['fecha']} • ${asistencia['hora']}',
                        style: textStyles.bodySmall.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}