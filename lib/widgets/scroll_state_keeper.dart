import 'package:flutter/material.dart';

/// Widget para mantener el estado del scroll entre navegación
class ScrollStateKeeper extends StatefulWidget {
  final String routeKey;
  final bool keepScrollPosition;
  final Widget Function(BuildContext, ScrollController) builder;

  const ScrollStateKeeper({
    super.key,
    required this.routeKey,
    this.keepScrollPosition = true,
    required this.builder,
  });

  @override
  State<ScrollStateKeeper> createState() => _ScrollStateKeeperState();
}

class _ScrollStateKeeperState extends State<ScrollStateKeeper> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _scrollController);
  }
}