import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Sistema de estilos de texto moderno - "Clarity UI"
/// Tipografía escalable, accesible y profesional con Inter
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

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPLAY - TÍTULOS GRANDES Y HEROES
  // ═══════════════════════════════════════════════════════════════════════════

  TextStyle get displayLarge => _createStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold para impacto
    height: 1.2,
    letterSpacing: -0.5, // Letter spacing negativo para títulos grandes
  );

  TextStyle get displayMedium => _createStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADLINE - TÍTULOS PRINCIPALES
  // ═══════════════════════════════════════════════════════════════════════════

  TextStyle get headlineLarge => _createStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600, // SemiBold para jerarquía
    height: 1.3,
    letterSpacing: -0.3,
  );

  TextStyle get headlineMedium => _createStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
  );

  TextStyle get headlineSmall => _createStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.1,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TITLE - SUBTÍTULOS Y ENCABEZADOS
  // ═══════════════════════════════════════════════════════════════════════════

  TextStyle get titleLarge => _createStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.0,
  );

  TextStyle get titleMedium => _createStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500, // Medium para subtítulos
    height: 1.5,
    letterSpacing: 0.0,
  );

  TextStyle get titleSmall => _createStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.1,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY - TEXTO PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════

  TextStyle get bodyLarge => _createStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular para legibilidad
    height: 1.5,
    letterSpacing: 0.1,
    color: AppColors.instance.textPrimary,
  );

  TextStyle get bodyMedium => _createStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
    color: AppColors.instance.textPrimary,
  );

  TextStyle get bodySmall => _createStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
    color: AppColors.instance.textMuted,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LABEL - TEXTO PARA BOTONES Y ETIQUETAS
  // ═══════════════════════════════════════════════════════════════════════════

  TextStyle get labelLarge => _createStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600, // SemiBold para botones
    height: 1.4,
    letterSpacing: 0.1,
    color: AppColors.instance.textSecondary,
  );

  TextStyle get labelMedium => _createStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
    color: AppColors.instance.textSecondary,
  );

  TextStyle get labelSmall => _createStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppColors.instance.textMuted,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTILOS ESPECIALES - CLARITY UI
  // ═══════════════════════════════════════════════════════════════════════════

  // Botones - optimizado para claridad
  TextStyle get button => labelLarge.copyWith(
    color: null, // Usar foregroundColor del botón
    letterSpacing: 0.2, // Mejor legibilidad en botones
  );

  // Texto de navegación
  TextStyle get navigation => labelMedium.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  // Texto de navegación activo
  TextStyle get navigationActive => navigation.copyWith(
    fontWeight: FontWeight.w600,
    color: AppColors.instance.primary,
  );

  // Texto de navegación inactivo
  TextStyle get navigationInactive => navigation.copyWith(
    color: AppColors.instance.textMuted,
  );

  // KPI y métricas - números grandes
  TextStyle get kpiNumber => _createStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.instance.textPrimary,
  );

  // Etiquetas de KPI
  TextStyle get kpiLabel => labelSmall.copyWith(
    fontSize: 10,
    letterSpacing: 0.8,
    fontWeight: FontWeight.w600,
  );

  // Texto de estado (activo, inactivo, etc.)
  TextStyle get statusText => labelSmall.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Texto de error en formularios
  TextStyle get errorText => bodySmall.copyWith(
    color: AppColors.instance.error,
    fontWeight: FontWeight.w500,
  );

  // Texto de ayuda
  TextStyle get helpText => bodySmall.copyWith(
    color: AppColors.instance.textMuted,
    fontWeight: FontWeight.w400,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY - PARA COMPATIBILIDAD
  // ═══════════════════════════════════════════════════════════════════════════

  TextStyle get caption => bodySmall.copyWith(
    fontSize: 12,
  );

  TextStyle get overline => labelSmall.copyWith(
    fontSize: 10,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w500,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONVENIENCIA
  // ═══════════════════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════════════════
  // GUÍA DE USO - CLARITY UI
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // 📏 ESCALA TIPOGRÁFICA:
  //   Display → Headlines → Titles → Body → Labels → Special
  //
  // 🎯 USO RECOMENDADO:
  //   - displayLarge: Hero titles, main headings
  //   - headlineMedium: Section headers, card titles
  //   - titleLarge: Dialog titles, form sections
  //   - bodyMedium: Main content, descriptions
  //   - labelMedium: Buttons, form labels
  //   - kpiNumber: Dashboard metrics, statistics
  //
  // ✨ CARACTERÍSTICAS:
  //   - Inter font: Moderna, legible, profesional
  //   - Letter spacing optimizado por tamaño
  //   - Line height accesible (1.4-1.5)
  //   - Pesos semánticos (400=regular, 500=medium, 600=semibold, 700=bold)
  // ═══════════════════════════════════════════════════════════════════════════
}