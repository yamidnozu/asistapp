import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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

  Widget _buildDashboardOptions(BuildContext context, Map<String, dynamic> responsive) {
    final colors = context.colors;
    
    final cards = [
      DashboardFeatureCard(
        icon: Icons.people,
        title: 'Usuarios',
        description: 'Gestionar profesores y estudiantes',
        color: colors.primary,  // Usar color primario consistente
        responsive: responsive,
        onTap: () => context.go('/users'),
      ),
      DashboardFeatureCard(
        icon: Icons.class_,
        title: 'Grupos',
        description: 'Administrar salones de clase',
        color: colors.primary,  // Usar color primario consistente
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.schedule,
        title: 'Horarios',
        description: 'Configurar horarios de clases',
        color: colors.primary,  // Usar color primario consistente
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.assignment,
        title: 'Asistencia',
        description: 'Control y registro de asistencia',
        color: colors.primary,  // Usar color primario consistente
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.bar_chart,
        title: 'Reportes',
        description: 'Estadísticas de la institución',
        color: colors.primary,  // Usar color primario consistente
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.settings,
        title: 'Configuración',
        description: 'Ajustes de la institución',
        color: colors.primary,  // Usar color primario consistente
        responsive: responsive,
      ),
    ];

    return DashboardOptionsGrid(
      cards: cards,
      responsive: responsive,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthProvider authProvider, Color primaryColor, String userRole) {
    return DashboardAppBar(
      backgroundColor: primaryColor,
      actions: [
        DashboardAppBarActions(
          userRole: userRole,
          roleIcon: Icons.admin_panel_settings,
          onLogout: () async {
            await authProvider.logout();
            if (context.mounted) {
              context.go('/login');
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
    final userRole = 'Administrador';

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