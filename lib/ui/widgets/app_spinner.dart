import 'package:flutter/widgets.dart';
import '../../theme/app_theme.dart';

/// Spinner personalizado sin Material Design
class AppSpinner extends StatefulWidget {
  final double size;
  final Color color;

  const AppSpinner({
    this.size = 24,
    this.color = AppColors.primary,
    super.key,
  });

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SpinnerPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SpinnerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // Dibujar arco animado
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, progress * 2 * 3.14159 - 3.14159 / 2, 3.14159 / 2, false, paint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) => true;
}