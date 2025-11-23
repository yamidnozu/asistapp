import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
// role_guard and role_enum removed — not required after replacing action list
import '../widgets/components/index.dart';

// Helper para construir acciones con estilo consistente (copiado de admin_dashboard)
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
                padding: EdgeInsets.all(8),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: textStyles.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Usuario';
  // selectedInstitution disponible en AuthProvider si es necesario

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // 1. Saludo Sutil
            Text('¡Hola, $userName!', style: textStyles.displayMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: spacing.sm),
            Text(
              'Bienvenido al panel estudiantil.',
              style: textStyles.bodyLarge.copyWith(color: colors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: spacing.xl),

            // 2. Barra de Estadísticas Adaptable (simplificada para estudiantes)
            _buildCompactStatsBar(context),

            SizedBox(height: spacing.xl),

            // 3. Acciones principales en lista compacta (estilo Admin)
            Text('Acciones Principales', style: textStyles.headlineSmall),
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
                    icon: Icons.qr_code_2_rounded,
                    label: 'Mi Código QR',
                    value: 'Para registrar asistencia',
                    color: colors.primary,
                    onTap: () => context.go('/student/qr'),
                    isFirst: true,
                  ),
                  Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
                  _buildMenuActionItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Mi Horario',
                    value: 'Ver mis clases',
                    color: const Color(0xFF06B6D4),
                    onTap: () => context.go('/student/schedule'),
                  ),
                  Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
                  _buildMenuActionItem(
                    context,
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Mi Asistencia',
                    value: 'Historial y estadísticas',
                    color: colors.success,
                    onTap: () => context.go('/student/attendance'),
                  ),
                  Divider(height: 0, indent: spacing.lg, endIndent: spacing.lg),
                  _buildMenuActionItem(
                    context,
                    icon: Icons.notifications_outlined,
                    label: 'Notificaciones',
                    value: 'Ver mensajes',
                    color: colors.warning,
                    onTap: () => context.go('/student/notifications'),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  // Widget para la nueva barra de estadísticas que se adapta
  Widget _buildCompactStatsBar(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        border: Border.all(color: colors.borderLight),
      ),
      child: SingleChildScrollView( // Permite scroll horizontal si no cabe
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ClarityCompactStat(
              value: '85%', // Placeholder - se puede conectar a datos reales
              title: 'Asistencia',
              icon: Icons.check_circle,
              color: colors.success,
            ),
            SizedBox(width: spacing.lg),
            ClarityCompactStat(
              value: '4.2', // Placeholder - se puede conectar a datos reales
              title: 'Promedio',
              icon: Icons.grade,
              color: colors.primary,
            ),
            SizedBox(width: spacing.lg),
            ClarityCompactStat(
              value: '12', // Placeholder - se puede conectar a datos reales
              title: 'Materias',
              icon: Icons.book,
              color: colors.info,
            ),
          ],
        ),
      ),
    );
  }

  // Large action cards removed — using compact ListTile layout instead.
}