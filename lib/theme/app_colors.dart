import 'package:flutter/material.dart';

/// Sistema de colores escalable y mantenible
class AppColors {
  AppColors._();
  static final AppColors instance = AppColors._();
  static const Color _primaryBase = Color(0xFF0F172A); // Slate 900
  static const Color _secondaryBase = Color(0xFF64748B); // Slate 500
  static const Color _surfaceBase = Color(0xFFFFFFFF); // White
  static const Color _backgroundBase = Color(0xFFF8FAFC); // Slate 50
  final Color primary = _primaryBase;
  final Color primaryDark = const Color(0xFF0F172A); // Slate 900
  final Color primaryLight = const Color(0xFF6366F1); // Indigo 500 (hover/focus)
  final Color primaryContainer = const Color(0xFFE2E8F0); // Slate 200
  final Color secondary = _secondaryBase;
  final Color secondaryLight = const Color(0xFF94A3B8); // Slate 400
  final Color secondaryContainer = const Color(0xFFF1F5F9); // Slate 100
  final Color success = const Color(0xFF10B981); // Emerald 500
  final Color warning = const Color(0xFFF59E0B); // Amber 500
  final Color error = const Color(0xFFF43F5E); // Rose 500
  final Color info = const Color(0xFF6366F1); // Indigo 500
  final Color surface = _surfaceBase;
  final Color surfaceLight = const Color(0xFFF8FAFC); // Slate 50
  final Color surfaceContainer = const Color(0xFFFFFFFF); // White
  final Color background = _backgroundBase;
  final Color backgroundLight = const Color(0xFFFFFFFF); // White
  final Color textPrimary = const Color(0xFF1E293B); // Slate 800
  final Color textSecondary = const Color(0xFF64748B); // Slate 500
  final Color textMuted = const Color(0xFF94A3B8); // Slate 400
  final Color textDisabled = const Color(0xFFCBD5E1); // Slate 300
  final Color border = const Color(0xFFE2E8F0); // Slate 200
  final Color borderLight = const Color(0xFFF1F5F9); // Slate 100
  final Color divider = const Color(0xFFE2E8F0); // Slate 200
  final Color shadow = const Color(0x0A000000); // Black 10% opacity
  final Color transparent = const Color(0x00000000);
  final Color shadowLight = const Color(0x0A000000); // Black 10% opacity
  final Color scrim = const Color(0x1A000000); // Black 10% opacity
  final Color white = const Color(0xFFFFFFFF);
  final Color black = const Color(0xFF000000);
  final Color grey = const Color(0xFF64748B); // Slate 500
  final Color greyDark = const Color(0xFF475569); // Slate 600
  final Color greyLight = const Color(0xFFCBD5E1); // Slate 300
  Color get primaryWithOpacity => primary.withValues(alpha: 0.8);
  Color get surfaceWithOpacity => surface.withValues(alpha: 0.9);
  Color get textSecondaryWithOpacity => textSecondary.withValues(alpha: 0.7);
}