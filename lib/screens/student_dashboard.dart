import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/asistencia_service.dart';
import '../services/academic/horario_service.dart';
import '../theme/theme_extensions.dart';
import '../widgets/components/index.dart';

// Helper para construir acciones con estilo consistente (copiado de admin_dashboard)
Widget _buildMenuActionItem(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
  required Color color,
  required VoidCallback onTap,
  bool isFirst = false,
  bool isLast = false,
}) {
  final textStyles = context.textStyles;
  final spacing = context.spacing;
  final colors = context.colors;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.lg,
          vertical: spacing.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: textStyles.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _isLoadingStats = true;
  int _asistenciaPercentage = 0;
  int _totalMaterias = 0;
  int _clasesHoy = 0;

  final AsistenciaService _asistenciaService = AsistenciaService();
  final HorarioService _horarioService = HorarioService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token == null) {
        setState(() {
          _isLoadingStats = false;
        });
        return;
      }

      // Load attendance data for percentage calculation
      final asistencias = await _asistenciaService.getAsistenciasEstudiante(
        accessToken: token,
      );

      // Load schedule data for materias count
      final horarios = await _horarioService.getMisHorariosEstudiante(token);

      if (!mounted) return;

      // Calculate attendance percentage
      int percentage = 0;
      if (asistencias != null && asistencias.isNotEmpty) {
        final total = asistencias.length;
        final presentes = asistencias.where((a) {
          final estado = (a['estado'] as String?)?.toUpperCase() ?? '';
          return estado == 'PRESENTE' || estado == 'TARDANZA';
        }).length;
        percentage = total > 0 ? ((presentes / total) * 100).round() : 0;
      }

      // Calculate unique materias from horarios
      int materiasCount = 0;
      int clasesHoyCount = 0;
      if (horarios != null && horarios.isNotEmpty) {
        final materiaIds = <String>{};
        final hoy = DateTime.now().weekday; // 1=Monday, 7=Sunday

        for (final horario in horarios) {
          final materia = horario['materia'] as Map<String, dynamic>?;
          if (materia != null && materia['id'] != null) {
            materiaIds.add(materia['id'] as String);
          }

          // Count classes for today
          final diaSemana = horario['diaSemana'] as int?;
          if (diaSemana == hoy) {
            clasesHoyCount++;
          }
        }
        materiasCount = materiaIds.length;
      }

      setState(() {
        _asistenciaPercentage = percentage;
        _totalMaterias = materiasCount;
        _clasesHoy = clasesHoyCount;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Error loading student stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Usuario';

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Saludo Sutil
            Text('¡Hola, $userName!',
                style: textStyles.displayMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: spacing.sm),
            Text(
              'Bienvenido al panel estudiantil.',
              style: textStyles.bodyLarge.copyWith(color: colors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: spacing.xl),

            // 2. Barra de Estadísticas con datos reales
            _buildCompactStatsBar(context),

            SizedBox(height: spacing.xl),

            // 3. Acciones principales en lista compacta (estilo Admin)
            Text('Acciones Principales', style: textStyles.headlineSmall),
            SizedBox(height: spacing.md),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(spacing.borderRadius),
                border: Border.all(color: colors.borderLight),
              ),
              child: Column(
                children: [
                  _buildMenuActionItem(
                    context,
                    icon: Icons.qr_code_2_rounded,
                    label: 'Mi Código QR',
                    value: 'Para registrar asistencia',
                    color: colors.primary,
                    onTap: () => context.go('/student/qr'),
                    isFirst: true,
                  ),
                  Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
                  _buildMenuActionItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Mi Horario',
                    value: 'Ver mis clases',
                    color: const Color(0xFF06B6D4),
                    onTap: () => context.go('/student/schedule'),
                  ),
                  Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
                  _buildMenuActionItem(
                    context,
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Mi Asistencia',
                    value: 'Historial y estadísticas',
                    color: colors.success,
                    onTap: () => context.go('/student/attendance'),
                  ),
                  Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
                  _buildMenuActionItem(
                    context,
                    icon: Icons.notifications_outlined,
                    label: 'Notificaciones',
                    value: 'Ver mensajes',
                    color: colors.warning,
                    onTap: () => context.go('/student/notifications'),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para la barra de estadísticas con datos reales
  Widget _buildCompactStatsBar(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        border: Border.all(color: colors.borderLight),
      ),
      child: _isLoadingStats
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(spacing.md),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ClarityCompactStat(
                    value: '$_asistenciaPercentage%',
                    title: 'Asistencia',
                    icon: Icons.check_circle,
                    color: _asistenciaPercentage >= 80
                        ? colors.success
                        : _asistenciaPercentage >= 60
                            ? colors.warning
                            : colors.error,
                  ),
                  SizedBox(width: spacing.lg),
                  ClarityCompactStat(
                    value: '$_clasesHoy',
                    title: 'Clases Hoy',
                    icon: Icons.today,
                    color: colors.primary,
                  ),
                  SizedBox(width: spacing.lg),
                  ClarityCompactStat(
                    value: '$_totalMaterias',
                    title: 'Materias',
                    icon: Icons.book,
                    color: colors.info,
                  ),
                ],
              ),
            ),
    );
  }
}
