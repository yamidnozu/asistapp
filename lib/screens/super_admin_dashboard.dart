import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_utils.dart';
import '../widgets/dashboard_widgets.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  Widget _buildDashboardOptions(Map<String, dynamic> responsive) {
    final cards = [
      DashboardFeatureCard(
        icon: Icons.business,
        title: 'Instituciones',
        description: 'Gestionar todas las instituciones del sistema',
        color: Colors.blue,
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.people,
        title: 'Usuarios Globales',
        description: 'Administrar usuarios de todo el sistema',
        color: Colors.green,
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.security,
        title: 'Permisos',
        description: 'Configurar permisos y roles del sistema',
        color: Colors.orange,
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.analytics,
        title: 'Reportes Globales',
        description: 'Estadísticas y métricas del sistema completo',
        color: Colors.purple,
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.settings,
        title: 'Configuración',
        description: 'Ajustes globales del sistema',
        color: Colors.teal,
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.backup,
        title: 'Backup & Restore',
        description: 'Gestión de respaldos del sistema',
        color: Colors.red,
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
          roleIcon: Icons.verified_user,
        ),
      ],
    );
  }

  Widget _buildBody(String userName, Map<String, dynamic> responsive) {
    return DashboardBody(
      userGreeting: UserGreetingWidget(
        userName: userName,
        responsive: responsive,
        subtitle: 'Control Total del Sistema',
      ),
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
    final userRole = 'Super Admin';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(colors.primary, userRole),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final responsive = ResponsiveUtils.getResponsiveValues(constraints);
          return _buildBody(userName, responsive);
        },
      ),
    );
  }
}