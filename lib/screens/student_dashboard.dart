import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/asistencia_service.dart';
import '../services/academic/horario_service.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_styles.dart';

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

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de resumen centralizado
                  DashboardResumenCard(
                    icon: Icons.person_outline,
                    greeting: '¡Hola, $userName!',
                    subtitle: 'Panel del Estudiante',
                    onMenuPressed: () => Scaffold.of(context).openDrawer(),
                    onRefreshPressed: _loadStats,
                    stats: [
                      DashboardStatItem(
                        icon: Icons.check_circle_outline,
                        value:
                            _isLoadingStats ? '-' : '$_asistenciaPercentage%',
                        label: 'Asistencia',
                      ),
                      DashboardStatItem(
                        icon: Icons.class_outlined,
                        value: _isLoadingStats ? '-' : '$_totalMaterias',
                        label: 'Materias',
                      ),
                      DashboardStatItem(
                        icon: Icons.calendar_today_outlined,
                        value: _isLoadingStats ? '-' : '$_clasesHoy',
                        label: 'Clases Hoy',
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),

                  // Título de sección
                  Text('Acciones Principales', style: textStyles.headlineSmall),
                  SizedBox(height: spacing.md),

                  // Lista de acciones usando MenuActionCard
                  MenuActionCard(
                    icon: Icons.qr_code_2,
                    title: 'Mi Código QR',
                    subtitle: 'Para registrar asistencia',
                    onTap: () => context.go('/student/qr'),
                  ),
                  MenuActionCard(
                    icon: Icons.calendar_today,
                    title: 'Mi Horario',
                    subtitle: 'Ver mis clases',
                    onTap: () => context.go('/student/schedule'),
                  ),
                  MenuActionCard(
                    icon: Icons.check_circle_outline,
                    title: 'Mi Asistencia',
                    subtitle: 'Historial y estadísticas',
                    onTap: () => context.go('/student/attendance'),
                  ),
                  MenuActionCard(
                    icon: Icons.notifications_outlined,
                    title: 'Notificaciones',
                    subtitle: 'Ver mensajes',
                    onTap: () => context.go('/student/notifications'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
