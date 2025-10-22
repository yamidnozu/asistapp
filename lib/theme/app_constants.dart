/// Constantes de UI específicas que no cambian con el tema
class AppConstants {
  // Constructor privado
  AppConstants._();

  // Instancia singleton
  static final AppConstants instance = AppConstants._();

  // === DIMENSIONES FIJAS ===
  final double logoSize = 80;
  final double maxScreenWidth = 400;
  final double spinnerSize = 20;
  final double buttonBorderRadius = 8;
  final double cardBorderRadius = 8;
  final double logoBorderRadius = 20;
  final double errorLoggerWidthCollapsed = 60;
  final double errorLoggerHeightCollapsed = 60;
  final double errorLoggerWidthExpanded = 300;
  final double errorLoggerHeightExpanded = 200;

  // === VALORES FIJOS ===
  final double defaultFontSize = 14;
  final double logoFontSize = 48;
  final double shadowBlurRadius = 8;
  final double shadowOffsetY = 2;
  final double errorLoggerShadowBlur = 8;
  final double errorLoggerShadowOffsetY = 4;
  final double borderWidthThin = 0.5;
  final double borderWidthNormal = 1;
  final double borderWidthThick = 1.5;

  // === OPACIDADES FIJAS ===
  final double shadowOpacity = 0.1; // 10% para sombras sutiles
  final double surfaceTintOpacity = 0.1;
}