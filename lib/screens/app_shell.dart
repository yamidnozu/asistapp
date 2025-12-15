import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart'; // Importar extensiones para el tema
// Colors via context.colors
import '../utils/responsive_utils.dart';
import '../widgets/components/command_palette.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late FocusNode _focusNode;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _appVersion = '-'; // Default fallback

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    // Agregar listener para capturar Ctrl+K globalmente
    _focusNode.addListener(_handleKeyboardShortcuts);

    // Obtener la versión de la app después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppVersion();
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleKeyboardShortcuts);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyboardShortcuts() {
    // Este método se puede ampliar para otros atajos
  }

  Future<void> _loadAppVersion() async {
    try {
      final pubspecContent = await rootBundle.loadString('pubspec.yaml');
      final versionRegex = RegExp(r'version:\s*([^\s]+)');
      final match = versionRegex.firstMatch(pubspecContent);
      if (match != null && match.groupCount >= 1) {
        final version = match.group(1)!;
        // Remover el +build si existe
        final cleanVersion = version.split('+').first;
        debugPrint('Versión obtenida del pubspec: $cleanVersion');
        if (mounted) {
          setState(() {
            _appVersion = cleanVersion;
          });
        }
      } else {
        debugPrint('No se encontró la versión en pubspec.yaml');
      }
    } catch (e) {
      // Mantener el valor por defecto si hay error
      debugPrint('Error obteniendo versión de la app: $e');
    }
  }

  void _showCommandPalette() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['rol'] as String?;

    // Crear items según el rol
    final items = _buildCommandPaletteItems(userRole);

    showDialog(
      context: context,
      builder: (context) => CommandPalette(
        items: items,
        onDismiss: () {
          FocusScope.of(context).requestFocus(_focusNode);
        },
      ),
    );
  }

  List<CommandPaletteItem> _buildCommandPaletteItems(String? userRole) {
    final items = <CommandPaletteItem>[
      // Navegación principal
      CommandPaletteItem(
        title: 'Ir a Dashboard',
        description: 'Abre el dashboard principal',
        icon: Icons.dashboard_rounded,
        shortcut: '⌘D',
        onExecute: () {
          context.go('/');
        },
      ),
    ];

    // Items específicos por rol
    if (userRole == 'super_admin') {
      items.addAll([
        CommandPaletteItem(
          title: 'Ir a Instituciones',
          description: 'Gestiona todas las instituciones',
          icon: Icons.business_rounded,
          shortcut: '⌘I',
          onExecute: () {
            context.go('/institutions');
          },
        ),
        CommandPaletteItem(
          title: 'Ir a Usuarios',
          description: 'Gestiona todos los usuarios',
          icon: Icons.people_alt_rounded,
          shortcut: '⌘U',
          onExecute: () {
            context.go('/users');
          },
        ),
      ]);
    }

    if (userRole == 'super_admin' || userRole == 'admin_institucion') {
      items.addAll([
        CommandPaletteItem(
          title: 'Crear Nueva Institución',
          description: 'Agrega una institución nueva',
          icon: Icons.add_business_rounded,
          onExecute: () {
            // Implementar según GoRouter config
          },
        ),
      ]);
    }

    // Acciones globales
    items.addAll([
      CommandPaletteItem(
        title: 'Cerrar Sesión',
        description: 'Cierra tu sesión actual',
        icon: Icons.logout_rounded,
        color: context.colors.error, // Rojo error con mejor contraste
        onExecute: () {
          Provider.of<AuthProvider>(context, listen: false).logout();
          context.go('/login');
        },
      ),
      CommandPaletteItem(
        title: 'Preferencias',
        description: 'Accede a la configuración',
        icon: Icons.settings_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          context.go('/settings');
        },
      ),
      CommandPaletteItem(
        title: 'Ayuda',
        description: 'Ver documentación y ayuda',
        icon: Icons.help_rounded,
        onExecute: () {
          // Implementar ayuda
        },
      ),
    ]);

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?['rol'] as String?;

    final allBranches = [
      (
        label: 'Dashboard',
        icon: Icons.dashboard_rounded,
        branchIndex: 0,
        roles: ['super_admin', 'admin_institucion', 'profesor', 'estudiante']
      ),
      (
        label: 'Instituciones',
        icon: Icons.business_rounded,
        branchIndex: 1,
        roles: ['super_admin']
      ),
      (
        label: 'Usuarios',
        icon: Icons.people_alt_rounded,
        branchIndex: 2,
        roles: ['super_admin', 'admin_institucion']
      ),
    ];

    final accessibleBranches =
        allBranches.where((branch) => branch.roles.contains(userRole)).toList();

    // Lógica para encontrar el índice seleccionado
    int selectedIndex = 0; // Default a 0
    if (accessibleBranches.isNotEmpty) {
      final currentBranchIndex = widget.navigationShell.currentIndex;
      final foundIndex = accessibleBranches
          .indexWhere((b) => b.branchIndex == currentBranchIndex);
      if (foundIndex != -1) {
        selectedIndex = foundIndex;
      }
    }

    // Nombre de la institución seleccionada (si aplica)
    final institutionName = authProvider.selectedInstitution?.name;

    // Usamos LayoutBuilder para decidir qué navegación mostrar
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        // Capturar Ctrl+K (Windows/Linux) o Cmd+K (Mac)
        if (HardwareKeyboard.instance
                .isLogicalKeyPressed(LogicalKeyboardKey.keyK) &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _showCommandPalette();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final responsive = ResponsiveUtils.getResponsiveValues(constraints);

          // Si no hay ramas accesibles, mostrar solo el contenido sin navegación
          if (accessibleBranches.isEmpty) {
            return Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                backgroundColor: context.colors.surface,
                elevation: 0,
                foregroundColor: context.colors.textPrimary,
                title: Text(institutionName != null
                    ? 'Dashboard — $institutionName'
                    : 'Dashboard'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings,
                        color: Theme.of(context).colorScheme.onSurface),
                    tooltip: 'Ajustes',
                    onPressed: () {
                      context.go('/settings');
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.logout, color: context.colors.error),
                    tooltip: 'Cerrar sesión',
                    onPressed: () async {
                      await authProvider.logoutAndClearAllData(context);
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
              body: widget.navigationShell,
            );
          }

          // Si no es móvil (tablet o escritorio), usamos NavigationRail
          if (!responsive['isMobile']) {
            return Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                backgroundColor: context.colors.surface,
                elevation: 0,
                foregroundColor: context.colors.textPrimary,
                title: Text(institutionName != null
                    ? '${accessibleBranches[selectedIndex].label} — $institutionName'
                    : accessibleBranches[selectedIndex].label),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings,
                        color: Theme.of(context).colorScheme.onSurface),
                    tooltip: 'Ajustes',
                    onPressed: () {
                      context.go('/settings');
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.logout, color: context.colors.error),
                    tooltip: 'Cerrar sesión',
                    onPressed: () async {
                      await authProvider.logoutAndClearAllData(context);
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
              body: Row(
                children: [
                  if (accessibleBranches.isNotEmpty)
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (index) {
                        final branchIndexToGo =
                            accessibleBranches[index].branchIndex;
                        widget.navigationShell.goBranch(branchIndexToGo,
                            initialLocation:
                                index == widget.navigationShell.currentIndex);
                      },
                      backgroundColor: context.colors.surface,
                      selectedIconTheme: IconThemeData(
                        color: context.colors.primary,
                        size: 24,
                      ),
                      unselectedIconTheme: IconThemeData(
                        color: context.colors.textMuted,
                        size: 24,
                      ),
                      selectedLabelTextStyle: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      unselectedLabelTextStyle: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 12,
                      ),
                      indicatorColor:
                          context.colors.primary.withValues(alpha: 0.15),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final branch in accessibleBranches)
                          NavigationRailDestination(
                            icon: Icon(branch.icon),
                            label: Text(branch.label),
                          ),
                      ],
                    ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: widget.navigationShell),
                ],
              ),
            );
          } else {
            // Si es móvil, NO usamos AppBar - los dashboards controlan su UI
            return Scaffold(
              key: _scaffoldKey,
              // Sin AppBar - diseño limpio controlado por cada dashboard
              drawer: Drawer(
                backgroundColor: context.colors.surface,
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      color: context.colors.primary,
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'Menú',
                        style: context.textStyles.headlineSmall.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          authProvider.logoutAndClearAllData(context).then((_) {
                            if (context.mounted) context.go('/login');
                          });
                        },
                        icon: Icon(Icons.logout, color: context.colors.white),
                        label: const Text('Cerrar Sesión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.error,
                          foregroundColor: context.colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/settings');
                        },
                        icon: Icon(Icons.settings,
                            color: Theme.of(context).colorScheme.onSurface),
                        label: Text('Ajustes',
                            style: context.textStyles.bodyMedium),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.surface,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: context.colors.border),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Versión $_appVersion',
                        style: context.textStyles.bodySmall.copyWith(
                          color: context.colors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              body: widget.navigationShell,
              bottomNavigationBar: accessibleBranches.length > 1
                  ? _buildFloatingNavBar(
                      context, accessibleBranches, selectedIndex)
                  : null, // No mostrar la barra si solo hay una opción
            );
          }
        },
      ),
    );
  }

  /// Barra de navegación flotante estilo píldora continua (Premium)
  /// Usa colores del tema para coherencia total.
  Widget _buildFloatingNavBar(
    BuildContext context,
    List<dynamic> branches,
    int selectedIndex,
  ) {
    // Usamos los colores del tema actual
    final colors = context.colors;
    // Fondo de la píldora: Usamos Surface (que se adapta a Light/Dark)
    // pero con alta opacidad para que flote bien sobre el contenido.
    final navBarColor = colors.surface;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: navBarColor,
            borderRadius: BorderRadius.circular(35), // Píldora completa
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15), // Sombra más sutil
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: branches.asMap().entries.map((entry) {
              final i = entry.key;
              final branch = entry.value;
              return _buildPremiumNavItem(
                context,
                icon: branch.icon,
                label: branch.label,
                isSelected: i == selectedIndex,
                onTap: () => _onTapNav(i, branches),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _onTapNav(int index, List<dynamic> branches) {
    widget.navigationShell.goBranch(
      branches[index].branchIndex,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  Widget _buildPremiumNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Colores dinámicos basados en el tema
    final colors = context.colors;
    final activeColor = colors.primary; // Azul/Violeta del tema
    final inactiveColor = colors.textMuted; // Gris suave

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono animado
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()
                ..translate(0.0, isSelected ? -2.0 : 0.0),
              child: Icon(
                icon,
                size: 26,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            // Etiqueta de texto animada
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.3,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Pequeño punto indicador si está seleccionado
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
