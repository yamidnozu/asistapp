import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_state_provider.dart';

/// Mixin para agregar persistencia automática de estado a cualquier StatefulWidget
/// Uso: class MyScreen extends StatefulWidget with NavigationStateMixin
mixin NavigationStateMixin<T extends StatefulWidget> on State<T> {
  String get currentRoute;
  Map<String, dynamic>? get routeArguments => null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveCurrentState();
    });
  }

  @override
  void dispose() {
    _refreshStateTimestamp();
    super.dispose();
  }

  /// Guarda el estado actual de navegación
  void _saveCurrentState() {
    final navigationProvider = Provider.of<NavigationStateProvider>(
      context,
      listen: false,
    );
    navigationProvider.saveNavigationState(currentRoute, arguments: routeArguments);
  }

  /// Actualiza solo el timestamp sin cambiar la ruta
  void _refreshStateTimestamp() {
    final navigationProvider = Provider.of<NavigationStateProvider>(
      context,
      listen: false,
    );
    navigationProvider.refreshStateTimestamp();
  }

  /// Método para llamar manualmente cuando cambia el estado
  void updateNavigationState({Map<String, dynamic>? arguments}) {
    final navigationProvider = Provider.of<NavigationStateProvider>(
      context,
      listen: false,
    );
    navigationProvider.saveNavigationState(currentRoute, arguments: arguments);
  }
}

/// Widget wrapper para pantallas Stateless que necesiten guardar estado
class NavigationStateWrapper extends StatefulWidget {
  final Widget child;
  final String route;
  final Map<String, dynamic>? arguments;

  const NavigationStateWrapper({
    super.key,
    required this.child,
    required this.route,
    this.arguments,
  });

  @override
  State<NavigationStateWrapper> createState() => _NavigationStateWrapperState();
}

class _NavigationStateWrapperState extends State<NavigationStateWrapper>
    with NavigationStateMixin {
  @override
  String get currentRoute => widget.route;

  @override
  Map<String, dynamic>? get routeArguments => widget.arguments;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
