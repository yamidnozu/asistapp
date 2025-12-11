import 'package:flutter/material.dart';

/// Sistema de colores moderno y profesional - "Clarity UI"
class AppColors {
  /// Default singleton (light mode default)
  static final AppColors instance = AppColors._light();

  /// Factory to create colors based on the current brightness
  factory AppColors.fromBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors._dark()
        : AppColors._light();
  }

  /// Private constructors for light/dark variants
  AppColors._light() {
    _setLight();
  }
  AppColors._dark() {
    _setDark();
  }

  void _setLight() {
    primary = _primaryBase;
    primaryDark = const Color(0xFF0288D1);
    primaryLight = const Color(0xFF81D4FA);
    primaryContainer = const Color(0xFFE1F5FE);

    secondary = _secondaryBase;
    secondaryLight = const Color(0xFF6366F1);
    secondaryContainer = const Color(0xFFEEF2FF);

    success = const Color(0xFF16A34A);
    successLight = const Color(0xFF22C55E);
    successDark = const Color(0xFF15803D);

    warning = const Color(0xFFF59E0B);
    warningLight = const Color(0xFFFCD34D);
    warningDark = const Color(0xFFD97706);

    error = const Color(0xFFDC2626);
    errorLight = const Color(0xFFF87171);
    errorDark = const Color(0xFFB91C1C);

    info = const Color(0xFF3B82F6);
    infoLight = const Color(0xFF60A5FA);
    infoDark = const Color(0xFF2563EB);

    featureUsers = const Color(0xFF6366F1);
    featureInstitutions = const Color(0xFF0EA5E9);
    featureAttendance = const Color(0xFFF59E0B);
    featureReports = const Color(0xFF7C3AED);
    featureSchedule = const Color(0xFF14B8A6);
    featureSettings = const Color(0xFF475569);
    featureNotifications = const Color(0xFFF97316);
    featureClasses = const Color(0xFFEF4444);
    featureGrades = const Color(0xFF84CC16);
    featureStudents = const Color(0xFF0055D4);

    stateNoData = const Color(0xFF94A3B8);
    stateInDevelopment = const Color(0xFF6366F1);
    stateSuccess = const Color(0xFF22C55E);
    stateInactive = const Color(0xFFE2E8F0);
    stateActive = const Color(0xFF16A34A);

    surface = _surfaceBase;
    surfaceLight = const Color(0xFFF8FAFC);
    surfaceContainer = const Color(0xFFFFFFFF);
    surfaceVariant = const Color(0xFFF1F5F9);

    background = _backgroundBase;
    backgroundLight = const Color(0xFFFFFFFF);
    backgroundVariant = const Color(0xFFF8FAFC);

    textPrimary = const Color(0xFF0F172A);
    textSecondary = const Color(0xFF334155);
    textMuted = const Color(0xFF64748B);
    textDisabled = const Color(0xFF94A3B8);

    textOnDark = const Color(0xFFF8FAFC);
    textOnDarkSecondary = const Color(0xFFE2E8F0);
    textOnDarkMuted = const Color(0xFFCBD5E1);

    onPrimary = const Color(0xFFFFFFFF);

    border = const Color(0xFFE2E8F0);
    borderLight = const Color(0xFFF1F5F9);
    borderStrong = const Color(0xFFCBD5E1);
    divider = const Color(0xFFE2E8F0);

    shadow = const Color(0x0A000000);
    shadowLight = const Color(0x05000000);
    shadowMedium = const Color(0x0F000000);
    scrim = const Color(0x0F000000);

    transparent = const Color(0x00000000);
    white = const Color(0xFFFFFFFF);
    black = const Color(0xFF000000);

    grey50 = const Color(0xFFF8FAFC);
    grey100 = const Color(0xFFF1F5F9);
    grey200 = const Color(0xFFE2E8F0);
    grey300 = const Color(0xFFCBD5E1);
    grey400 = const Color(0xFF94A3B8);
    grey500 = const Color(0xFF64748B);
    grey600 = const Color(0xFF475569);
    grey700 = const Color(0xFF334155);
    grey800 = const Color(0xFF1E293B);
    grey900 = const Color(0xFF0F172A);

    debugBadge = const Color(0xFF6EE7B7);
  }

  void _setDark() {
    primary = _primaryBase;
    primaryDark = const Color(0xFF0277BD);
    primaryLight = const Color(0xFF4FC3F7);
    primaryContainer = const Color(0xFF1E3A5F);

    secondary = _secondaryBase;
    secondaryLight = const Color(0xFF6366F1);
    secondaryContainer = const Color(0xFF1F2937);

    success = const Color(0xFF16A34A);
    successLight = const Color(0xFF16A34A);
    successDark = const Color(0xFF16A34A);

    warning = const Color(0xFFF59E0B);
    warningLight = const Color(0xFFF59E0B);
    warningDark = const Color(0xFFF59E0B);

    error = const Color(0xFFDC2626);
    errorLight = const Color(0xFFDC2626);
    errorDark = const Color(0xFFDC2626);

    info = const Color(0xFF3B82F6);
    infoLight = const Color(0xFF3B82F6);
    infoDark = const Color(0xFF3B82F6);

    featureUsers = const Color(0xFF6366F1);
    featureInstitutions = const Color(0xFF0EA5E9);
    featureAttendance = const Color(0xFFF59E0B);
    featureReports = const Color(0xFF7C3AED);
    featureSchedule = const Color(0xFF14B8A6);
    featureSettings = const Color(0xFF475569);
    featureNotifications = const Color(0xFFF97316);
    featureClasses = const Color(0xFFEF4444);
    featureGrades = const Color(0xFF84CC16);
    featureStudents = const Color(0xFF0055D4);

    stateNoData = const Color(0xFF94A3B8);
    stateInDevelopment = const Color(0xFF6366F1);
    stateSuccess = const Color(0xFF22C55E);
    stateInactive = const Color(0xFF0F172A);
    stateActive = const Color(0xFF16A34A);

    surface = const Color(0xFF0F172A);
    surfaceLight = const Color(0xFF111827);
    surfaceContainer = const Color(0xFF111827);
    surfaceVariant = const Color(0xFF111827);

    background = const Color(0xFF071026);
    backgroundLight = const Color(0xFF0B1220);
    backgroundVariant = const Color(0xFF071026);

    textPrimary = const Color(0xFFF8FAFC);
    textSecondary = const Color(0xFFE2E8F0);
    textMuted = const Color(0xFFCBD5E1);
    textDisabled = const Color(0xFF94A3B8);

    textOnDark = const Color(0xFFF8FAFC);
    textOnDarkSecondary = const Color(0xFFE2E8F0);
    textOnDarkMuted = const Color(0xFFCBD5E1);

    onPrimary = const Color(0xFFFFFFFF);

    border = const Color(0xFF1E293B);
    borderLight = const Color(0xFF111827);
    borderStrong = const Color(0xFF0B1220);
    divider = const Color(0xFF1E293B);

    shadow = const Color(0x1AFFFFFF);
    shadowLight = const Color(0x0F000000);
    shadowMedium = const Color(0x1F000000);
    scrim = const Color(0xFF000000);

    transparent = const Color(0x00000000);
    white = const Color(0xFFFFFFFF);
    black = const Color(0xFF000000);

    grey50 = const Color(0xFF0F172A);
    grey100 = const Color(0xFF111827);
    grey200 = const Color(0xFF1E293B);
    grey300 = const Color(0xFF334155);
    grey400 = const Color(0xFF475569);
    grey500 = const Color(0xFF64748B);
    grey600 = const Color(0xFF94A3B8);
    grey700 = const Color(0xFFCBD5E1);
    grey800 = const Color(0xFFF1F5F9);
    grey900 = const Color(0xFFFFFFFF);

    debugBadge = const Color(0xFF6EE7B7);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PALETA MODERNA - CLARITY UI
  // ═══════════════════════════════════════════════════════════════════════════

  // Base colors - Paleta moderna inspirada en Atlassian/Linear
  // Cambiado a azul claro para una apariencia más agradable
  static const Color _primaryBase =
      Color(0xFF8A0303); // Vinotinto - para verificar despliegue
  static const Color _secondaryBase =
      Color(0xFF4F46E5); // Índigo moderno - complementario
  static const Color _surfaceBase = Color(0xFFFFFFFF); // Blanco puro
  static const Color _backgroundBase =
      Color(0xFFF8FAFC); // Gris muy claro - fondo limpio

  // Primary palette - Azul moderno y profesional
  late final Color primary;
  late final Color primaryDark;
  late final Color primaryLight;
  late final Color primaryContainer;

  // Secondary palette - Índigo moderno
  late final Color secondary;
  late final Color secondaryLight;
  late final Color secondaryContainer;

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES DE ESTADO - SEMÁNTICOS Y ACCESIBLES
  // ═══════════════════════════════════════════════════════════════════════════

  // Success - Verde moderno (similar a Tailwind)
  late final Color success;
  late final Color successLight;
  late final Color successDark;

  // Warning - Ámbar moderno
  late final Color warning;
  late final Color warningLight;
  late final Color warningDark;

  // Error - Rojo moderno
  late final Color error;
  late final Color errorLight;
  late final Color errorDark;

  // Info - Azul informativo
  late final Color info;
  late final Color infoLight;
  late final Color infoDark;

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES ESPECÍFICOS POR FEATURE - USAR CON MODERACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  // Features principales - colores diferenciados pero armoniosos
  late final Color featureUsers;
  late final Color featureInstitutions;
  late final Color featureAttendance;
  late final Color featureReports;
  late final Color featureSchedule;
  late final Color featureSettings;
  late final Color featureNotifications;
  late final Color featureClasses;
  late final Color featureGrades;
  late final Color featureStudents;

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADOS Y CONDICIONES
  // ═══════════════════════════════════════════════════════════════════════════

  // Estados informativos
  late final Color stateNoData;
  late final Color stateInDevelopment;
  late final Color stateSuccess;
  late final Color stateInactive;
  late final Color stateActive;

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPERFICIES Y FONDOS - ESCALA MODERNA
  // ═══════════════════════════════════════════════════════════════════════════

  late final Color surface;
  late final Color surfaceLight;
  late final Color surfaceContainer;
  late final Color surfaceVariant;

  late final Color background;
  late final Color backgroundLight;
  late final Color backgroundVariant;

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXTO - JERARQUÍA CLARA Y ACCESIBLE
  // ═══════════════════════════════════════════════════════════════════════════

  // Texto principal - escala moderna
  late final Color textPrimary;
  late final Color textSecondary;
  late final Color textMuted;
  late final Color textDisabled;

  // Texto sobre fondos oscuros
  late final Color textOnDark;
  late final Color textOnDarkSecondary;
  late final Color textOnDarkMuted;

  // Texto sobre colores primarios
  late final Color onPrimary;

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDES Y DIVISORES - SUAVES Y MODERNOS
  // ═══════════════════════════════════════════════════════════════════════════

  late final Color border;
  late final Color borderLight;
  late final Color borderStrong;
  late final Color divider;

  // ═══════════════════════════════════════════════════════════════════════════
  // SOMBRAS Y EFECTOS - SUBTLES Y MODERNOS
  // ═══════════════════════════════════════════════════════════════════════════

  late final Color shadow;
  late final Color shadowLight;
  late final Color shadowMedium;
  late final Color scrim;

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES UTILITARIOS
  // ═══════════════════════════════════════════════════════════════════════════

  late final Color transparent;
  late final Color white;
  late final Color black;

  // Escala de grises moderna
  late final Color grey50;
  late final Color grey100;
  late final Color grey200;
  late final Color grey300;
  late final Color grey400;
  late final Color grey500;
  late final Color grey600;
  late final Color grey700;
  late final Color grey800;
  late final Color grey900;

  // Minor debug color: used for small non-production badges (non-invasive change)
  late final Color debugBadge;

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONVENIENCIA
  // ═══════════════════════════════════════════════════════════════════════════

  // Colores con opacidad
  Color get primaryWithOpacity => primary.withValues(alpha: 0.9);
  Color get surfaceWithOpacity => surface.withValues(alpha: 0.95);
  Color get textSecondaryWithOpacity => textSecondary.withValues(alpha: 0.8);

  // Fondos de estado con opacidad
  Color get warningBackground => warning.withValues(alpha: 0.08);
  Color get warningBorder => warning.withValues(alpha: 0.2);
  Color get infoBackground => info.withValues(alpha: 0.08);
  Color get infoBorder => info.withValues(alpha: 0.2);
  Color get errorBackground => error.withValues(alpha: 0.08);
  Color get errorBorder => error.withValues(alpha: 0.2);
  Color get successBackground => success.withValues(alpha: 0.08);
  Color get successBorder => success.withValues(alpha: 0.2);

  // Badges de rol
  Color get roleBadgeBackground => primary.withValues(alpha: 0.1);
  Color get roleBadgeText => primary;
  Color get roleBadgeIcon => primary;

  // Helpers de contraste
  Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textOnDark;
  }

  Color getSecondaryTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textSecondary : textOnDarkSecondary;
  }

  Color getMutedTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textMuted : textOnDarkMuted;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GUÍA DE USO - CLARITY UI
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // 🎨 PALETA MODERNA:
  //   - primary: Para acciones principales, CTAs, elementos destacados
  //   - secondary: Para elementos de soporte, navegación secundaria
  //   - success/warning/error/info: Para estados y feedback
  //
  // 📝 JERARQUÍA DE TEXTO:
  //   - textPrimary: Títulos, información crítica
  //   - textSecondary: Subtítulos, información secundaria
  //   - textMuted: Etiquetas, información auxiliar
  //
  // 🎯 FEATURES:
  //   - Usar featureColors solo cuando sea necesario diferenciar
  //   - Preferir primary/secondary para consistencia
  //
  // ✨ ACCESIBILIDAD:
  //   - Mantener contraste mínimo 4.5:1 para texto normal
  //   - Usar textOnDark para fondos oscuros
  // ═══════════════════════════════════════════════════════════════════════════
}
