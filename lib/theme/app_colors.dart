import 'package:flutter/material.dart';

/// Sistema de colores ajustado a temática académica / de estudios
class AppColors {

  AppColors._();

  static final AppColors instance = AppColors._();

  static const Color _primaryBase = Color(0xFF2563EB); // Azul educativo - concentración
  static const Color _secondaryBase = Color(0xFF38BDF8); // Azul celeste - frescura y dinamismo
  static const Color _surfaceBase = Color(0xFFFFFFFF); // Blanco puro
  static const Color _backgroundBase = Color(0xFFF9FAFB); // Gray 50 - Fondo limpio y luminoso

  final Color primary = _primaryBase;
  final Color primaryDark = const Color(0xFF1E40AF); // Azul profundo - foco
  final Color primaryLight = const Color(0xFF60A5FA); // Azul claro - interacción
  final Color primaryContainer = const Color(0xFFE0F2FE); // Azul pastel - resalte suave

  final Color secondary = _secondaryBase;
  final Color secondaryLight = const Color(0xFF7DD3FC); // Azul brillante - optimismo
  final Color secondaryContainer = const Color(0xFFE0F7FA); // Azul cielo claro

  // Colores de estado - suaves pero definidos
  final Color success = const Color(0xFF16A34A); // Verde educativo - logro
  final Color warning = const Color(0xFFFACC15); // Amarillo pastel - advertencia
  final Color error = const Color(0xFFDC2626); // Rojo académico - corrección
  final Color info = const Color(0xFF3B82F6); // Azul medio - información

  // ═══════════════════════════════════════════════════════════════════════════
  // RECOMENDACIÓN DE USO DE COLORES PARA FEATURES
  // ═══════════════════════════════════════════════════════════════════════════
  // 
  // Para mantener una identidad visual consistente y profesional:
  // 
  // ✅ USAR PREFERENTEMENTE:
  //   - colors.primary     → Para acciones principales, iconos destacados
  //   - colors.secondary   → Para elementos de soporte, iconos secundarios
  //   - colors.info        → Para elementos informativos o terciarios
  // 
  // ⚠️ USAR CON MODERACIÓN:
  //   Los colores específicos por feature (abajo) solo cuando sea NECESARIO
  //   diferenciar visualmente tipos de datos o estados específicos.
  // 
  // 💡 EJEMPLO:
  //   En dashboards, usa colors.primary para TODOS los iconos de features.
  //   El ICONO y el TEXTO ya los diferencian visualmente.
  // ═══════════════════════════════════════════════════════════════════════════

  // Colores específicos por feature (USAR CON MODERACIÓN - ver nota arriba)
  final Color featureUsers = const Color(0xFF6366F1); // Índigo - usuarios
  final Color featureInstitutions = const Color(0xFF0EA5E9); // Azul cyan - instituciones
  final Color featureAttendance = const Color(0xFFF59E0B); // Dorado - asistencia
  final Color featureReports = const Color(0xFFE11D48); // Rosa fuerte - reportes
  final Color featureSchedule = const Color(0xFF14B8A6); // Verde menta - horarios
  final Color featureSettings = const Color(0xFF475569); // Slate - configuración
  final Color featureNotifications = const Color(0xFFF97316); // Naranja - notificaciones
  final Color featureClasses = const Color(0xFFEF4444); // Rojo coral - clases
  final Color featureGrades = const Color(0xFF84CC16); // Verde lima - calificaciones
  final Color featureStudents = const Color(0xFF2563EB); // Azul principal - estudiantes

  // Colores para estados informativos
  final Color stateNoData = const Color(0xFF94A3B8); // Slate 400
  final Color stateInDevelopment = const Color(0xFF6366F1); // Índigo - en desarrollo
  final Color stateSuccess = const Color(0xFF22C55E); // Verde éxito
  final Color stateInactive = const Color(0xFFE2E8F0); // Slate 200

  final Color surface = _surfaceBase;
  final Color surfaceLight = const Color(0xFFF9FAFB); // Fondo claro
  final Color surfaceContainer = const Color(0xFFFFFFFF); // Contenedor blanco
  final Color background = _backgroundBase;
  final Color backgroundLight = const Color(0xFFFFFFFF); // Fondo blanco puro

  // Texto - mejor contraste y jerarquía visual
  final Color textPrimary = const Color(0xFF0F172A); // Slate 900
  final Color textSecondary = const Color(0xFF334155); // Slate 700
  final Color textMuted = const Color(0xFF64748B); // Slate 500
  final Color textDisabled = const Color(0xFF94A3B8); // Slate 400

  // Texto sobre fondos oscuros
  final Color textOnDark = const Color(0xFFF8FAFC);
  final Color textOnDarkSecondary = const Color(0xFFE2E8F0);
  final Color textOnDarkMuted = const Color(0xFFCBD5E1);

  // Bordes y divisores - suaves y modernos
  final Color border = const Color(0xFFE2E8F0);
  final Color borderLight = const Color(0xFFF1F5F9);
  final Color divider = const Color(0xFFE2E8F0);
  final Color shadow = const Color(0x0A000000);

  final Color transparent = const Color(0x00000000);
  final Color shadowLight = const Color(0x05000000);
  final Color scrim = const Color(0x0F000000);

  final Color white = const Color(0xFFFFFFFF);
  final Color black = const Color(0xFF000000);
  final Color grey = const Color(0xFF94A3B8);
  final Color greyDark = const Color(0xFF475569);
  final Color greyLight = const Color(0xFFE2E8F0);

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
  Color get roleBadgeBackground => white.withValues(alpha: 0.15);
  Color get roleBadgeText => white;
  Color get roleBadgeIcon => white;

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
}
