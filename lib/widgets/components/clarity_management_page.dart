// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme_extensions.dart';
import 'clarity_components.dart';

/// Widget reutilizable para pantallas de gestión/listado
/// 
/// Proporciona una estructura consistente con:
/// - AppBar con título y estadísticas
/// - Filtros (búsqueda, chips, etc.)
/// - Lista con scroll infinito
/// - Estados de carga, error y vacío
/// - Pull to refresh
/// - Floating action button opcional
class ClarityManagementPage extends StatelessWidget {
  /// Título de la página mostrado en el AppBar
  final String title;
  
  /// Indica si los datos están cargando
  final bool isLoading;
  
  /// Indica si hay un error
  final bool hasError;
  
  /// Mensaje de error a mostrar
  final String? errorMessage;
  
  /// Número total de items en la lista
  final int itemCount;
  
  /// Constructor para cada item de la lista
  final Widget Function(BuildContext, int) itemBuilder;
  
  /// Widgets de filtro (buscador, chips, etc.)
  final List<Widget>? filterWidgets;
  
  /// Widgets de estadísticas para el AppBar
  final List<Widget>? statisticWidgets;
  
  /// Callback para refresh
  final Future<void> Function()? onRefresh;
  
  /// Floating action button opcional
  final Widget? floatingActionButton;
  
  /// Controller del scroll para paginación infinita
  final ScrollController? scrollController;
  
  /// Indica si hay más datos para cargar
  final bool hasMoreData;
  
  /// Indica si se están cargando más datos
  final bool isLoadingMore;
  
  /// Widget para estado vacío
  final Widget? emptyStateWidget;
  
  /// Widget para estado de error
  final Widget? errorStateWidget;
  
  /// Espaciado entre items de la lista
  final double? itemSpacing;
  
  /// Color de fondo de la página
  final Color? backgroundColor;

  /// Ruta de navegación de retorno (si se proporciona, muestra botón de volver)
  final String? backRoute;

  /// Widget leading personalizado para el AppBar
  final Widget? leading;
  
  /// Si mostrar automáticamente el botón leading de Flutter (false si usamos backRoute)
  final bool automaticallyImplyLeading;

  const ClarityManagementPage({
    super.key,
    required this.title,
    required this.isLoading,
    required this.hasError,
    required this.itemCount,
    required this.itemBuilder,
    this.errorMessage,
    this.filterWidgets,
    this.statisticWidgets,
    this.onRefresh,
    this.floatingActionButton,
    this.scrollController,
    this.hasMoreData = false,
    this.isLoadingMore = false,
    this.emptyStateWidget,
    this.errorStateWidget,
    this.itemSpacing,
    this.backgroundColor,
    this.backRoute,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
  final colors = context.colors;
  final spacing = context.spacing;
  final textStyles = context.textStyles;

  // Determinar el widget leading
  Widget? effectiveLeading = leading;
  if (effectiveLeading == null && backRoute != null) {
    effectiveLeading = IconButton(
      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
      tooltip: 'Volver',
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(backRoute!);
        }
      },
    );
  }

    return Scaffold(
      backgroundColor: backgroundColor ?? colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: effectiveLeading,
        automaticallyImplyLeading: effectiveLeading == null && automaticallyImplyLeading,
        title: Text(title, style: textStyles.headlineMedium),
        centerTitle: false,
        // ▼▼▼ ELIMINAMOS LOS ACTIONS DE AQUÍ ▼▼▼
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            // ▼▼▼ AÑADIMOS LAS ESTADÍSTICAS Y FILTROS AQUÍ ▼▼▼
            SliverToBoxAdapter(
              child: Container(
                color: colors.surface,
                padding: EdgeInsets.all(spacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (statisticWidgets != null && statisticWidgets!.isNotEmpty) ...[
                      // Usamos Wrap para que sea responsivo
                      Wrap(
                        spacing: spacing.lg,
                        runSpacing: spacing.md,
                        alignment: WrapAlignment.center,
                        children: statisticWidgets!,
                      ),
                      SizedBox(height: spacing.lg),
                    ],
                    if (filterWidgets != null && filterWidgets!.isNotEmpty)
                      ...filterWidgets!,
                  ],
                ),
              ),
            ),

            // Estados de carga, error o vacío
            if (isLoading && itemCount == 0)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (hasError)
              SliverFillRemaining(
                child: errorStateWidget ??
                    ClarityEmptyState(
                      icon: Icons.error_outline,
                      title: 'Error al cargar datos',
                      subtitle: errorMessage ?? 'Error desconocido',
                      action: onRefresh != null
                          ? ElevatedButton.icon(
                              onPressed: onRefresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            )
                          : null,
                    ),
              )
            else if (itemCount == 0)
              SliverFillRemaining(
                child: emptyStateWidget ??
                    ClarityEmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No hay elementos',
                      subtitle: 'Comienza agregando tu primer elemento',
                    ),
              )
            else
              // Lista de items
              SliverPadding(
                padding: EdgeInsets.all(spacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Último item: mostrar indicador de carga si hay más datos
                      if (index >= itemCount) {
                        if (hasMoreData && !isLoadingMore) {
                          // Trigger load more automáticamente
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            // El callback debe ser manejado por el padre
                          });
                        }
                        return isLoadingMore
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(spacing.md),
                                  child: const CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      // Item normal
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: itemSpacing ?? spacing.md,
                        ),
                        child: itemBuilder(context, index),
                      );
                    },
                    childCount: itemCount + (hasMoreData ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
