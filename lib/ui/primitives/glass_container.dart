import 'package:flutter/widgets.dart';
import '../theme.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({super.key, required this.child, this.padding = const EdgeInsets.all(12)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ChronoTheme.glass(),
      padding: padding,
      child: child,
    );
  }
}