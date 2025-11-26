// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme_extensions.dart';

/// FASE 6: Command Palette - Búsqueda global con Ctrl+K
/// Proporciona acceso rápido a todas las rutas y acciones principales
class CommandPalette extends StatefulWidget {
  final List<CommandPaletteItem> items;
  final VoidCallback? onDismiss;

  const CommandPalette({
    super.key,
    required this.items,
    this.onDismiss,
  });

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  late List<CommandPaletteItem> _filteredItems;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
    
    // Focus en search input al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items
          .where((item) =>
              item.title.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query))
          .toList();
      _selectedIndex = 0;
    });
  }

  void _executeCommand() {
    if (_filteredItems.isNotEmpty && _selectedIndex < _filteredItems.length) {
      _filteredItems[_selectedIndex].onExecute();
      Navigator.of(context).pop();
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
  final colors = context.colors;
  final spacing = context.spacing;
  final textStyles = context.textStyles;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: spacing.xl),
        Container(
      constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(spacing.borderRadius),
              border: Border.all(color: colors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Input
                Padding(
                  padding: EdgeInsets.all(spacing.md),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (KeyEvent event) {
                      if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.escape)) {
                        Navigator.of(context).pop();
                        widget.onDismiss?.call();
                      } else if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowDown)) {
                        setState(() {
                          if (_selectedIndex < _filteredItems.length - 1) {
                            _selectedIndex++;
                          }
                        });
                      } else if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowUp)) {
                        setState(() {
                          if (_selectedIndex > 0) {
                            _selectedIndex--;
                          }
                        });
                      } else if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.enter)) {
                        _executeCommand();
                      }
                    },
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Escribe para buscar (Esc para cerrar)...',
                        prefixIcon: Icon(Icons.search, color: colors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(spacing.borderRadius),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(spacing.borderRadius),
                          borderSide: BorderSide(color: colors.primary, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: spacing.md,
                          vertical: spacing.sm,
                        ),
                      ),
                    ),
                  ),
                ),

                // Divider
                Divider(height: 1, color: colors.borderLight),

                // Results List
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: _filteredItems.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(spacing.lg),
                          child: Text(
                            'No se encontraron resultados',
                            style: textStyles.bodyMedium.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final isSelected = index == _selectedIndex;

                            return Material(
                              color: isSelected
                                  ? colors.primary.withValues(alpha: 0.1)
                                  : colors.surface,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                  _executeCommand();
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing.md,
                                    vertical: spacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        color: item.color ?? colors.primary,
                                        size: 18,
                                      ),
                                      SizedBox(width: spacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: textStyles.titleSmall
                                                  .copyWith(
                                                color: isSelected
                                                    ? colors.primary
                                                    : colors.textPrimary,
                                              ),
                                            ),
                                            if (item.description.isNotEmpty)
                                              Text(
                                                item.description,
                                                style: textStyles.bodySmall
                                                    .copyWith(
                                                  color: colors.textMuted,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: spacing.md),
                                      if (item.shortcut != null)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: spacing.xs,
                                            vertical: spacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.surfaceLight,
                                            borderRadius:
                                                BorderRadius.circular(
                                              spacing.borderRadius / 2,
                                            ),
                                            border: Border.all(
                                              color: colors.borderLight,
                                            ),
                                          ),
                                          child: Text(
                                            item.shortcut!,
                                            style: textStyles.labelSmall
                                                .copyWith(
                                              color: colors.textMuted,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          ),
          SizedBox(height: spacing.xl),
        ],
      ),
    );
  }
}

/// Data class para items del Command Palette
class CommandPaletteItem {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
  final String? shortcut; // ej: "Cmd+K", "Ctrl+A"
  final VoidCallback onExecute;

  CommandPaletteItem({
    required this.title,
    this.description = '',
    required this.icon,
    this.color,
    this.shortcut,
    required this.onExecute,
  });
}

/// Mixin para agregar Command Palette a app_shell.dart
mixin CommandPaletteMixin {
  static void showCommandPalette(BuildContext context, List<CommandPaletteItem> items) {
    showDialog(
      context: context,
      builder: (context) => CommandPalette(items: items),
    );
  }

  static void setupCommandPaletteShortcut(BuildContext context, List<CommandPaletteItem> items) {
    // Se puede usar aquí para setup global de Ctrl+K
    // Implementar en app_shell.dart o main.dart
  }
}
