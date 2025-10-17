import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class RouteGuards {
  /// Guard para rutas que requieren autenticación
  static bool requireAuth(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return authProvider.isAuthenticated;
  }

  /// Guard para rutas que requieren rol específico
  static bool requireRole(BuildContext context, String role) {
    final userProvider = context.read<UserProvider>();
    return userProvider.hasRole(role);
  }

  /// Guard para rutas solo de admin
  static bool requireAdmin(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    return userProvider.isAdmin();
  }

  /// Guard para rutas públicas (sin autenticación)
  static bool isPublic(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return !authProvider.isAuthenticated;
  }
}

/// Widget de protección para rutas
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final bool Function(BuildContext) guard;
  final Widget fallback;

  const ProtectedRoute({
    required this.child,
    required this.guard,
    required this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return guard(context) ? child : fallback;
  }
}
