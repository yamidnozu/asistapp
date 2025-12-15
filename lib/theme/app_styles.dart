import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ESTILOS DE UI - BASADOS EN LOS MOCKUPS DEL MANUAL
/// Este archivo centraliza los estilos visuales para mantener consistencia
/// ═══════════════════════════════════════════════════════════════════════════

class AppStyles {
  AppStyles._();
  static final AppStyles instance = AppStyles._();

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTES - Colores extraídos de los mockups
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gradiente primario para headers (azul oscuro a azul claro)
  static LinearGradient get headerGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E3A8A), // Blue 900
          Color(0xFF3B82F6), // Blue 500
        ],
      );

  /// Gradiente para el login (más oscuro)
  static LinearGradient get loginGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F172A), // Slate 900
          Color(0xFF1E40AF), // Blue 800
          Color(0xFF3B82F6), // Blue 500
        ],
      );

  /// Gradientes para action cards (basados en mockups)
  static LinearGradient get actionCardCyan => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      );

  static LinearGradient get actionCardPurple => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      );

  static LinearGradient get actionCardGreen => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      );

  static LinearGradient get actionCardOrange => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      );

  static LinearGradient get actionCardSlate => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF64748B), Color(0xFF475569)],
      );

  static LinearGradient get actionCardIndigo => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORACIONES DE HEADER - Estilo de los dashboards
  // ═══════════════════════════════════════════════════════════════════════════

  /// Decoración del header con gradiente y esquinas redondeadas inferiores
  static BoxDecoration headerDecoration(AppColors colors) => BoxDecoration(
        gradient: headerGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORACIONES DE CARDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card blanca con sombra suave (KPIs dentro del header)
  static BoxDecoration kpiCardDecoration(AppColors colors) => BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Card con gradiente para acciones
  static BoxDecoration actionCardDecoration(LinearGradient gradient) =>
      BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  /// Card de lista con sombra sutil
  static BoxDecoration listCardDecoration(AppColors colors) => BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORACIONES DE AVATARES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Avatar con borde blanco (para headers con fondo oscuro)
  static BoxDecoration avatarOnDarkDecoration({double size = 56}) =>
      BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
      );

  /// Avatar con fondo de color (para fondos claros)
  static BoxDecoration avatarOnLightDecoration(Color color) => BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORACIONES DE ICONOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Contenedor de icono con fondo semitransparente (en cards con gradiente)
  static BoxDecoration iconContainerOnGradient() => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      );

  /// Contenedor de icono con fondo de color (en cards blancas)
  static BoxDecoration iconContainerOnLight(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORACIONES DE BADGES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Badge de estado activo
  static BoxDecoration activeBadgeDecoration() => BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      );

  /// Badge de estado inactivo
  static BoxDecoration inactiveBadgeDecoration() => BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      );

  /// Badge genérico con color
  static BoxDecoration badgeDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORACIONES DE CAMPOS DE TEXTO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Campo de búsqueda con fondo claro
  static BoxDecoration searchFieldDecoration(AppColors colors) => BoxDecoration(
        color: colors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      );

  /// Campo de búsqueda en header oscuro
  static BoxDecoration searchOnDarkDecoration() => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTES DE TAMAÑO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Radio de borde estándar para cards
  static const double cardBorderRadius = 16.0;

  /// Radio de borde para headers
  static const double headerBorderRadius = 28.0;

  /// Radio de borde para action cards
  static const double actionCardBorderRadius = 20.0;

  /// Radio de borde para badges
  static const double badgeBorderRadius = 20.0;

  /// Radio de borde para campos de texto
  static const double inputBorderRadius = 12.0;

  /// Tamaño de avatar en headers
  static const double headerAvatarSize = 56.0;

  /// Tamaño de icono en action cards
  static const double actionIconSize = 28.0;

  /// Tamaño de contenedor de icono en action cards
  static const double iconContainerSize = 48.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORACIONES PARA DASHBOARD RESUMEN CARD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Decoración de la card de resumen en dashboards
  static BoxDecoration dashboardResumenDecoration(Color primaryColor) =>
      BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Decoración del contenedor de stats dentro del resumen
  static BoxDecoration statsContainerDecoration() => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(inputBorderRadius),
      );

  /// Decoración de las action cards en la lista
  static BoxDecoration actionListCardDecoration(AppColors colors) =>
      BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS REUTILIZABLES BASADOS EN LOS MOCKUPS
// ═══════════════════════════════════════════════════════════════════════════

/// Header con gradiente estilo mockups del manual
class GradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GradientHeader({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppStyles.headerGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppStyles.headerBorderRadius),
          bottomRight: Radius.circular(AppStyles.headerBorderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding ?? EdgeInsets.all(AppSpacing.instance.lg),
          child: child,
        ),
      ),
    );
  }
}

/// Avatar para headers con fondo oscuro
class HeaderAvatar extends StatelessWidget {
  final IconData icon;
  final double size;

  const HeaderAvatar({
    super.key,
    required this.icon,
    this.size = AppStyles.headerAvatarSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: AppStyles.avatarOnDarkDecoration(size: size),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

/// Card de KPI para mostrar dentro del header
class KPICard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const KPICard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.instance.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: AppStyles.iconContainerOnLight(color),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: AppSpacing.instance.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de acción con gradiente
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppStyles.actionCardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppStyles.actionCardBorderRadius),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.instance.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: AppStyles.iconContainerSize,
                  height: AppStyles.iconContainerSize,
                  decoration: AppStyles.iconContainerOnGradient(),
                  child: Icon(icon,
                      color: Colors.white, size: AppStyles.actionIconSize),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge de estado
class StatusBadge extends StatelessWidget {
  final String text;
  final bool isActive;
  final Color? customColor;

  const StatusBadge({
    super.key,
    required this.text,
    this.isActive = true,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = customColor ??
        (isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.instance.sm,
        vertical: AppSpacing.instance.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppStyles.badgeBorderRadius),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Card de resumen para dashboards - Widget centralizado
class DashboardResumenCard extends StatelessWidget {
  final IconData icon;
  final String greeting;
  final String subtitle;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onRefreshPressed;
  final List<DashboardStatItem> stats;

  const DashboardResumenCard({
    super.key,
    required this.icon,
    required this.greeting,
    required this.subtitle,
    this.onMenuPressed,
    this.onRefreshPressed,
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.fromBrightness(Theme.of(context).brightness);
    final spacing = AppSpacing.instance;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: AppStyles.dashboardResumenDecoration(colors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Botón de menú
              if (onMenuPressed != null)
                IconButton(
                  onPressed: onMenuPressed,
                  icon: const Icon(Icons.menu, color: Colors.white),
                  tooltip: 'Menú',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (onMenuPressed != null) SizedBox(width: spacing.sm),
              // Avatar
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                radius: 20,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              SizedBox(width: spacing.md),
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Botón de refresh
              if (onRefreshPressed != null)
                IconButton(
                  onPressed: onRefreshPressed,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Actualizar',
                ),
            ],
          ),
          if (stats.isNotEmpty) ...[
            SizedBox(height: spacing.md),
            Container(
              padding: EdgeInsets.all(spacing.sm),
              decoration: AppStyles.statsContainerDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int i = 0; i < stats.length; i++) ...[
                    if (i > 0)
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    stats[i],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Item de estadística para el DashboardResumenCard
class DashboardStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  const DashboardStatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: valueColor ?? Colors.white, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Card de acción para lista de menú en dashboards
class MenuActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const MenuActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.fromBrightness(Theme.of(context).brightness);
    final spacing = AppSpacing.instance;

    return Container(
      margin: EdgeInsets.only(bottom: spacing.sm),
      decoration: AppStyles.actionListCardDecoration(colors),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppStyles.cardBorderRadius),
          child: Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  child: Icon(icon, color: colors.primary, size: 20),
                ),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
