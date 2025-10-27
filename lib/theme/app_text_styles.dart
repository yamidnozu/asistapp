import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Sistema de estilos de texto escalable y mantenible
class AppTextStyles {
  AppTextStyles._();
  static final AppTextStyles instance = AppTextStyles._();
  TextStyle _createStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required double letterSpacing,
    Color? color,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.instance.textPrimary,
      decoration: decoration,
    );
  }
  TextStyle get displayLarge => _createStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0.4,
  );

  TextStyle get displayMedium => _createStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.25,
    letterSpacing: 0.36,
  );
  TextStyle get headlineLarge => _createStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.35,
  );

  TextStyle get headlineMedium => _createStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.25,
  );
  TextStyle get titleLarge => _createStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.41,
  );

  TextStyle get titleMedium => _createStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: -0.24,
  );
  TextStyle get bodyLarge => _createStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.47,
    letterSpacing: -0.41,
    color: AppColors.instance.textPrimary,
  );

  TextStyle get bodyMedium => _createStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.47,
    letterSpacing: -0.24,
    color: AppColors.instance.textPrimary,
  );

  TextStyle get bodySmall => _createStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.38,
    letterSpacing: -0.08,
    color: AppColors.instance.textMuted,
  );
  TextStyle get labelLarge => _createStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: -0.5,
  );

  TextStyle get labelMedium => _createStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.38,
    letterSpacing: -0.08,
    color: AppColors.instance.textSecondary,
  );

  TextStyle get labelSmall => _createStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.36,
    letterSpacing: 0.06,
    color: AppColors.instance.textMuted,
  );
  TextStyle get button => labelLarge.copyWith(
    color: null, // Usar foregroundColor del botón
  );

  TextStyle get caption => bodySmall.copyWith(
    fontSize: 12,
  );

  TextStyle get overline => labelSmall.copyWith(
    fontSize: 10,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w500,
  );
  TextStyle withColor(Color color) => _createStyle(
    fontSize: 15, // default
    fontWeight: FontWeight.normal,
    height: 1.4,
    letterSpacing: 0,
    color: color,
  );

  TextStyle withWeight(FontWeight weight) => _createStyle(
    fontSize: 15, // default
    fontWeight: weight,
    height: 1.4,
    letterSpacing: 0,
  );

  TextStyle withSize(double size) => _createStyle(
    fontSize: size,
    fontWeight: FontWeight.normal,
    height: 1.4,
    letterSpacing: 0,
  );
}