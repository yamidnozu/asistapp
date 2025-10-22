import 'package:flutter/widgets.dart';
import '../../theme/app_theme.dart';
import 'app_button.dart';

/// Layout base para pantallas
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppScaffold({
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  if (showBackButton)
                    GestureDetector(
                      onTap: onBackPressed ?? () => Navigator.maybePop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: Text(
                          '←',
                          style: TextStyle(
                            fontSize: 24,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.headlineLarge,
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenedor de tarjeta reutilizable
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color backgroundColor;

  const AppCard({
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor = AppColors.surface,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Dialogo personalizado
class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? cancelLabel;
  final VoidCallback? onCancel;

  const AppDialog({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.cancelLabel,
    this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: const Color(0xB3000000),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevenir que el tap se propague
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: AppSpacing.md),
                  Text(message, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      if (cancelLabel != null)
                        Expanded(
                          child: AppSecondaryButton(
                            label: cancelLabel!,
                            onPressed: onCancel ?? () => Navigator.pop(context),
                          ),
                        ),
                      if (cancelLabel != null && actionLabel != null)
                        const SizedBox(width: AppSpacing.md),
                      if (actionLabel != null)
                        Expanded(
                          child: AppButton(
                            label: actionLabel!,
                            onPressed: onAction ?? () => Navigator.pop(context),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
