import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/institution_provider.dart';
import '../providers/user_provider.dart';
import '../theme/theme_extensions.dart';
import '../widgets/components/index.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);

        final token = authProvider.accessToken;
        if (token != null) {
          await userProvider.loadUsers(token);
          await institutionProvider.loadInstitutions(token);
        }
      } catch (e) {
        debugPrint('SuperAdminDashboard init load error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final institutionProvider = Provider.of<InstitutionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
  // Usar context.colors / context.textStyles localmente en widgets según sea necesario

    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Usuario';

    return LayoutBuilder(
      builder: (context, constraints) {
          // FASE 3: Detección de dispositivo
          final isDesktop = constraints.maxWidth > 1024;
          final isTablet = constraints.maxWidth > 600;
          final columnCount = isDesktop ? 4 : (isTablet ? 3 : 2);

          // FASE 7: Layout adaptativo 70/30 para desktop
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

  /// FASE 7: Layout Desktop (70% contenido, 30% sidebar)
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
                  _buildKPIRow(context, institutionProvider, userProvider),
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

  /// Lay out Móvil/Tablet (flujo vertical)
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
          _buildKPIRow(context, institutionProvider, userProvider),
          SizedBox(height: spacing.xl),
          _buildActionsGrid(context, columnCount),
        ],
      ),
    );
  }

  /// Saludo Sutil (Fase 1)
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
          'Bienvenido al panel de administración del sistema.',
          style: textStyles.bodyLarge.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  /// Row de KPIs (Fase 7: Mejor visualización)
  Widget _buildKPIRow(
    BuildContext context,
    InstitutionProvider institutionProvider,
    UserProvider userProvider,
  ) {
    final spacing = context.spacing;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ClarityCompactStat(
            value: (institutionProvider.paginationInfo?.total ?? 0).toString(),
            title: 'Instituciones',
            icon: Icons.business,
            color: context.colors.primary,
          ),
          SizedBox(width: spacing.lg),
          ClarityCompactStat(
            value: userProvider.totalUsersFromPagination.toString(),
            title: 'Usuarios',
            icon: Icons.people,
            color: context.colors.info,
          ),
          SizedBox(width: spacing.lg),
          ClarityCompactStat(
            value: '3',
            title: 'Reportes',
            icon: Icons.analytics,
            color: context.colors.warning,
          ),
        ],
      ),
    );
  }

  /// Grilla de Acciones Principal (Fase 1: Clarity UI)
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
                icon: Icons.business_rounded,
                label: 'Instituciones',
                value: 'Gestión Total',
                color: colors.primary,
                onTap: () => context.go('/institutions'),
                isFirst: true,
              ),
              Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
              _buildMenuActionItem(
                context,
                icon: Icons.people_alt_rounded,
                label: 'Usuarios',
                value: 'Admins y Super Admins',
                color: colors.info,
                onTap: () => context.go('/users'),
              ),
              Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
              _buildMenuActionItem(
                context,
                icon: Icons.settings_outlined,
                label: 'Ajustes',
                value: 'Sistema',
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

  // Quick actions sidebar removed per request.

  // Large action cards removed per request; replaced by compact ListTiles above.
}