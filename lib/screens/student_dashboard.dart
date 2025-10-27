import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../widgets/role_guard.dart';
import '../utils/role_enum.dart';
import '../utils/responsive_utils.dart';
import '../widgets/dashboard_widgets.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  Widget _buildUserGreeting(String userName, AuthProvider authProvider, Map<String, dynamic> responsive) {
    final selectedInstitution = authProvider.selectedInstitution;

    return UserGreetingWidget(
      userName: userName,
      responsive: responsive,
      subtitle: selectedInstitution?.name,
    );
  }

  Widget _buildDashboardOptions(Map<String, dynamic> responsive) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            DashboardFeatureCard(
              icon: Icons.qr_code,
              title: 'Mi Código QR',
              description: 'Mostrar código para asistencia',
              color: Colors.green,
              responsive: responsive,
            ),
            RoleGuard(
              allowedRoles: [UserRole.estudiante],
              child: DashboardFeatureCard(
                icon: Icons.calendar_today,
                title: 'Mi Horario',
                description: 'Ver clases del día',
                color: Colors.blue,
                responsive: responsive,
              ),
            ),
            DashboardFeatureCard(
              icon: Icons.assignment,
              title: 'Asistencia',
              description: 'Historial de mi asistencia',
              color: Colors.orange,
              responsive: responsive,
            ),
            DashboardFeatureCard(
              icon: Icons.bar_chart,
              title: 'Estadísticas',
              description: 'Mi rendimiento académico',
              color: Colors.purple,
              responsive: responsive,
            ),
            DashboardFeatureCard(
              icon: Icons.notifications,
              title: 'Notificaciones',
              description: 'Avisos de padres/profesores',
              color: Colors.teal,
              responsive: responsive,
            ),
            DashboardFeatureCard(
              icon: Icons.contact_phone,
              title: 'Contacto',
              description: 'Información de contacto',
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
          roleIcon: Icons.person,
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
    final userRole = 'Estudiante';

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