import 'package:flutter/material.dart';

/// Sistema de colores moderno y profesional - "Clarity UI"
class AppColors {

  AppColors._();

  static final AppColors instance = AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PALETA MODERNA - CLARITY UI
  // ═══════════════════════════════════════════════════════════════════════════

  // Base colors - Paleta moderna inspirada en Atlassian/Linear
  static const Color _primaryBase = Color(0xFF0055D4); // Azul Atlassian - profesional y moderno
  static const Color _secondaryBase = Color(0xFF4F46E5); // Índigo moderno - complementario
  static const Color _surfaceBase = Color(0xFFFFFFFF); // Blanco puro
  static const Color _backgroundBase = Color(0xFFF8FAFC); // Gris muy claro - fondo limpio

  // Primary palette - Azul moderno y profesional
  final Color primary = _primaryBase;
  final Color primaryDark = const Color(0xFF0043B8); // Azul más profundo para hover/focus
  final Color primaryLight = const Color(0xFF4D9DE0); // Azul claro para elementos secundarios
  final Color primaryContainer = const Color(0xFFE3F2FD); // Azul pastel muy suave

  // Secondary palette - Índigo moderno
  final Color secondary = _secondaryBase;
  final Color secondaryLight = const Color(0xFF6366F1); // Índigo claro
  final Color secondaryContainer = const Color(0xFFEEF2FF); // Índigo pastel

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES DE ESTADO - SEMÁNTICOS Y ACCESIBLES
  // ═══════════════════════════════════════════════════════════════════════════

  // Success - Verde moderno (similar a Tailwind)
  final Color success = const Color(0xFF16A34A); // Verde 600 - éxito claro
  final Color successLight = const Color(0xFF22C55E); // Verde 500 - para elementos ligeros
  final Color successDark = const Color(0xFF15803D); // Verde 700 - para hover

  // Warning - Ámbar moderno
  final Color warning = const Color(0xFFF59E0B); // Ámbar 500 - advertencia clara
  final Color warningLight = const Color(0xFFFCD34D); // Ámbar 300 - para fondos
  final Color warningDark = const Color(0xFFD97706); // Ámbar 600 - para hover

  // Error - Rojo moderno
  final Color error = const Color(0xFFDC2626); // Rojo 600 - error claro
  final Color errorLight = const Color(0xFFF87171); // Rojo 400 - para elementos ligeros
  final Color errorDark = const Color(0xFFB91C1C); // Rojo 700 - para hover

  // Info - Azul informativo
  final Color info = const Color(0xFF3B82F6); // Azul 500 - información
  final Color infoLight = const Color(0xFF60A5FA); // Azul 400 - para elementos ligeros
  final Color infoDark = const Color(0xFF2563EB); // Azul 600 - para hover

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES ESPECÍFICOS POR FEATURE - USAR CON MODERACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  // Features principales - colores diferenciados pero armoniosos
  final Color featureUsers = const Color(0xFF6366F1); // Índigo - usuarios
  final Color featureInstitutions = const Color(0xFF0EA5E9); // Cyan - instituciones
  final Color featureAttendance = const Color(0xFFF59E0B); // Ámbar - asistencia
  final Color featureReports = const Color(0xFFE11D48); // Rosa fuerte - reportes
  final Color featureSchedule = const Color(0xFF14B8A6); // Teal - horarios
  final Color featureSettings = const Color(0xFF475569); // Slate - configuración
  final Color featureNotifications = const Color(0xFFF97316); // Naranja - notificaciones
  final Color featureClasses = const Color(0xFFEF4444); // Rojo coral - clases
  final Color featureGrades = const Color(0xFF84CC16); // Verde lima - calificaciones
  final Color featureStudents = const Color(0xFF0055D4); // Azul principal - estudiantes

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADOS Y CONDICIONES
  // ═══════════════════════════════════════════════════════════════════════════

  // Estados informativos
  final Color stateNoData = const Color(0xFF94A3B8); // Slate 400
  final Color stateInDevelopment = const Color(0xFF6366F1); // Índigo - en desarrollo
  final Color stateSuccess = const Color(0xFF22C55E); // Verde éxito
  final Color stateInactive = const Color(0xFFE2E8F0); // Slate 200
  final Color stateActive = const Color(0xFF16A34A); // Verde activo

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPERFICIES Y FONDOS - ESCALA MODERNA
  // ═══════════════════════════════════════════════════════════════════════════

  final Color surface = _surfaceBase; // Blanco puro
  final Color surfaceLight = const Color(0xFFF8FAFC); // Gris 50 muy claro
  final Color surfaceContainer = const Color(0xFFFFFFFF); // Contenedor blanco
  final Color surfaceVariant = const Color(0xFFF1F5F9); // Gris 100 para variantes

  final Color background = _backgroundBase; // Fondo principal
  final Color backgroundLight = const Color(0xFFFFFFFF); // Fondo blanco puro
  final Color backgroundVariant = const Color(0xFFF8FAFC); // Variante de fondo

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXTO - JERARQUÍA CLARA Y ACCESIBLE
  // ═══════════════════════════════════════════════════════════════════════════

  // Texto principal - escala moderna
  final Color textPrimary = const Color(0xFF0F172A); // Slate 900 - casi negro
  final Color textSecondary = const Color(0xFF334155); // Slate 700 - gris oscuro
  final Color textMuted = const Color(0xFF64748B); // Slate 500 - gris medio
  final Color textDisabled = const Color(0xFF94A3B8); // Slate 400 - gris claro

  // Texto sobre fondos oscuros
  final Color textOnDark = const Color(0xFFF8FAFC); // Blanco casi puro
  final Color textOnDarkSecondary = const Color(0xFFE2E8F0); // Gris muy claro
  final Color textOnDarkMuted = const Color(0xFFCBD5E1); // Gris claro

  // Texto sobre colores primarios
  final Color onPrimary = const Color(0xFFFFFFFF); // Blanco sobre primary

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDES Y DIVISORES - SUAVES Y MODERNOS
  // ═══════════════════════════════════════════════════════════════════════════

  final Color border = const Color(0xFFE2E8F0); // Slate 200 - borde estándar
  final Color borderLight = const Color(0xFFF1F5F9); // Slate 100 - borde ligero
  final Color borderStrong = const Color(0xFFCBD5E1); // Slate 300 - borde fuerte
  final Color divider = const Color(0xFFE2E8F0); // Slate 200 - divisor

  // ═══════════════════════════════════════════════════════════════════════════
  // SOMBRAS Y EFECTOS - SUBTLES Y MODERNOS
  // ═══════════════════════════════════════════════════════════════════════════

  final Color shadow = const Color(0x0A000000); // Negro con 4% opacidad
  final Color shadowLight = const Color(0x05000000); // Negro con 2% opacidad
  final Color shadowMedium = const Color(0x0F000000); // Negro con 6% opacidad
  final Color scrim = const Color(0x0F000000); // Negro con 6% opacidad

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES UTILITARIOS
  // ═══════════════════════════════════════════════════════════════════════════

  final Color transparent = const Color(0x00000000);
  final Color white = const Color(0xFFFFFFFF);
  final Color black = const Color(0xFF000000);

  // Escala de grises moderna
  final Color grey50 = const Color(0xFFF8FAFC);
  final Color grey100 = const Color(0xFFF1F5F9);
  final Color grey200 = const Color(0xFFE2E8F0);
  final Color grey300 = const Color(0xFFCBD5E1);
  final Color grey400 = const Color(0xFF94A3B8);
  final Color grey500 = const Color(0xFF64748B);
  final Color grey600 = const Color(0xFF475569);
  final Color grey700 = const Color(0xFF334155);
  final Color grey800 = const Color(0xFF1E293B);
  final Color grey900 = const Color(0xFF0F172A);

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
