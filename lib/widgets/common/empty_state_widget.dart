import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colors.textMuted,
          ),
          SizedBox(height: spacing.lg),
          Text(
            title,
            style: textStyles.headlineMedium.withColor(colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.md),
          Text(
            message,
            style: textStyles.bodyMedium.withColor(colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}