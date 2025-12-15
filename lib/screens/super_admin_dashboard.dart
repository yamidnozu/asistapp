import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/institution_provider.dart';
import '../providers/user_provider.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_styles.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final institutionProvider =
          Provider.of<InstitutionProvider>(context, listen: false);

      final token = authProvider.accessToken;
      if (token != null) {
        await userProvider.loadUsers(token);
        await institutionProvider.loadInstitutions(token);
      }
    } catch (e) {
      debugPrint('SuperAdminDashboard refresh error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final institutionProvider = Provider.of<InstitutionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Usuario';

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
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
                    icon: Icons.admin_panel_settings,
                    greeting: '¡Hola, $userName!',
                    subtitle: 'Super Administrador',
                    onMenuPressed: () => Scaffold.of(context).openDrawer(),
                    onRefreshPressed: _refresh,
                    stats: [
                      DashboardStatItem(
                        icon: Icons.business,
                        value:
                            '${institutionProvider.paginationInfo?.total ?? 0}',
                        label: 'Instituciones',
                      ),
                      DashboardStatItem(
                        icon: Icons.people,
                        value: '${userProvider.totalUsersFromPagination}',
                        label: 'Usuarios',
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),

                  // Título de sección
                  Text('Acciones Principales', style: textStyles.headlineSmall),
                  SizedBox(height: spacing.md),

                  // Lista de acciones usando MenuActionCard
                  MenuActionCard(
                    icon: Icons.business,
                    title: 'Instituciones',
                    subtitle: 'Gestionar instituciones educativas',
                    onTap: () => context.go('/institutions'),
                  ),
                  MenuActionCard(
                    icon: Icons.people,
                    title: 'Usuarios',
                    subtitle: 'Administrar usuarios del sistema',
                    onTap: () => context.go('/users'),
                  ),
                  MenuActionCard(
                    icon: Icons.settings,
                    title: 'Configuración',
                    subtitle: 'Ajustes del sistema',
                    onTap: () => context.go('/settings'),
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
