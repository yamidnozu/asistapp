import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/role_enum.dart';

/// Muestra o esconde widgets según el rol del usuario
/// 
/// Ejemplo:
/// ```dart
/// RoleGuard(
///   allowedRoles: [UserRole.profesor],
///   child: EditarButton(),
///   fallback: Text('No tienes permiso'),
/// )
/// ```
class RoleGuard extends StatelessWidget {
  final List<UserRole> allowedRoles; // Qué roles pueden ver esto
  final Widget child;                // Qué mostrar si tiene permiso
  final Widget? fallback;            // Qué mostrar si NO tiene permiso (opcional)

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRoleString = authProvider.user?['rol'] as String?;

    if (userRoleString == null) {
      return fallback ?? const SizedBox.shrink();
    }

    UserRole? userRole;
    try {
      userRole = UserRoleExtension.fromString(userRoleString);
    } catch (e) {
      return fallback ?? const SizedBox.shrink();
    }

    if (allowedRoles.contains(userRole)) {
      return child;
    } else {
      return fallback ?? const SizedBox.shrink();
    }
  }
}