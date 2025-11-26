import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Widget helper para navegación hacia atrás consistente en toda la app.
/// 
/// Comportamiento:
/// 1. Si hay historial de navegación (canPop), hace pop()
/// 2. Si no hay historial, navega a la ruta de fallback especificada
/// 3. Soporta tanto IconButton como Leading en AppBar
class BackNavigationButton extends StatelessWidget {
  /// Ruta de fallback si no se puede hacer pop (ej: '/dashboard')
  final String fallbackRoute;
  
  /// Color del icono (por defecto usa el foreground del AppBar)
  final Color? iconColor;
  
  /// Icono personalizado (por defecto es arrow_back)
  final IconData icon;
  
  /// Tooltip personalizado
  final String tooltip;

  const BackNavigationButton({
    super.key,
    required this.fallbackRoute,
    this.iconColor,
    this.icon = Icons.arrow_back,
    this.tooltip = 'Volver',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: iconColor),
      tooltip: tooltip,
      onPressed: () => _navigateBack(context),
    );
  }

  void _navigateBack(BuildContext context) {
    // Verificar si podemos hacer pop (hay historial de navegación)
    if (context.canPop()) {
      context.pop();
    } else {
      // Si no hay historial, ir a la ruta de fallback
      context.go(fallbackRoute);
    }
  }

  /// Método estático para usar directamente sin crear el widget
  static void navigateBack(BuildContext context, {String fallbackRoute = '/dashboard'}) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }
}

/// AppBar preconfigurado con navegación de retorno consistente
class AppBarWithBackNavigation extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String fallbackRoute;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? titleWidget;
  final bool centerTitle;

  const AppBarWithBackNavigation({
    super.key,
    required this.title,
    this.fallbackRoute = '/dashboard',
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.titleWidget,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.colorScheme.surface;
    final effectiveForegroundColor = foregroundColor ?? theme.colorScheme.onSurface;

    return AppBar(
      title: titleWidget ?? Text(
        title,
        style: TextStyle(color: effectiveForegroundColor),
      ),
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: 0,
      centerTitle: centerTitle,
      leading: BackNavigationButton(
        fallbackRoute: fallbackRoute,
        iconColor: effectiveForegroundColor,
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
