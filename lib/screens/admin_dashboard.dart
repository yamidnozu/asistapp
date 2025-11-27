import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/institution_provider.dart';
import '../theme/theme_extensions.dart';
import '../widgets/components/index.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

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
    final authProvider = Provider.of<AuthProvider>(context);
    final institutionProvider = Provider.of<InstitutionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Usuario';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1024;
        final isTablet = constraints.maxWidth > 600;
        final columnCount = isDesktop ? 4 : (isTablet ? 3 : 2);

        return isDesktop
            ? _buildDesktopLayout(
                context,
                userName,
                institutionProvider,
                userProvider,
                columnCount,
              )
            : _buildMobileLayout(
                context,
                userName,
                institutionProvider,
                userProvider,
                columnCount,
              );
      },
    );
  }

  /// Layout Desktop (70% contenido, 30% sidebar)
  Widget _buildDesktopLayout(
    BuildContext context,
    String userName,
    InstitutionProvider institutionProvider,
    UserProvider userProvider,
    int columnCount,
  ) {
    final spacing = context.spacing;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(spacing.screenPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 70% - Contenido Principal
            Expanded(
              flex: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(context, userName),
                  SizedBox(height: spacing.xl),
                  _buildKPIRow(context, userProvider),
                  SizedBox(height: spacing.xl),
                  _buildActionsGrid(context, columnCount),
                ],
              ),
            ),
            SizedBox(width: spacing.lg),
          ],
        ),
      ),
    );
  }

  /// Layout Móvil/Tablet (flujo vertical)
  Widget _buildMobileLayout(
    BuildContext context,
    String userName,
    InstitutionProvider institutionProvider,
    UserProvider userProvider,
    int columnCount,
  ) {
    final spacing = context.spacing;

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(context, userName),
          SizedBox(height: spacing.xl),
          _buildKPIRow(context, userProvider),
          SizedBox(height: spacing.xl),
          _buildActionsGrid(context, columnCount),
        ],
      ),
    );
  }

  /// Saludo Sutil
  Widget _buildGreeting(BuildContext context, String userName) {
    final textStyles = context.textStyles;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Hola, $userName!',
          style: textStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: context.spacing.sm),
        Text(
          'Bienvenido al panel de administración.',
          style: textStyles.bodyLarge.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  /// Row de KPIs
  Widget _buildKPIRow(BuildContext context, UserProvider userProvider) {
    final spacing = context.spacing;

    // Obtener estadísticas desde el provider
    final stats = userProvider.getUserStatistics();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ClarityCompactStat(
            value: stats['total']?.toString() ?? '0',
            title: 'Usuarios',
            icon: Icons.people,
            color: context.colors.primary,
          ),
          SizedBox(width: spacing.lg),
          ClarityCompactStat(
            value: stats['profesores']?.toString() ?? userProvider.professorsCount.toString(),
            title: 'Profesores',
            icon: Icons.school,
            color: context.colors.info,
          ),
          SizedBox(width: spacing.lg),
          ClarityCompactStat(
            value: stats['estudiantes']?.toString() ?? userProvider.studentsCount.toString(),
            title: 'Estudiantes',
            icon: Icons.person,
            color: context.colors.warning,
          ),
        ],
      ),
    );
  }

  /// Grilla de Acciones Principal
  Widget _buildActionsGrid(BuildContext context, int columnCount) {
    final spacing = context.spacing;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Principales',
          style: context.textStyles.headlineSmall,
        ),
        SizedBox(height: spacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            border: Border.all(color: colors.borderLight),
          ),
          child: Column(
            children: [
              _buildMenuActionItem(
                context,
                icon: Icons.people_outline_rounded,
                label: 'Usuarios',
                value: 'Gestión de usuarios',
                color: colors.primary,
                onTap: () => context.go('/users'),
                isFirst: true,
              ),
              Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
              _buildMenuActionItem(
                context,
                icon: Icons.group_outlined,
                label: 'Grupos',
                value: 'Gestión de grupos académicos',
                color: colors.success,
                onTap: () => context.go('/academic/grupos'),
              ),
              Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
              _buildMenuActionItem(
                context,
                icon: Icons.calendar_today_outlined,
                label: 'Horarios',
                value: 'Configuración de horarios',
                color: colors.warning,
                onTap: () => context.go('/academic/horarios'),
              ),
              Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
              _buildMenuActionItem(
                context,
                icon: Icons.settings_outlined,
                label: 'Ajustes',
                value: 'Configuración del sistema',
                color: const Color(0xFF8B5CF6),
                onTap: () => context.go('/settings'),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      value,
                      style: textStyles.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}