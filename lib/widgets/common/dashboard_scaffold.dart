import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';

class DashboardActionItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  DashboardActionItem({required this.icon, required this.label, this.onTap});
}

class DashboardScaffold extends StatelessWidget {
  final String userName;
  final String subtitle;
  final List<Widget>? statsWidgets;
  final Widget? kpiWidget;
  final Widget? recentActivityWidget;
  final List<DashboardActionItem>? actionItems;

  const DashboardScaffold({
    super.key,
    required this.userName,
    required this.subtitle,
    this.statsWidgets,
    this.kpiWidget,
    this.recentActivityWidget,
    this.actionItems,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¡Hola, $userName!', style: textStyles.displayMedium),
          SizedBox(height: spacing.sm),
          Text(subtitle, style: textStyles.bodyLarge),
          SizedBox(height: spacing.xl),

          if (statsWidgets != null && statsWidgets!.isNotEmpty) ...[
            Wrap(spacing: spacing.md, runSpacing: spacing.md, children: statsWidgets!),
            SizedBox(height: spacing.xl),
          ],

          if (kpiWidget != null || recentActivityWidget != null)
            LayoutBuilder(builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              if (isNarrow) {
                return Column(children: [if (kpiWidget != null) kpiWidget!, if (recentActivityWidget != null) SizedBox(height: spacing.md), if (recentActivityWidget != null) recentActivityWidget!]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [if (kpiWidget != null) Expanded(child: kpiWidget!), if (kpiWidget != null) SizedBox(width: spacing.md), if (recentActivityWidget != null) SizedBox(width: 420, child: recentActivityWidget!)]);
            }),

          SizedBox(height: spacing.xl),

          if (actionItems != null && actionItems!.isNotEmpty) ...[
            Text('Acciones Principales', style: textStyles.headlineSmall),
            SizedBox(height: spacing.md),
            // Wrap the action list in a Material so ListTile has a Material ancestor during tests & usages
            Material(
              type: MaterialType.transparency,
              child: Column(children: actionItems!.map((ai) => ListTile(leading: Icon(ai.icon), title: Text(ai.label), onTap: ai.onTap)).toList()),
            ),
          ],
        ],
      ),
    );
  }
}
