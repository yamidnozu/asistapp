import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../widgets/role_guard.dart';
import '../utils/role_enum.dart';
import '../utils/responsive_utils.dart';
import '../utils/app_routes.dart';
import '../widgets/dashboard_widgets.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  Widget _buildUserGreeting(String userName, AuthProvider authProvider, Map<String, dynamic> responsive) {
    final selectedInstitution = authProvider.selectedInstitution;

    return UserGreetingWidget(
      userName: userName,
      responsive: responsive,
      subtitle: selectedInstitution?.name,
    );
  }

  Widget _buildDashboardOptions(BuildContext context, Map<String, dynamic> responsive) {
    final colors = context.colors;

    return Column(
      children: [
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            DashboardFeatureCard(
              icon: Icons.qr_code_scanner,
              title: 'Tomar Asistencia',
              description: 'Registrar asistencia con QR',
              color: colors.primary,  // Usar color primario consistente
              responsive: responsive,
            ),
            DashboardFeatureCard(
              icon: Icons.assignment,
              title: 'Mis Clases',
              description: 'Ver horarios y grupos asignados',
              color: colors.primary,  // Usar color primario consistente
              responsive: responsive,
            ),
            DashboardFeatureCard(
              icon: Icons.people,
              title: 'Estudiantes',
              description: 'Lista de estudiantes por grupo',
              color: colors.primary,  // Usar color primario consistente
              responsive: responsive,
            ),
            DashboardFeatureCard(
              icon: Icons.bar_chart,
              title: 'Reportes',
              description: 'Estadísticas de asistencia',
              color: colors.primary,  // Usar color primario consistente
              responsive: responsive,
            ),
            RoleGuard(
              allowedRoles: [UserRole.profesor],
              child: DashboardFeatureCard(
                icon: Icons.notifications,
                title: 'Notificaciones',
                description: 'Enviar avisos a padres',
                color: colors.primary,  // Usar color primario consistente
                responsive: responsive,
              ),
            ),
            DashboardFeatureCard(
              icon: Icons.calendar_today,
              title: 'Horario',
              description: 'Mi horario de clases',
              color: colors.primary,  // Usar color primario consistente
              responsive: responsive,
            ),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthProvider authProvider, Color primaryColor, String userRole) {
    return DashboardAppBar(
      backgroundColor: primaryColor,
      actions: [
        DashboardAppBarActions(
          userRole: userRole,
          roleIcon: Icons.school,
          onLogout: () async {
            await authProvider.logout();
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, String userName, AuthProvider authProvider, Map<String, dynamic> responsive) {
    return DashboardBody(
      userGreeting: _buildUserGreeting(userName, authProvider, responsive),
      dashboardOptions: _buildDashboardOptions(context, responsive),
      responsive: responsive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colors = context.colors;
    
    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Usuario';
    final userRole = 'Profesor';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context, authProvider, colors.primary, userRole),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final responsive = ResponsiveUtils.getResponsiveValues(constraints);
          return _buildBody(context, userName, authProvider, responsive);
        },
      ),
    );
  }
}