import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Extensiones para acceder fácilmente al theme desde BuildContext
extension ThemeExtensions on BuildContext {
  /// Acceso rápido a colores del theme
  AppColors get colors => AppColors.fromBrightness(Theme.of(this).brightness);
  
  /// Return theme-aware colors (light/dark) based on Theme's brightness
  AppColors get themeColors => AppColors.fromBrightness(Theme.of(this).brightness);

  /// Acceso rápido a estilos de texto
  AppTextStyles get textStyles => AppTextStyles.instance;

  /// Acceso rápido a espaciado
  AppSpacing get spacing => AppSpacing.instance;

  /// Theme data actual
  ThemeData get theme => Theme.of(this);

  /// Text theme actual
  TextTheme get textTheme => theme.textTheme;

  /// Color scheme actual
  ColorScheme get colorScheme => theme.colorScheme;
}

/// Extensiones para TextStyle para facilitar modificaciones
extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get regular => copyWith(fontWeight: FontWeight.normal);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);
  TextStyle get underlined => copyWith(decoration: TextDecoration.underline);
  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);
}

/// Extensiones para EdgeInsets para espaciado consistente
extension EdgeInsetsExtensions on EdgeInsets {
  static EdgeInsets get xs => EdgeInsets.all(AppSpacing.instance.xs);
  static EdgeInsets get sm => EdgeInsets.all(AppSpacing.instance.sm);
  static EdgeInsets get md => EdgeInsets.all(AppSpacing.instance.md);
  static EdgeInsets get lg => EdgeInsets.all(AppSpacing.instance.lg);
  static EdgeInsets get xl => EdgeInsets.all(AppSpacing.instance.xl);

  static EdgeInsets horizontal(double value) => EdgeInsets.symmetric(horizontal: value);
  static EdgeInsets vertical(double value) => EdgeInsets.symmetric(vertical: value);

  static EdgeInsets get cardPadding => EdgeInsets.all(AppSpacing.instance.cardPadding);
  static EdgeInsets get screenPadding => EdgeInsets.all(AppSpacing.instance.screenPadding);
  static EdgeInsets get buttonPadding => EdgeInsets.symmetric(
    horizontal: AppSpacing.instance.buttonPadding,
    vertical: AppSpacing.instance.sm,
  );
}