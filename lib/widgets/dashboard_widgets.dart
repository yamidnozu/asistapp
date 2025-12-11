import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../config/app_constants.dart';
import '../theme/theme_extensions.dart';
import 'components/clarity_components.dart';

/// Widget reutilizable para las tarjetas de características en los dashboards
class DashboardFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Map<String, dynamic> responsive;
  final VoidCallback? onTap;

  const DashboardFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.responsive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = responsive['isDesktop'] as bool;
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return ClarityCard(
      onTap: onTap ??
          () {
            // PENDIENTE: Implementar navegación a la funcionalidad específica
          },
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isDesktop ? 48 : 32,
            color: color,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              title,
              style: textStyles.titleLarge.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        description,
        style: textStyles.bodyMedium.copyWith(
          color: colors.textSecondary,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      padding: EdgeInsets.all(isDesktop ? spacing.xl : spacing.lg),
    );
  }
}

/// Widget reutilizable para el saludo del usuario
class UserGreetingWidget extends StatelessWidget {
  final String userName;
  final Map<String, dynamic> responsive;
  final String? subtitle;

  const UserGreetingWidget({
    super.key,
    required this.userName,
    required this.responsive,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return ClarityCard(
      title: Text(
        '¡Hola, $userName!',
        style: textStyles.headlineMedium.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: textStyles.bodyLarge.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            )
          : null,
      padding: EdgeInsets.all(spacing.xl),
    );
  }
}

/// Widget reutilizable para las opciones del dashboard en grid
class DashboardOptionsGrid extends StatelessWidget {
  final List<DashboardFeatureCard> cards;
  final Map<String, dynamic> responsive;
  final bool verticalMode;

  const DashboardOptionsGrid({
    super.key,
    required this.cards,
    required this.responsive,
    this.verticalMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = responsive['screenType'] as ScreenType;

    if (verticalMode) {
      return Column(
        children: [
          const SizedBox(height: 32),
          Column(
            children: cards.map((card) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                  onTap: card.onTap,
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  leading: Icon(card.icon, color: card.color, size: 28),
                  title: Text(card.title, style: context.textStyles.bodyLarge),
                  subtitle: Text(card.description,
                      style: context.textStyles.bodySmall),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final gridDelegate =
                ResponsiveUtils.getResponsiveGridDelegate(screenType);

            return GridView(
              gridDelegate: gridDelegate,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: cards,
            );
          },
        ),
      ],
    );
  }
}

/// Widget reutilizable para el AppBar de los dashboards
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final List<Widget> actions;

  const DashboardAppBar({
    super.key,
    this.title = 'AsistApp',
    required this.backgroundColor,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Widget reutilizable para las acciones del AppBar
class DashboardAppBarActions extends StatelessWidget {
  final String userRole;
  final IconData roleIcon;
  final VoidCallback? onLogout;

  const DashboardAppBarActions({
    super.key,
    required this.userRole,
    required this.roleIcon,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          constraints:
              const BoxConstraints(maxWidth: 120), // Limitar ancho máximo
          decoration: BoxDecoration(
            color: colors.roleBadgeBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(roleIcon, size: 14, color: colors.roleBadgeIcon),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  userRole,
                  style: TextStyle(
                    color: colors.roleBadgeText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: onLogout ??
              () async {
                // PENDIENTE: Implementar cierre de sesión
              },
        ),
      ],
    );
  }
}

/// Widget reutilizable para el body base de los dashboards
class DashboardBody extends StatelessWidget {
  final Widget userGreeting;
  final Widget dashboardOptions;
  final Map<String, dynamic> responsive;

  const DashboardBody({
    super.key,
    required this.userGreeting,
    required this.dashboardOptions,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsive['maxWidth']),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive['horizontalPadding'],
                  vertical: responsive['verticalPadding'],
                ),
                child: Column(
                  children: [
                    userGreeting,
                    SizedBox(height: responsive['elementSpacing']),
                    dashboardOptions,
                    SizedBox(height: responsive['elementSpacing'] * 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
