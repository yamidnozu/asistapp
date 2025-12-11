/// Sistema de espaciado escalable y consistente
class AppSpacing {
  AppSpacing._();
  static final AppSpacing instance = AppSpacing._();
  static const double _baseUnit = 4;
  final double xs = _baseUnit; // 4
  final double sm = _baseUnit * 2; // 8
  final double md = _baseUnit * 4; // 16
  final double lg = _baseUnit * 6; // 24
  final double xl = _baseUnit * 8; // 32
  final double xxl = _baseUnit * 12; // 48
  final double xxxl = _baseUnit * 16; // 64
  final double buttonPadding = _baseUnit * 4; // 16
  final double cardPadding = _baseUnit * 3; // 12 - Padding en tarjetas
  final double screenPadding = _baseUnit * 4; // 16 - Padding global
  final double inputPadding = _baseUnit * 3; // 12
  final double iconSize = _baseUnit * 6; // 24
  final double borderRadius = _baseUnit * 2; // 8 - Border radius estándar
  final double borderRadiusLarge =
      _baseUnit * 3; // 12 - Border radius en chips o botones
  final double appBarHeight = _baseUnit * 14; // 56 - Altura de AppBar
  final double borderWidth = 1; // 1 - Ancho de borde estándar
  double multiply(double factor) => _baseUnit * factor;
  double add(double value) => _baseUnit + value;
}
