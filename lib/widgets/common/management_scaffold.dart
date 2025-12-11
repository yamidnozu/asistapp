import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/user.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/shimmer_list_widget.dart';
import '../../widgets/pagination_widget.dart';

class ManagementScaffold extends StatelessWidget {
  final String title;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final bool hasMoreData;
  final VoidCallback onRefresh;
  final ScrollController scrollController;
  final Widget? floatingActionButton;
  final List<Widget>? filterWidgets;
  final List<Widget>? statisticWidgets;
  final PaginationInfo? paginationInfo;
  final Future<void> Function(int) onPageChange;
  final String? emptyStateTitle;
  final String? emptyStateMessage;
  final IconData emptyStateIcon;

  const ManagementScaffold({
    super.key,
    required this.title,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.itemCount,
    required this.itemBuilder,
    required this.hasMoreData,
    required this.onRefresh,
    required this.scrollController,
    this.floatingActionButton,
    this.filterWidgets,
    this.statisticWidgets,
    this.paginationInfo,
    required this.onPageChange,
    this.emptyStateTitle,
    this.emptyStateMessage,
    this.emptyStateIcon = Icons.business,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(title,
            style: textStyles.headlineMedium.copyWith(color: colors.surface)),
        backgroundColor: colors.primary,
        elevation: 2,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filtros
            if (filterWidgets != null && filterWidgets!.isNotEmpty)
              Card(
                margin: EdgeInsets.symmetric(
                    horizontal: spacing.lg, vertical: spacing.md),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.borderRadius),
                ),
                child: ExpansionTile(
                  title:
                      Text('Filtros y Búsqueda', style: textStyles.titleMedium),
                  children: [
                    Material(
                      color: colors.surface,
                      child: Padding(
                        padding: EdgeInsets.all(spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: filterWidgets!,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Estadísticas
            if (statisticWidgets != null && statisticWidgets!.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: spacing.lg),
                padding: EdgeInsets.symmetric(
                    horizontal: spacing.md, vertical: spacing.sm),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(spacing.borderRadius),
                  border: Border.all(color: colors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: statisticWidgets!,
                ),
              ),

            // Lista
            Expanded(
              child: _buildListContent(context),
            ),

            // Paginación
            if (paginationInfo != null)
              PaginationWidget(
                currentPage: paginationInfo!.page,
                totalPages: paginationInfo!.totalPages,
                totalItems: paginationInfo!.total,
                onPageChange: onPageChange,
                isLoading: isLoading,
              ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildListContent(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;
    if (isLoading && itemCount == 0) {
      return ShimmerListWidget(
        itemCount: 5,
        cardBuilder: (context) => _buildShimmerCard(context),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            SizedBox(height: spacing.lg),
            Text(
              'Error al cargar datos',
              style: textStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.md),
            Text(
              errorMessage,
              style: textStyles.bodyMedium.withColor(colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.lg),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.lg,
                  vertical: spacing.md,
                ),
              ),
              child: Text('Reintentar', style: textStyles.button),
            ),
          ],
        ),
      );
    }

    if (itemCount == 0) {
      return EmptyStateWidget(
        icon: emptyStateIcon,
        title: emptyStateTitle ?? 'No hay elementos',
        message: emptyStateMessage ?? 'Comienza creando tu primer elemento',
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.symmetric(horizontal: spacing.lg),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: itemBuilder(context, index),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    final spacing = context.spacing;
    return Card(
      margin: EdgeInsets.only(bottom: spacing.xs),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.borderRadius),
      ),
      child: const ListTile(
        leading: CircleAvatar(),
        title: SizedBox(height: 16),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            SizedBox(height: 12),
          ],
        ),
        trailing: SizedBox(width: 24, height: 24),
      ),
    );
  }
}
