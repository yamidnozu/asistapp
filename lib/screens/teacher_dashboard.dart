import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/horario_provider.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_styles.dart';
import '../models/clase_del_dia.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final horarioProvider =
        Provider.of<HorarioProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token != null) {
      await horarioProvider.cargarClasesDelDia(token);
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final horarioProvider = Provider.of<HorarioProvider>(context);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Profesor';

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
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
                    icon: Icons.school,
                    greeting: '¡Hola, $userName!',
                    subtitle: 'Panel del Profesor',
                    onMenuPressed: () => Scaffold.of(context).openDrawer(),
                    onRefreshPressed: _loadData,
                    stats: [
                      DashboardStatItem(
                        icon: Icons.calendar_today,
                        value: '${horarioProvider.clasesDelDiaCount}',
                        label: 'Clases Hoy',
                      ),
                      DashboardStatItem(
                        icon: Icons.access_time,
                        value: _getFormattedDate(),
                        label: 'Fecha',
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),

                  // Título de sección
                  Text('Clases de Hoy', style: textStyles.headlineSmall),
                  SizedBox(height: spacing.md),

                  // Lista de clases o estado vacío
                  if (horarioProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (horarioProvider.clasesDelDia.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...horarioProvider
                        .getClasesDelDiaOrdenadas()
                        .map((clase) => _ClaseCard(clase: clase)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_sunny_outlined, size: 64, color: colors.warning),
            SizedBox(height: spacing.md),
            Text('¡Día libre!', style: textStyles.headlineSmall),
            SizedBox(height: spacing.sm),
            Text(
              'No tienes clases programadas para hoy.',
              style:
                  textStyles.bodyMedium.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de clase
class _ClaseCard extends StatelessWidget {
  final ClaseDelDia clase;

  const _ClaseCard({required this.clase});

  @override
  Widget build(BuildContext context) {
    return MenuActionCard(
      icon: Icons.class_,
      title: clase.materia.nombre,
      subtitle:
          '${clase.horaInicio.substring(0, 5)} - ${clase.horaFin.substring(0, 5)} | ${clase.grupo.nombreCompleto}',
      onTap: () => context.pushNamed('teacher-attendance', extra: clase),
    );
  }
}
