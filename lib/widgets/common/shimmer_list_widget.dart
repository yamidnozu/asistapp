import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/theme_extensions.dart';

class ShimmerListWidget extends StatelessWidget {
  final Widget Function(BuildContext) cardBuilder;
  final int itemCount;

  const ShimmerListWidget({
    super.key,
    required this.cardBuilder,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Shimmer.fromColors(
      baseColor: colors.surface,
      highlightColor: colors.borderLight,
      child: ListView.builder(
        padding:
            EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.sm),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return cardBuilder(context);
        },
      ),
    );
  }
}
