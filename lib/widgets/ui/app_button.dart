import 'package:flutter/widgets.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/app_colors.dart';
import '../../config/app_constants.dart';

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
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    final buttonChild = Container(
      constraints: widget.width != null
          ? BoxConstraints(minWidth: widget.width!)
          : const BoxConstraints(minWidth: 0),
      padding: widget.padding ??
          EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.md,
          ),
      decoration: BoxDecoration(
        color: widget.isEnabled
            ? (_isPressed ? colors.primaryDark : colors.primary)
            : colors.grey300,
        borderRadius:
            BorderRadius.circular(AppConstants.instance.buttonBorderRadius),
      ),
      child: Center(
        child: widget.isLoading
            ? SizedBox(
                width: AppConstants.instance.spinnerSize,
                height: AppConstants.instance.spinnerSize,
                child: _buildLoadingSpinner(context),
              )
            : Text(
                widget.label,
                style: textStyles.labelLarge.copyWith(
                  color: colors.white, // Texto blanco sobre fondo primario
                ),
              ),
      ),
    );

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
      child: buttonChild,
    );
  }

  Widget _buildLoadingSpinner(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: SizedBox(
        width: AppConstants.instance.spinnerSize,
        height: AppConstants.instance.spinnerSize,
        child: CustomPaint(
          painter: _SpinnerPainter(colors: colors),
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
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    final buttonChild = Container(
      constraints: widget.width != null
          ? BoxConstraints(minWidth: widget.width!)
          : const BoxConstraints(minWidth: 0),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.md,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.isEnabled ? colors.primary : colors.grey300,
          width: AppConstants.instance.borderWidthNormal,
        ),
        borderRadius:
            BorderRadius.circular(AppConstants.instance.buttonBorderRadius),
        color: _isPressed && widget.isEnabled
            ? colors.surfaceLight
            : colors.transparent,
      ),
      child: Center(
        child: Text(
          widget.label,
          style: textStyles.labelLarge.copyWith(
            color: widget.isEnabled
                ? colors.primary // Texto primario sobre fondo transparente
                : colors.textDisabled,
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown:
          widget.isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed();
            }
          : null,
      onTapCancel:
          widget.isEnabled ? () => setState(() => _isPressed = false) : null,
      child: buttonChild,
    );
  }
}

/// Spinner personalizado sin Material Design
class _SpinnerPainter extends CustomPainter {
  final AppColors colors;

  _SpinnerPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.white // Spinner blanco sobre fondo primario
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, paint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 0, 1.5, false, paint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) => true;
}
