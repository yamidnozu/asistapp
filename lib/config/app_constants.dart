/// Constantes globales de la aplicación
/// Unifica constantes de UI, lógica y configuración
class AppConstants {
  AppConstants._();

  static final AppConstants instance = AppConstants._();

  // ============================================================================
  // CONSTANTES DE CONFIGURACIÓN Y LÓGICA
  // ============================================================================

  /// Número de elementos por página en todas las paginaciones
  static const int itemsPerPage = 5;

  /// Timeout para las peticiones HTTP (en segundos)
  static const int httpTimeoutSeconds = 10;

  /// Número máximo de reintentos para operaciones fallidas
  static const int maxRetries = 3;

  // ============================================================================
  // CONSTANTES DE UI - BREAKPOINTS RESPONSIVE
  // ============================================================================

  // Breakpoints responsive
  final double mobileSmall = 480;
  final double mobileLarge = 768;
  final double tablet = 1024;
  final double desktop = 1440;

  // Anchos máximos por tipo de pantalla
  final double maxWidthMobile = 480;
  final double maxWidthTablet = 768;
  final double maxWidthDesktop = 1024;
  final double maxWidthLargeDesktop = 1400;

  // ============================================================================
  // CONSTANTES DE UI - TAMAÑOS Y DIMENSIONES
  // ============================================================================

  final double logoSize = 80;
  final double spinnerSize = 20;
  final double buttonBorderRadius = 8;
  final double cardBorderRadius = 8;
  final double logoBorderRadius = 20;
  final double errorLoggerWidthCollapsed = 60;
  final double errorLoggerHeightCollapsed = 60;
  final double errorLoggerWidthExpanded = 300;
  final double errorLoggerHeightExpanded = 200;

  // ============================================================================
  // CONSTANTES DE UI - TIPOGRAFÍA Y EFECTOS
  // ============================================================================

  final double defaultFontSize = 14;
  final double logoFontSize = 48;
  final double shadowBlurRadius = 8;
  final double shadowOffsetY = 2;
  final double errorLoggerShadowBlur = 8;
  final double errorLoggerShadowOffsetY = 4;
  final double borderWidthThin = 0.5;
  final double borderWidthNormal = 1;
  final double borderWidthThick = 1.5;

  final double shadowOpacity = 0.1; // 10% para sombras sutiles
  final double surfaceTintOpacity = 0.1;

  // ============================================================================
  // MÉTODOS ÚTILES
  // ============================================================================

  /// Método para obtener el ancho máximo según el tamaño de pantalla
  double getMaxWidth(double screenWidth) {
    if (screenWidth <= mobileSmall) return maxWidthMobile;
    if (screenWidth <= mobileLarge) return maxWidthTablet;
    if (screenWidth <= tablet) return maxWidthDesktop;
    return maxWidthLargeDesktop;
  }

  /// Método para determinar el tipo de pantalla
  ScreenType getScreenType(double width) {
    if (width <= mobileSmall) return ScreenType.mobileSmall;
    if (width <= mobileLarge) return ScreenType.mobileLarge;
    if (width <= tablet) return ScreenType.tablet;
    if (width <= desktop) return ScreenType.desktop;
    return ScreenType.largeDesktop;
  }
}

enum ScreenType {
  mobileSmall, // Pantallas pequeñas (móviles antiguos, <= 480px)
  mobileLarge, // Móviles grandes (481-768px)
  tablet, // Tablets (769-1024px)
  desktop, // Escritorio (1025-1440px)
  largeDesktop, // Pantallas grandes (> 1440px)
}
