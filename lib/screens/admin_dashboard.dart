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
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Usuario';
  // selectedInstitution se obtiene del AuthProvider cuando se necesite en el UI

    // Obtener estadísticas desde el provider
    final stats = userProvider.getUserStatistics();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: colors.background,
          // AppBar centralizado en AppShell; este Scaffold mantiene solo el body
          body: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Saludo Sutil
                Text('¡Hola, $userName!', style: textStyles.displayMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: spacing.sm),
                Text(
                  'Bienvenido al panel de administración.',
                  style: textStyles.bodyLarge.copyWith(color: colors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: spacing.xl),

                // 2. Barra de Estadísticas Adaptable (usa stats map)
                _buildCompactStatsBar(context, stats, userProvider, constraints),

                SizedBox(height: spacing.xl),
                // 3. Nueva fila: KPIs + Actividad reciente
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 800;
                    return isNarrow
                        ? Column(
                            children: [
                              _buildKpiRow(context, userProvider),
                              SizedBox(height: spacing.md),
                              _buildRecentActivity(context, userProvider),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildKpiRow(context, userProvider)),
                              SizedBox(width: spacing.md),
                              SizedBox(width: 420, child: _buildRecentActivity(context, userProvider)),
                            ],
                          );
                  },
                ),

                // 3. Acciones Principales - Menú Elegante Vertical
                Text('Acciones Principales', style: textStyles.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                        value: stats['total']?.toString() ?? '0',
                        color: colors.primary,
                        onTap: () => context.go('/users'),
                        isFirst: true,
                      ),
                      Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
                      _buildMenuActionItem(
                        context,
                        icon: Icons.school_outlined,
                        label: 'Gestión Académica',
                        value: 'Grupos & Materias',
                        color: const Color(0xFF10B981),
                        onTap: () => context.go('/academic'),
                      ),
                      Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
                      _buildMenuActionItem(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Horarios',
                        value: 'Gestión',
                        color: const Color(0xFF06B6D4),
                        onTap: () {},
                      ),
                      Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
                      _buildMenuActionItem(
                        context,
                        icon: Icons.settings_outlined,
                        label: 'Ajustes',
                        value: 'Config',
                        color: const Color(0xFF8B5CF6),
                        onTap: () {},
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget para la nueva barra de estadísticas
  Widget _buildCompactStatsBar(BuildContext context, Map<String, int> stats, UserProvider userProvider, BoxConstraints constraints) {
    final colors = context.colors;
    final spacing = context.spacing;

    // Si el ancho es pequeño, usar layout vertical
    final isSmallScreen = constraints.maxWidth < 400;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        border: Border.all(color: colors.borderLight),
      ),
      child: isSmallScreen
          ? Column(
              children: [
                ClarityCompactStat(
                  value: stats['total']?.toString() ?? '0',
                  title: 'Usuarios',
                  icon: Icons.people,
                  color: colors.primary,
                ),
                SizedBox(height: spacing.md),
                ClarityCompactStat(
                  value: stats['profesores']?.toString() ?? userProvider.professorsCount.toString(),
                  title: 'Profesores',
                  icon: Icons.school,
                  color: colors.info,
                ),
                SizedBox(height: spacing.md),
                ClarityCompactStat(
                  value: stats['estudiantes']?.toString() ?? userProvider.studentsCount.toString(),
                  title: 'Estudiantes',
                  icon: Icons.person,
                  color: colors.warning,
                ),
              ],
            )
          : SingleChildScrollView( // Permite scroll horizontal si no cabe
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 'Usuarios' debe reflejar el total informado por la paginación del backend.
                  ClarityCompactStat(
                    value: stats['total']?.toString() ?? '0',
                    title: 'Usuarios',
                    icon: Icons.people,
                    color: colors.primary,
                  ),
                  SizedBox(width: spacing.lg),
                  // 'Profesores' y 'Estudiantes' actualmente reflejan solo la página cargada.
                  // Para una solución completa se requiere agregar endpoints que devuelvan los totales por rol en el backend.
                  ClarityCompactStat(
                    value: stats['profesores']?.toString() ?? userProvider.professorsCount.toString(),
                    title: 'Profesores',
                    icon: Icons.school,
                    color: colors.info,
                  ),
                  SizedBox(width: spacing.lg),
                  ClarityCompactStat(
                    value: stats['estudiantes']?.toString() ?? userProvider.studentsCount.toString(),
                    title: 'Estudiantes',
                    icon: Icons.person,
                    color: colors.warning,
                  ),
                ],
              ),
            ),
    );
  }

  // Widget para item del menú de acciones
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
              // Icono con fondo circular
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: spacing.md),
              // Texto principal y valor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
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
              // Icono de flecha
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: context.colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            Column(
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
        ],
      ),
    );
  }
}