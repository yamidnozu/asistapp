import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_utils.dart';
import '../utils/app_routes.dart';
import '../widgets/dashboard_widgets.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  Widget _buildDashboardOptions(BuildContext context, Map<String, dynamic> responsive) {
    final colors = context.colors;
    
    final cards = [
      DashboardFeatureCard(
        icon: Icons.business,
        title: 'Instituciones',
        description: 'Gestionar todas las instituciones del sistema',
        color: colors.primary,  // Usar color primario consistente
        responsive: responsive,
        onTap: () => context.go(AppRoutes.institutionsList),
      ),
      DashboardFeatureCard(
        icon: Icons.people,
        title: 'Usuarios Globales',
        description: 'Administrar usuarios de todo el sistema',
        color: colors.primary,  // Usar color primario consistente
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.security,
        title: 'Permisos',
        description: 'Configurar permisos y roles del sistema',
        color: colors.primary,  // Usar color primario consistente
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.analytics,
        title: 'Reportes Globales',
        description: 'Estadísticas y métricas del sistema completo',
        color: colors.primary,  // Usar color primario consistente
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.settings,
        title: 'Configuración',
        description: 'Ajustes globales del sistema',
        color: colors.primary,  // Usar color primario consistente
        responsive: responsive,
      ),
      DashboardFeatureCard(
        icon: Icons.backup,
        title: 'Backup & Restore',
        description: 'Gestión de respaldos del sistema',
        color: colors.error,  // Este puede mantener error para destacar su criticidad
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
          roleIcon: Icons.verified_user,
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

  Widget _buildBody(BuildContext context, String userName, Map<String, dynamic> responsive) {
    return DashboardBody(
      userGreeting: UserGreetingWidget(
        userName: userName,
        responsive: responsive,
      ),
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
    final userRole = 'Super Admin';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context, authProvider, colors.primary, userRole),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final responsive = ResponsiveUtils.getResponsiveValues(constraints);
          return _buildBody(context, userName, responsive);
        },
      ),
    );
  }
}