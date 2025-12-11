import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';

/// Componente base para tarjetas con información rica - Clarity UI
class ClarityCard extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? elevation;

  const ClarityCard({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Card(
      color: backgroundColor ?? colors.surface,
      elevation: elevation ?? 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        side: BorderSide(color: colors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        child: Padding(
          padding: padding ?? EdgeInsets.all(spacing.cardPadding),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Alinear verticalmente al centro
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: spacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) title!,
                    if (subtitle != null && title != null)
                      SizedBox(height: spacing.xs),
                    if (subtitle != null) subtitle!,
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: spacing.md),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Componente para mostrar métricas/KPI en dashboards
class ClarityKPICard extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ClarityKPICard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Card(
      color: backgroundColor ?? colors.surface,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        side: BorderSide(color: colors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: iconColor ?? colors.primary,
                      size: spacing.iconSize,
                    ),
                    SizedBox(width: spacing.md),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      style: textStyles.kpiNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.sm),
              Text(
                label.toUpperCase(),
                style: textStyles.kpiLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Componente para mostrar estados (activo, inactivo, etc.)
class ClarityStatusBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const ClarityStatusBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    // Nuevo estilo: fondo neutro, pequeño indicador de icono a la izquierda y texto en estilo sutil.
    final indicatorColor = textColor ?? backgroundColor ?? colors.primary;
    final bg = backgroundColor ?? colors.surfaceLight;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs - 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(spacing.borderRadiusLarge),
        border: Border.all(
          color: colors.borderLight,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de icono pequeño
          Icon(
            text == 'Activo' ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: indicatorColor,
          ),
          SizedBox(width: spacing.xs),
          Text(
            text,
            style: textStyles.statusText.copyWith(
              color: colors.textPrimary,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// Componente para botones de acción en listas
class ClarityActionButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;

  const ClarityActionButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return IconButton(
      icon: Icon(
        icon,
        color: color ?? colors.primary,
        size: size ?? spacing.iconSize,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: spacing.iconSize,
        minHeight: spacing.iconSize,
      ),
    );
  }
}

/// Componente para secciones con título y contenido
class ClaritySection extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final TextStyle? titleStyle;

  const ClaritySection({
    super.key,
    required this.title,
    required this.child,
    this.padding,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Padding(
      padding: padding ?? EdgeInsets.all(spacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: titleStyle ?? textStyles.headlineMedium,
          ),
          SizedBox(height: spacing.md),
          child,
        ],
      ),
    );
  }
}

/// Componente para mostrar información vacía
class ClarityEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? action;

  const ClarityEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: spacing.xxl,
              color: colors.textMuted,
            ),
            SizedBox(height: spacing.lg),
            Text(
              title,
              style: textStyles.headlineMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: spacing.md),
              Text(
                subtitle!,
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: spacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget compacto para mostrar estadísticas en AppBars
class ClarityCompactStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ClarityCompactStat({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              '$value $title',
              style: textStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NUEVOS COMPONENTES - FASES 1-5 DEL REDISEÑO
// ═══════════════════════════════════════════════════════════════════════════

/// FASE 5: Componente de Header Funcional para Páginas de Gestión
/// Incluye: Título, Botón +Crear, Búsqueda, Filtros
class ClarityManagementHeader extends StatelessWidget {
  final String title;
  final String? searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onCreatePressed;
  final String? createButtonLabel;
  final List<Widget>? filterWidgets;
  final bool showSearch;
  final bool showCreateButton;

  const ClarityManagementHeader({
    super.key,
    required this.title,
    this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.onCreatePressed,
    this.createButtonLabel,
    this.filterWidgets,
    this.showSearch = true,
    this.showCreateButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Título + Botón Crear
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: textStyles.headlineMedium,
              ),
            ),
            if (showCreateButton && onCreatePressed != null)
              ElevatedButton.icon(
                onPressed: onCreatePressed,
                icon: const Icon(Icons.add),
                label: Text(createButtonLabel ?? 'Crear'),
              ),
          ],
        ),

        SizedBox(height: spacing.md),

        // Fila 2: Búsqueda
        if (showSearch) ...[
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint ?? 'Buscar...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController?.text.isNotEmpty == true
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController?.clear();
                        onSearchChanged?.call('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.borderRadius),
                borderSide: BorderSide(color: colors.border),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: spacing.md,
                vertical: spacing.sm,
              ),
            ),
          ),
          SizedBox(height: spacing.md),
        ],

        // Fila 3: Filtros
        if (filterWidgets != null && filterWidgets!.isNotEmpty)
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: filterWidgets!,
          ),
      ],
    );
  }
}

/// FASE 4: Componente para Botón de Menú Contextual (+3 acciones)
/// Simplifica UI agrupando acciones en PopupMenuButton
class ClarityContextMenu extends StatelessWidget {
  final List<ClarityContextMenuAction> actions;
  final IconData icon;
  final Color? iconColor;
  final String? tooltip;

  const ClarityContextMenu({
    super.key,
    required this.actions,
    this.icon = Icons.more_vert,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return PopupMenuButton<int>(
      icon: Icon(
        icon,
        color: iconColor ?? colors.primary,
        size: spacing.iconSize,
      ),
      tooltip: tooltip ?? 'Mostrar menú',
      onSelected: (index) {
        if (index < actions.length) {
          actions[index].onPressed?.call();
        }
      },
      itemBuilder: (context) => actions.asMap().entries.map((entry) {
        final action = entry.value;
        return PopupMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Icon(action.icon, size: 18, color: action.color),
              const SizedBox(width: 12),
              Text(action.label),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Data class para acciones en menú contextual
class ClarityContextMenuAction {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onPressed;

  ClarityContextMenuAction({
    required this.label,
    required this.icon,
    this.color,
    this.onPressed,
  });
}

/// FASE 3: Widget Responsive Wrapper con Max-Width y Transición de Layout
/// Detecta breakpoints y adapta layout automáticamente
class ClarityResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool centerContent;
  final EdgeInsetsGeometry? padding;

  const ClarityResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.centerContent = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determinar max-width según el ancho disponible
        final responsiveMaxWidth = maxWidth ??
            (constraints.maxWidth > 1200
                ? 1200.0
                : constraints.maxWidth > 768
                    ? 900.0
                    : double.infinity);

        final responsivePadding = padding ??
            EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 768 ? spacing.lg : spacing.md,
              vertical: spacing.md,
            );

        final content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsiveMaxWidth),
          child: child,
        );

        return Container(
          width: double.infinity,
          padding: responsivePadding,
          alignment: centerContent ? Alignment.center : Alignment.topLeft,
          child: content,
        );
      },
    );
  }
}

/// FASE 1: Componente Base de Lista Responsiva
/// Combina ClarityCard con menú contextual para listas densas
class ClarityListItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final List<ClarityContextMenuAction>? contextActions;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final String? badgeText;
  final Color? badgeColor;

  const ClarityListItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.contextActions,
    this.onTap,
    this.backgroundColor,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return ClarityCard(
      backgroundColor: backgroundColor,
      onTap: onTap,
      leading: leading,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitleWidget != null) ...[
            SizedBox(height: spacing.xs),
            DefaultTextStyle(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ) ??
                  const TextStyle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: subtitleWidget!,
            ),
          ] else if (subtitle != null) ...[
            SizedBox(height: spacing.xs),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeText != null) ...[
            ClarityStatusBadge(
              text: badgeText!,
              backgroundColor: badgeColor,
            ),
            SizedBox(width: spacing.sm),
          ],
          if (contextActions != null && contextActions!.isNotEmpty)
            ClarityContextMenu(actions: contextActions!),
        ],
      ),
    );
  }
}

/// FASE 2: Componente para Mostrar Información de Accesibilidad/Contraste
/// Asegura WCAG AA compliance con indicador visual
class ClarityAccessibilityIndicator extends StatelessWidget {
  final double contrastRatio; // 4.5 = AA, 7 = AAA
  final String label;

  const ClarityAccessibilityIndicator({
    super.key,
    required this.contrastRatio,
    required this.label,
  });

  bool get isCompliantAA => contrastRatio >= 4.5;
  bool get isCompliantAAA => contrastRatio >= 7.0;

  Color get complianceColor => isCompliantAAA
      ? Colors.green
      : isCompliantAA
          ? Colors.orange
          : Colors.red;

  String get complianceText => isCompliantAAA
      ? 'AAA'
      : isCompliantAA
          ? 'AA'
          : 'No Cumple';

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: complianceColor.withValues(alpha: 0.1),
        border: Border.all(color: complianceColor, width: 1),
        borderRadius: BorderRadius.circular(spacing.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: complianceColor),
          SizedBox(width: spacing.xs),
          Text(
            '$label ($complianceText: ${contrastRatio.toStringAsFixed(1)}:1)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: complianceColor,
                ),
          ),
        ],
      ),
    );
  }
}
