import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';

/// Pantalla de Ajustes del Sistema para Super Admin
/// Permite configurar preferencias de la aplicación
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;
    final authProvider = Provider.of<AuthProvider>(context);
    final isSuperAdmin = authProvider.user?['rol'] == 'super_admin';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'Ajustes del Sistema',
          style: textStyles.titleLarge.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'Apariencia', Icons.palette_outlined),
                SizedBox(height: spacing.md),
                _buildAppearanceSection(context, settings),
                SizedBox(height: spacing.md),

                if (isSuperAdmin) ...[
                  SizedBox(height: spacing.xl),
                  _buildSectionHeader(context, 'Desarrollo', Icons.developer_mode_outlined),
                  SizedBox(height: spacing.md),
                  _buildDevelopmentSection(context, settings),
                  SizedBox(height: spacing.md),
                  Text(
                    'Opciones para facilitar las pruebas durante el desarrollo.',
                    style: textStyles.bodySmall.copyWith(color: colors.textMuted),
                  ),
                ],
                SizedBox(height: spacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(spacing.sm),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        SizedBox(width: spacing.md),
        Text(
          title,
          style: textStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        children: children,
      ),
    );
  }



  Widget _buildAppearanceSection(BuildContext context, SettingsProvider settings) {
    return _buildSettingsCard(
      context,
      children: [
        _buildSwitchTile(
          context,
          title: 'Tema Oscuro',
          subtitle: 'Usar el tema oscuro de la aplicación',
          value: settings.isDarkMode,
          onChanged: (_) => settings.toggleDarkMode(),
          icon: settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        ),
        // Only theme toggle is visible for now per requirement
      ],
    );
  }

  Widget _buildDevelopmentSection(BuildContext context, SettingsProvider settings) {
    return _buildSettingsCard(
      context,
      children: [
        _buildSwitchTile(
          context,
          title: 'Mostrar Usuarios de Prueba',
          subtitle: 'Habilita la visualización de usuarios de prueba en la pantalla de login',
          value: settings.showTestUsers,
          onChanged: (_) => settings.setShowTestUsers(!settings.showTestUsers),
          icon: Icons.bug_report_outlined,
        ),
      ],
    );
  }

  // Other advanced settings sections removed — only appearance toggle kept for now

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
      child: Row(
        children: [
          Icon(icon, color: colors.textSecondary, size: 22),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  subtitle,
                  style: textStyles.bodySmall.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colors.primary,
          ),
        ],
      ),
    );
  }

  

  

  // Divider helper removed (not needed for single toggle screen)

  // Info and reset helpers removed — only appearance setting remains visible for now
}
