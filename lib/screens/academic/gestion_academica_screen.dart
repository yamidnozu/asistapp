import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/components/index.dart';

class GestionAcademicaScreen extends StatelessWidget {
  const GestionAcademicaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.instance;
    final textStyles = AppTextStyles.instance;
    final spacing = AppSpacing.instance;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.white,
        elevation: 0,
        title: Text(
          'Gestión Académica',
          style: textStyles.headlineMedium.copyWith(color: colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Administrar Estructura Académica',
              style: textStyles.displayMedium,
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Gestiona grupos, materias y horarios de tu institución',
              style: textStyles.bodyLarge.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: spacing.xl),

            // Opciones del menú
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(spacing.borderRadius),
                border: Border.all(color: colors.borderLight),
              ),
              child: Column(
                children: [
                  _buildMenuOption(
                    context,
                    icon: Icons.group,
                    title: 'Gestionar Grupos',
                    subtitle: 'Crear y administrar grupos académicos',
                    color: colors.info,
                    onTap: () => context.push('/academic/grupos'),
                  ),
                  Divider(color: colors.borderLight),
                  _buildMenuOption(
                    context,
                    icon: Icons.book,
                    title: 'Gestionar Materias',
                    subtitle: 'Administrar catálogo de materias',
                    color: colors.warning,
                    onTap: () => context.push('/academic/materias'),
                  ),
                  Divider(color: colors.borderLight),
                  _buildMenuOption(
                    context,
                    icon: Icons.calendar_view_week,
                    title: 'Gestionar Horarios',
                    subtitle: 'Asignar clases y gestionar horarios',
                    color: colors.success,
                    onTap: () => context.push('/academic/horarios'),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacing.xxl),

            // Información adicional
            ClarityCard(
              leading: Icon(Icons.info_outline, color: colors.info),
              title: Text(
                'Información Importante',
                style: textStyles.headlineSmall,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Los grupos deben estar asociados a un periodo académico activo',
                    style: textStyles.bodyMedium,
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    '• Las materias pueden ser reutilizadas en diferentes horarios',
                    style: textStyles.bodyMedium,
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    '• Los horarios incluyen validación automática de conflictos',
                    style: textStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.instance;
    final textStyles = AppTextStyles.instance;
    final spacing = AppSpacing.instance;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: textStyles.headlineSmall),
      subtitle: Text(
        subtitle,
        style: textStyles.bodyMedium.copyWith(color: colors.textMuted),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: colors.textDisabled),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.md,
      ),
    );
  }
}