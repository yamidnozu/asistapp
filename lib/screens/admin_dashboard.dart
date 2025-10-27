import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_utils.dart';
import '../widgets/dashboard_widgets.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Widget _buildUserGreeting(String userName, AuthProvider authProvider, Map<String, dynamic> responsive) {
    final selectedInstitution = authProvider.selectedInstitution;

    return UserGreetingWidget(
      userName: userName,
      responsive: responsive,
      subtitle: selectedInstitution?.name,
    );
  }

  Widget _buildDashboardOptions(Map<String, dynamic> responsive) {
    final cards = [
      DashboardFeatureCard(
        icon: Icons.people,
        title: 'Usuarios',
        description: 'Gestionar profesores y estudiantes',
        color: Colors.blue,
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.class_,
        title: 'Grupos',
        description: 'Administrar salones de clase',
        color: Colors.green,
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.schedule,
        title: 'Horarios',
        description: 'Configurar horarios de clases',
        color: Colors.orange,
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.assignment,
        title: 'Asistencia',
        description: 'Control y registro de asistencia',
        color: Colors.purple,
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.bar_chart,
        title: 'Reportes',
        description: 'Estadísticas de la institución',
        color: Colors.teal,
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.settings,
        title: 'Configuración',
        description: 'Ajustes de la institución',
        color: Colors.indigo,
        responsive: responsive,
      ),
    ];

    return DashboardOptionsGrid(
      cards: cards,
      responsive: responsive,
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor, String userRole) {
    return DashboardAppBar(
      backgroundColor: primaryColor,
      actions: [
        DashboardAppBarActions(
          userRole: userRole,
          roleIcon: Icons.admin_panel_settings,
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
    final userRole = 'Administrador';

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