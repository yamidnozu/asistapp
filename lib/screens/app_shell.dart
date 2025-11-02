import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?['rol'] as String?;

    // 1. Define todas las ramas disponibles con sus configuraciones
    final allBranches = [
      (label: 'Dashboard', icon: Icons.dashboard, branchIndex: 0, roles: ['super_admin', 'admin_institucion', 'profesor', 'estudiante']),
      (label: 'Instituciones', icon: Icons.business, branchIndex: 1, roles: ['super_admin']),
      (label: 'Usuarios', icon: Icons.people, branchIndex: 2, roles: ['super_admin', 'admin_institucion']),
    ];

    // 2. Filtra las ramas a las que el usuario tiene acceso
    final accessibleBranches = allBranches.where((branch) => branch.roles.contains(userRole)).toList();

    // 3. Encuentra el índice actual en la lista filtrada
    // Puede ocurrir que `accessibleBranches` esté vacío (usuario sin rutas en el shell).
    // NavigationRail acepta `selectedIndex` nulo, así que usamos `int?` y manejamos el caso vacío.
    int? selectedIndex;
    if (accessibleBranches.isNotEmpty) {
      selectedIndex = accessibleBranches.indexWhere((b) => b.branchIndex == navigationShell.currentIndex);
      if (selectedIndex == -1) {
        // No se encontró la rama actual dentro de las accesibles -> fallback al primero
        selectedIndex = 0;
      }
    }

    return Scaffold(
      body: Row(
        children: [
          // Si no hay ramas accesibles mostramos un placeholder (sin NavigationRail) para evitar
          // pasar un `selectedIndex` fuera de rango.
          if (accessibleBranches.isNotEmpty)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                // Navega usando el branchIndex de la rama seleccionada
                final branchIndex = accessibleBranches[index].branchIndex;
                navigationShell.goBranch(branchIndex);
              },
              labelType: NavigationRailLabelType.all,
              destinations: [
                // 4. Construye los destinos a partir de la lista filtrada
                for (final branch in accessibleBranches)
                  NavigationRailDestination(
                    icon: Icon(branch.icon),
                    selectedIcon: Icon(branch.icon), // Puedes cambiar a outlined si tienes íconos diferentes
                    label: Text(branch.label),
                  ),
              ],
            )
          else
            // Mantener el layout pero sin rail: un ancho fijo vacío para que la UI no salte
            const SizedBox(width: 0),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: navigationShell,
          ),
        ],
      ),
    );
  }
}