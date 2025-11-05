import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/components/index.dart';
// responsive_utils removed — this dashboard uses responsive values from AppSpacing when needed

/// Dashboard mejorado con Clarity UI - Versión moderna y funcional
class ClarityAdminDashboard extends StatelessWidget {
  const ClarityAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final colors = AppColors.instance;
    final textStyles = AppTextStyles.instance;
    final spacing = AppSpacing.instance;

    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Usuario';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.white,
        elevation: 0,
        title: Text(
          'Panel de Administración',
          style: textStyles.headlineMedium.copyWith(color: colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await authProvider.logoutAndClearAllData(context);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {

          return SingleChildScrollView(
            padding: EdgeInsets.all(spacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ════════════════════════════════════════════════════════════════
                // SECCIÓN DE BIENVENIDA
                // ════════════════════════════════════════════════════════════════

                Text(
                  '¡Hola, $userName!',
                  style: textStyles.displayMedium,
                ),
                SizedBox(height: spacing.sm),
                Text(
                  'Aquí tienes un resumen de tu institución',
                  style: textStyles.bodyLarge.copyWith(color: colors.textSecondary),
                ),
                SizedBox(height: spacing.xl),

                // ════════════════════════════════════════════════════════════════
                // MÉTRICAS KPI - NUEVO EN CLARITY UI
                // ════════════════════════════════════════════════════════════════

                Text(
                  'Métricas Clave',
                  style: textStyles.headlineSmall,
                ),
                SizedBox(height: spacing.md),

                // Grid de KPIs
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                    final childAspectRatio = constraints.maxWidth > 600 ? 1.5 : 1.2;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: spacing.md,
                      mainAxisSpacing: spacing.md,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ClarityKPICard(
                          // Mostrar el total informado por la paginación del backend.
                          value: userProvider.totalUsersFromPagination.toString(),
                          label: 'Total Usuarios',
                          icon: Icons.people,
                          iconColor: colors.featureUsers,
                        ),
                        ClarityKPICard(
                          value: userProvider.activeUsersCount.toString(),
                          label: 'Usuarios Activos',
                          icon: Icons.check_circle,
                          iconColor: colors.success,
                        ),
                        ClarityKPICard(
                          value: userProvider.professorsCount.toString(),
                          label: 'Profesores',
                          icon: Icons.school,
                          iconColor: colors.featureClasses,
                        ),
                        ClarityKPICard(
                          value: userProvider.studentsCount.toString(),
                          label: 'Estudiantes',
                          icon: Icons.person,
                          iconColor: colors.featureStudents,
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: spacing.xxl),

                // ════════════════════════════════════════════════════════════════
                // ACCESOS DIRECTOS - REDISEÑADOS
                // ════════════════════════════════════════════════════════════════

                Text(
                  'Accesos Directos',
                  style: textStyles.headlineSmall,
                ),
                SizedBox(height: spacing.md),

                // Accesos directos: lista compacta para consistencia
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.people, color: colors.featureUsers),
                        title: Text('Gestionar Usuarios', style: textStyles.bodyLarge),
                        subtitle: Text('Crear, editar y administrar', style: textStyles.bodySmall.copyWith(color: colors.textMuted)),
                        onTap: () {},
                      ),
                      Divider(color: colors.borderLight),
                      ListTile(
                        leading: Icon(Icons.business, color: colors.featureInstitutions),
                        title: Text('Instituciones', style: textStyles.bodyLarge),
                        subtitle: Text('Administrar instituciones', style: textStyles.bodySmall.copyWith(color: colors.textMuted)),
                        onTap: () {},
                      ),
                      Divider(color: colors.borderLight),
                      ListTile(
                        leading: Icon(Icons.bar_chart, color: colors.featureReports),
                        title: Text('Reportes', style: textStyles.bodyLarge),
                        subtitle: Text('Estadísticas y análisis', style: textStyles.bodySmall.copyWith(color: colors.textMuted)),
                        onTap: () {},
                      ),
                      Divider(color: colors.borderLight),
                      ListTile(
                        leading: Icon(Icons.school, color: colors.featureClasses),
                        title: Text('Gestión Académica', style: textStyles.bodyLarge),
                        subtitle: Text('Grupos, materias y horarios', style: textStyles.bodySmall.copyWith(color: colors.textMuted)),
                        onTap: () {
                          context.push('/academic');
                        },
                      ),
                      Divider(color: colors.borderLight),
                      ListTile(
                        leading: Icon(Icons.settings, color: colors.featureSettings),
                        title: Text('Configuración', style: textStyles.bodyLarge),
                        subtitle: Text('Ajustes del sistema', style: textStyles.bodySmall.copyWith(color: colors.textMuted)),
                        onTap: () {},
                      ),
                      Divider(color: colors.borderLight),
                      ListTile(
                        leading: Icon(Icons.notifications, color: colors.featureNotifications),
                        title: Text('Notificaciones', style: textStyles.bodyLarge),
                        subtitle: Text('Centro de mensajes', style: textStyles.bodySmall.copyWith(color: colors.textMuted)),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing.xxl),

                // ════════════════════════════════════════════════════════════════
                // ACTIVIDAD RECIENTE - NUEVO EN CLARITY UI
                // ════════════════════════════════════════════════════════════════

                Text(
                  'Actividad Reciente',
                  style: textStyles.headlineSmall,
                ),
                SizedBox(height: spacing.md),

                // Lista de actividad reciente usando ClarityCard
                Column(
                  children: [
                    _buildActivityItem(
                      context,
                      icon: Icons.person_add,
                      title: 'Nuevo usuario registrado',
                      subtitle: 'María González se unió como estudiante',
                      time: 'Hace 2 horas',
                      color: colors.success,
                    ),
                    SizedBox(height: spacing.sm),
                    _buildActivityItem(
                      context,
                      icon: Icons.edit,
                      title: 'Perfil actualizado',
                      subtitle: 'Juan Pérez modificó su información',
                      time: 'Hace 4 horas',
                      color: colors.info,
                    ),
                    SizedBox(height: spacing.sm),
                    _buildActivityItem(
                      context,
                      icon: Icons.warning,
                      title: 'Usuario inactivo',
                      subtitle: 'Ana López no ha iniciado sesión en 30 días',
                      time: 'Hace 1 día',
                      color: colors.warning,
                    ),
                  ],
                ),

                SizedBox(height: spacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  // Quick access cards replaced by compact list for consistency across dashboards.

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    final colors = AppColors.instance;
    final textStyles = AppTextStyles.instance;
    final spacing = AppSpacing.instance;

    return ClarityCard(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: spacing.md),
      ),
      title: Text(
        title,
        style: textStyles.bodyMedium.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: textStyles.bodySmall.copyWith(color: colors.textMuted),
          ),
          SizedBox(height: spacing.xs),
          Text(
            time,
            style: textStyles.caption.copyWith(color: colors.textDisabled),
          ),
        ],
      ),
    );
  }
}