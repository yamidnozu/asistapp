import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scroll_state_provider.dart';

/// Widget que guarda y restaura automáticamente la posición de scroll
class ScrollStateKeeper extends StatefulWidget {
  final String routeKey;
  final Widget Function(BuildContext, ScrollController) builder;
  final bool keepScrollPosition;

  const ScrollStateKeeper({
    super.key,
    required this.routeKey,
    required this.builder,
    this.keepScrollPosition = true,
  });

  @override
  State<ScrollStateKeeper> createState() => _ScrollStateKeeperState();
}

class _ScrollStateKeeperState extends State<ScrollStateKeeper> {
  late final ScrollController _scrollController;
  bool _isRestoringPosition = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    if (widget.keepScrollPosition) {
      _restoreScrollPosition();
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Restaura la posición de scroll guardada
  void _restoreScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final scrollProvider = Provider.of<ScrollStateProvider>(
        context,
        listen: false,
      );
      
      final savedPosition = scrollProvider.getScrollPosition(widget.routeKey);
      
      if (savedPosition > 0 && _scrollController.hasClients) {
        _isRestoringPosition = true;
        _scrollController.jumpTo(savedPosition);
        _isRestoringPosition = false;
        debugPrint('Scroll restaurado para ${widget.routeKey}: $savedPosition');
      }
    });
  }

  /// Guarda la posición actual de scroll
  void _onScroll() {
    if (_isRestoringPosition || !_scrollController.hasClients) return;
    
    final scrollProvider = Provider.of<ScrollStateProvider>(
      context,
      listen: false,
    );
    
    final currentPosition = _scrollController.offset;
    scrollProvider.saveScrollPosition(widget.routeKey, currentPosition);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _scrollController);
  }
}

/// Mixin para pantallas StatefulWidget que necesiten mantener scroll
mixin ScrollStateMixin<T extends StatefulWidget> on State<T> {
  late final ScrollController scrollController;
  String get scrollRouteKey;
  
  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    _restoreAndListenScroll();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _restoreAndListenScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final scrollProvider = Provider.of<ScrollStateProvider>(
        context,
        listen: false,
      );
      
      final savedPosition = scrollProvider.getScrollPosition(scrollRouteKey);
      
      if (savedPosition > 0 && scrollController.hasClients) {
        scrollController.jumpTo(savedPosition);
      }
      
      scrollController.addListener(() {
        if (scrollController.hasClients) {
          scrollProvider.saveScrollPosition(
            scrollRouteKey,
            scrollController.offset,
          );
        }
      });
    });
  }
}
