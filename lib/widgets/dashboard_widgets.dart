import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../theme/app_constants.dart';

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
    final bodyFontSize = responsive['bodyFontSize'] as double;
    final isDesktop = responsive['isDesktop'] as bool;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap ?? () {
          // TODO: Implementar navegación a la funcionalidad específica
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: SizedBox(
            height: isDesktop ? 140 : 120, // Altura fija para evitar overflow
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: isDesktop ? 48 : 32,
                  color: color,
                ),
                SizedBox(height: isDesktop ? 12 : 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isDesktop ? 6 : 4),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: bodyFontSize * 0.9,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    final titleFontSize = responsive['titleFontSize'] as double;
    final subtitleFontSize = responsive['subtitleFontSize'] as double;

    return Column(
      children: [
        Text(
          'Hola, $userName',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Widget reutilizable para las opciones del dashboard en grid
class DashboardOptionsGrid extends StatelessWidget {
  final List<DashboardFeatureCard> cards;
  final Map<String, dynamic> responsive;

  const DashboardOptionsGrid({
    super.key,
    required this.cards,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = responsive['screenType'] as ScreenType;

    return Column(
      children: [
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final gridDelegate = ResponsiveUtils.getResponsiveGridDelegate(screenType);

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          constraints: const BoxConstraints(maxWidth: 120), // Limitar ancho máximo
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(roleIcon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  userRole,
                  style: const TextStyle(
                    color: Colors.white,
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
          onPressed: onLogout ?? () async {
            // TODO: Implement logout
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