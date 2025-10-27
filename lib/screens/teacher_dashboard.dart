import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../widgets/role_guard.dart';
import '../utils/role_enum.dart';
import '../utils/responsive_utils.dart';
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

  Widget _buildDashboardOptions(Map<String, dynamic> responsive) {
    final isSmallScreen = responsive['isSmallScreen'] as bool;

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
              color: Colors.green,
              responsive: responsive,
            ),
            DashboardFeatureCard(
              icon: Icons.assignment,
              title: 'Mis Clases',
              description: 'Ver horarios y grupos asignados',
              color: Colors.blue,
              responsive: responsive,
            ),
            DashboardFeatureCard(
              icon: Icons.people,
              title: 'Estudiantes',
              description: 'Lista de estudiantes por grupo',
              color: Colors.orange,
              responsive: responsive,
            ),
            DashboardFeatureCard(
              icon: Icons.bar_chart,
              title: 'Reportes',
              description: 'Estadísticas de asistencia',
              color: Colors.purple,
              responsive: responsive,
            ),
            RoleGuard(
              allowedRoles: [UserRole.profesor],
              child: DashboardFeatureCard(
                icon: Icons.notifications,
                title: 'Notificaciones',
                description: 'Enviar avisos a padres',
                color: Colors.teal,
                responsive: responsive,
              ),
            ),
            DashboardFeatureCard(
              icon: Icons.calendar_today,
              title: 'Horario',
              description: 'Mi horario de clases',
              color: Colors.indigo,
              responsive: responsive,
            ),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor, String userRole) {
    return DashboardAppBar(
      backgroundColor: primaryColor,
      actions: [
        DashboardAppBarActions(
          userRole: userRole,
          roleIcon: Icons.school,
        ),
      ],
    );
  }

  Widget _buildBody(String userName, AuthProvider authProvider, Map<String, dynamic> responsive) {
    return DashboardBody(
      userGreeting: _buildUserGreeting(userName, authProvider, responsive),
      dashboardOptions: _buildDashboardOptions(responsive),
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
      appBar: _buildAppBar(colors.primary, userRole),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final responsive = ResponsiveUtils.getResponsiveValues(constraints);
          return _buildBody(userName, authProvider, responsive);
        },
      ),
    );
  }
}