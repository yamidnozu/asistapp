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
    int selectedIndex = 0; // Default to first (dashboard)

    // Buscar el índice basado en la rama actual
    for (int i = 0; i < accessibleBranches.length; i++) {
      if (accessibleBranches[i].branchIndex == navigationShell.currentIndex) {
        selectedIndex = i;
        break;
      }
    }

    // Asegurar que selectedIndex esté dentro del rango válido
    if (selectedIndex >= accessibleBranches.length) {
      selectedIndex = 0; // Fallback to first accessible branch
    }

    return Scaffold(
      body: Row(
        children: [
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
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: navigationShell,
          ),
        ],
      ),
    );
  }
}