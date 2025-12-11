import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../config/app_constants.dart';

/// Callback cuando se solicita cambiar de página
typedef OnPageChangeCallback = Future<void> Function(int page);

/// Widget reutilizable de paginación
///
/// Uso:
/// ```dart
/// PaginationWidget(
///   currentPage: 1,
///   totalPages: 10,
///   totalItems: 100,
///   onPageChange: (page) async {
///     await provider.loadPage(page);
///   },
/// )
/// ```
class PaginationWidget extends StatelessWidget {
  /// Página actual (1-indexed)
  final int currentPage;

  /// Total de páginas disponibles
  final int totalPages;

  /// Total de items en la paginación
  final int totalItems;

  /// Callback cuando cambia la página
  final OnPageChangeCallback onPageChange;

  /// Si está cargando, deshabilita botones
  final bool isLoading;

  /// Máximo de botones de página a mostrar
  final int maxPageButtons;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.onPageChange,
    this.isLoading = false,
    this.maxPageButtons = 5,
  });

  bool get _canGoPrevious => currentPage > 1;
  bool get _canGoNext => currentPage < totalPages;
  bool get _showPagination => totalPages > 1;

  Future<void> _handlePageChange(int page) async {
    if (page != currentPage && page >= 1 && page <= totalPages) {
      await onPageChange(page);
    }
  }

  List<int> _getVisiblePages() {
    final pages = <int>[];

    if (totalPages <= maxPageButtons) {
      // Mostrar todas las páginas si hay pocas
      pages.addAll(List.generate(totalPages, (i) => i + 1));
    } else {
      // Lógica inteligente de rango
      if (currentPage <= maxPageButtons ~/ 2 + 1) {
        // En el inicio: mostrar primeras maxPageButtons páginas
        pages.addAll(List.generate(maxPageButtons, (i) => i + 1));
      } else if (currentPage >= totalPages - maxPageButtons ~/ 2) {
        // En el final: mostrar últimas maxPageButtons páginas
        pages.addAll(List.generate(
          maxPageButtons,
          (i) => totalPages - maxPageButtons + i + 1,
        ));
      } else {
        // En el medio: mostrar página actual ± (maxPageButtons ~/ 2)
        final center = maxPageButtons ~/ 2;
        pages.addAll(List.generate(
          maxPageButtons,
          (i) => currentPage - center + i,
        ));
      }
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    if (!_showPagination) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Container(
      margin:
          EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.textMuted.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con información de página
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: spacing.md, vertical: spacing.sm),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 16,
                  color: colors.primary,
                ),
                SizedBox(width: spacing.xs),
                Text(
                  'Página $currentPage de $totalPages',
                  style: textStyles.bodyMedium.bold
                      .copyWith(color: colors.primary),
                ),
                SizedBox(width: spacing.sm),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: spacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalItems items',
                    style: textStyles.bodySmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selector de página con números
                _buildPageSelector(colors, spacing, textStyles),

                SizedBox(height: spacing.md),

                // Botones de navegación
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón Primera Página
                    _buildNavigationButton(
                      icon: Icons.first_page,
                      label: 'Primera',
                      enabled: _canGoPrevious && !isLoading,
                      onPressed: () => _handlePageChange(1),
                      colors: colors,
                      spacing: spacing,
                      textStyles: textStyles,
                      compact: true,
                    ),

                    SizedBox(width: spacing.sm),

                    // Botón Anterior
                    _buildNavigationButton(
                      icon: Icons.chevron_left,
                      label: 'Anterior',
                      enabled: _canGoPrevious && !isLoading,
                      onPressed: () => _handlePageChange(currentPage - 1),
                      colors: colors,
                      spacing: spacing,
                      textStyles: textStyles,
                    ),

                    SizedBox(width: spacing.md),

                    // Botón Siguiente
                    _buildNavigationButton(
                      icon: Icons.chevron_right,
                      label: 'Siguiente',
                      enabled: _canGoNext && !isLoading,
                      onPressed: () => _handlePageChange(currentPage + 1),
                      colors: colors,
                      spacing: spacing,
                      textStyles: textStyles,
                      iconOnRight: true,
                    ),

                    SizedBox(width: spacing.sm),

                    // Botón Última Página
                    _buildNavigationButton(
                      icon: Icons.last_page,
                      label: 'Última',
                      enabled: _canGoNext && !isLoading,
                      onPressed: () => _handlePageChange(totalPages),
                      colors: colors,
                      spacing: spacing,
                      textStyles: textStyles,
                      iconOnRight: true,
                      compact: true,
                    ),
                  ],
                ),

                // Indicador de carga
                if (isLoading) ...[
                  SizedBox(height: spacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(colors.primary),
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      Text(
                        'Cargando...',
                        style: textStyles.bodySmall
                            .copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
    required AppColors colors,
    required AppSpacing spacing,
    required AppTextStyles textStyles,
    bool iconOnRight = false,
    bool compact = false,
  }) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          disabledBackgroundColor: colors.borderLight,
          foregroundColor: colors.getTextColorForBackground(colors.primary),
          disabledForegroundColor: colors.textMuted,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? spacing.sm : spacing.md,
            vertical: spacing.sm,
          ),
          elevation: enabled ? 2 : 0,
          shadowColor: colors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            colors
                .getTextColorForBackground(colors.primary)
                .withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!iconOnRight) ...[
              Icon(icon, size: 18),
              if (!compact) SizedBox(width: spacing.xs),
            ],
            if (!compact)
              Text(
                label,
                style: textStyles.bodySmall.bold,
              ),
            if (iconOnRight) ...[
              if (!compact) SizedBox(width: spacing.xs),
              Icon(icon, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPageSelector(
      AppColors colors, AppSpacing spacing, AppTextStyles textStyles) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final pages = _getVisiblePages();

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
      decoration: BoxDecoration(
        color: colors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderLight.withValues(alpha: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < pages.length; i++) ...[
              _buildPageButton(
                pageNumber: pages[i],
                isCurrentPage: pages[i] == currentPage,
                colors: colors,
                spacing: spacing,
                textStyles: textStyles,
              ),
              if (i != pages.length - 1) SizedBox(width: spacing.xs / 2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required int pageNumber,
    required bool isCurrentPage,
    required AppColors colors,
    required AppSpacing spacing,
    required AppTextStyles textStyles,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: !isLoading && !isCurrentPage
            ? () => _handlePageChange(pageNumber)
            : null,
        borderRadius: BorderRadius.circular(8),
        splashColor: colors.primary.withValues(alpha: 0.1),
        highlightColor: colors.primary.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.sm,
            vertical: spacing.xs,
          ),
          decoration: BoxDecoration(
            color: isCurrentPage ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentPage
                  ? colors.primary
                  : colors.borderLight.withValues(alpha: 0.3),
              width: isCurrentPage ? 2 : 1,
            ),
            boxShadow: isCurrentPage
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$pageNumber',
              style: textStyles.bodyMedium.copyWith(
                color: isCurrentPage
                    ? colors.getTextColorForBackground(colors.primary)
                    : colors.textSecondary,
                fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modelo para estado de paginación
/// Usar con ChangeNotifier o Provider
class PaginationState {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool isLoading;

  PaginationState({
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.itemsPerPage = AppConstants.itemsPerPage,
    this.isLoading = false,
  });

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
  bool get isFirstPage => currentPage == 1;
  bool get isLastPage => currentPage == totalPages;

  /// Crear nueva instancia con cambios
  PaginationState copyWith({
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? itemsPerPage,
    bool? isLoading,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() =>
      'PaginationState(page: $currentPage/$totalPages, items: $totalItems, perPage: $itemsPerPage)';
}
