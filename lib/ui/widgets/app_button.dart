import 'package:flutter/widgets.dart';
import '../../theme/app_theme.dart';

/// Botón primario reutilizable
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final EdgeInsets? padding;

  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.padding,
    super.key,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled && !widget.isLoading
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.isEnabled && !widget.isLoading
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed();
            }
          : null,
      onTapCancel: widget.isEnabled && !widget.isLoading
          ? () => setState(() => _isPressed = false)
          : null,
      child: Container(
        width: widget.width ?? double.infinity,
        padding: widget.padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
        decoration: BoxDecoration(
          color: widget.isEnabled
              ? (_isPressed ? AppColors.primaryDark : AppColors.primary)
              : AppColors.greyDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: _buildLoadingSpinner(),
                )
              : Text(
                  widget.label,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingSpinner() {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(
          painter: _SpinnerPainter(),
        ),
      ),
    );
  }
}

/// Botón secundario
class AppSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;
  final double? width;

  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
    this.width,
    super.key,
  });

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed();
            }
          : null,
      onTapCancel: widget.isEnabled
          ? () => setState(() => _isPressed = false)
          : null,
      child: Container(
        width: widget.width ?? double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isEnabled ? AppColors.primary : AppColors.greyDark,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _isPressed && widget.isEnabled
              ? AppColors.background
              : AppColors.white,
        ),
        child: Center(
          child: Text(
            widget.label,
            style: AppTextStyles.titleMedium.copyWith(
              color: widget.isEnabled
                  ? AppColors.primary
                  : AppColors.greyDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// Spinner personalizado sin Material Design
class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // Dibujar círculo
    canvas.drawCircle(center, radius, paint);

    // Dibujar arco (simulando rotación)
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 0, 1.5, false, paint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) => true;
}
