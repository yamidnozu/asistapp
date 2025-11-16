import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/institution_provider.dart';
import '../theme/theme_extensions.dart';
import '../widgets/components/index.dart';
import '../widgets/common/dashboard_scaffold.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        final selectedInstitutionId = authProvider.selectedInstitutionId;
        final token = authProvider.accessToken;
        if (selectedInstitutionId != null && token != null) {
          await userProvider.loadUsersByInstitution(token, selectedInstitutionId);
        }
      } catch (e) {
        debugPrint('AdminDashboard init load error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Escuchar userProvider para refrescar estadísticas en tiempo real
    final userProvider = Provider.of<UserProvider>(context);
  final colors = context.colors;

    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Usuario';
  // selectedInstitution se obtiene del AuthProvider cuando se necesite en el UI

    // Obtener estadísticas desde el provider
    final stats = userProvider.getUserStatistics();

    // Convert AdminDashboard to use the generic DashboardScaffold
    return DashboardScaffold(
      userName: userName,
      subtitle: 'Bienvenido al panel de administración.',
      statsWidgets: [
        ClarityCompactStat(value: stats['total']?.toString() ?? '0', title: 'Usuarios', icon: Icons.people, color: colors.primary),
        ClarityCompactStat(value: stats['profesores']?.toString() ?? userProvider.professorsCount.toString(), title: 'Profesores', icon: Icons.school, color: colors.info),
        ClarityCompactStat(value: stats['estudiantes']?.toString() ?? userProvider.studentsCount.toString(), title: 'Estudiantes', icon: Icons.person, color: colors.warning),
      ],
      kpiWidget: _buildKpiRow(context, userProvider),
      recentActivityWidget: _buildRecentActivity(context, userProvider),
      actionItems: [
        DashboardActionItem(icon: Icons.people_outline_rounded, label: 'Usuarios', onTap: () => context.go('/users')),
        DashboardActionItem(icon: Icons.school_outlined, label: 'Gestión Académica', onTap: () => context.go('/academic')),
        DashboardActionItem(icon: Icons.calendar_today_outlined, label: 'Horarios', onTap: () {}),
        DashboardActionItem(icon: Icons.settings_outlined, label: 'Ajustes', onTap: () {}),
      ],
    );
  }

  // Widget para la nueva barra de estadísticas
  // Compact stats helper removed - stats rendered via DashboardScaffold

  // menu action items are centralized via DashboardScaffold actionItems

  Widget _buildKpiRow(BuildContext context, UserProvider userProvider) {
    final institutionProvider = Provider.of<InstitutionProvider>(context);
    final colors = context.colors;
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Métricas Rápidas', style: context.textStyles.headlineSmall),
          SizedBox(height: spacing.md),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            // Standard breakpoints: >=1024 (3 col), >=600 (2 col), else 1 col
            final columns = width >= 1024 ? 3 : (width >= 600 ? 2 : 1);
            final itemWidth = (width - ((columns - 1) * spacing.md)) / columns;

            return Wrap(
              spacing: spacing.md,
              runSpacing: spacing.md,
              alignment: WrapAlignment.start,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: ClarityKPICard(
                    value: institutionProvider.totalInstitutions.toString(),
                    label: 'Instituciones',
                    icon: Icons.apartment,
                    iconColor: colors.primary,
                    backgroundColor: colors.primary.withValues(alpha: 0.05),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: ClarityKPICard(
                    value: (userProvider.paginationInfo?.total ?? userProvider.loadedUsersCount).toString(),
                    label: 'Usuarios',
                    icon: Icons.people,
                    iconColor: colors.info,
                    backgroundColor: colors.info.withValues(alpha: 0.05),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: ClarityKPICard(
                    value: userProvider.professorsCount.toString(),
                    label: 'Profesores',
                    icon: Icons.school,
                    iconColor: colors.warning,
                    backgroundColor: colors.warning.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, UserProvider userProvider) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    final recent = userProvider.users.take(6).toList();

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actividad reciente', style: textStyles.headlineSmall),
          SizedBox(height: spacing.md),
          if (recent.isEmpty)
            Center(
              child: Text('No hay actividad reciente', style: textStyles.bodyMedium.copyWith(color: colors.textSecondary)),
            )
          else
            // Wrap list items inside a Material so ListTile has required Material ancestor
            Material(
              type: MaterialType.transparency,
              child: Column(
                children: recent.map((u) {
                  return ListTile(
                    onTap: () => context.go('/users?edit=true&userId=${u.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: colors.primary.withValues(alpha: 0.12), child: Text(u.inicial, style: textStyles.bodyMedium.withColor(colors.primary))),
                    title: Text(u.nombreCompleto, style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(u.email, style: textStyles.bodySmall.copyWith(color: colors.textSecondary)),
                    trailing: Chip(label: Text(u.rol, style: textStyles.labelSmall)),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}