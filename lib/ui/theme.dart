import 'package:flutter/widgets.dart';

class ChronoTheme {
  static const Color background = Color(0xFF0F1115);
  static const Color card = Color(0x1AF5F7FA); // glassy
  static const Color accent = Color(0xFF7DD3FC);
  static const Color ok = Color(0xFF34D399);
  static const Color warn = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color text = Color(0xFFE5E7EB);
  static const Color textDim = Color(0xFF9CA3AF);

  static const TextStyle baseText = TextStyle(
    color: text,
    fontSize: 16,
    height: 1.25,
    fontFamilyFallback: ['SF Pro Text', 'Roboto', 'Helvetica', 'Arial'],
  );

  static BoxDecoration glass() => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 8)),
    ],
    border: Border.all(color: Color(0x22FFFFFF), width: 1),
  );
}