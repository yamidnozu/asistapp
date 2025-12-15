import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/institution_provider.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_styles.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final selectedInstitutionId = authProvider.selectedInstitutionId;
      final token = authProvider.accessToken;
      if (selectedInstitutionId != null && token != null) {
        await userProvider.loadUsersByInstitution(token, selectedInstitutionId);
      }
    } catch (e) {
      debugPrint('AdminDashboard refresh error: $e');
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
    final institutionName =
        institutionProvider.selectedInstitution?.nombre ?? 'Institución';

    // Obtener estadísticas
    final stats = userProvider.getUserStatistics();

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
                    icon: Icons.dashboard,
                    greeting: '¡Hola, $userName!',
                    subtitle: institutionName,
                    onMenuPressed: () => Scaffold.of(context).openDrawer(),
                    onRefreshPressed: _refresh,
                    stats: [
                      DashboardStatItem(
                        icon: Icons.people,
                        value: '${stats['total'] ?? 0}',
                        label: 'Total',
                      ),
                      DashboardStatItem(
                        icon: Icons.school,
                        value: '${stats['profesores'] ?? 0}',
                        label: 'Profesores',
                      ),
                      DashboardStatItem(
                        icon: Icons.person,
                        value: '${stats['estudiantes'] ?? 0}',
                        label: 'Estudiantes',
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),

                  // Título de sección
                  Text('Gestión Académica', style: textStyles.headlineSmall),
                  SizedBox(height: spacing.md),

                  // Lista de acciones usando MenuActionCard
                  MenuActionCard(
                    icon: Icons.people,
                    title: 'Usuarios',
                    subtitle: 'Profesores y estudiantes',
                    onTap: () => context.go('/users'),
                  ),
                  MenuActionCard(
                    icon: Icons.groups,
                    title: 'Grupos',
                    subtitle: 'Grupos académicos',
                    onTap: () => context.go('/academic/grupos'),
                  ),
                  MenuActionCard(
                    icon: Icons.calendar_month,
                    title: 'Horarios',
                    subtitle: 'Configuración de clases',
                    onTap: () => context.go('/academic/horarios'),
                  ),
                  MenuActionCard(
                    icon: Icons.settings,
                    title: 'Configuración',
                    subtitle: 'Ajustes de la institución',
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
