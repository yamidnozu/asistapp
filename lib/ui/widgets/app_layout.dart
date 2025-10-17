import 'package:flutter/widgets.dart';
import '../../theme/app_theme.dart';

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
    return Container(
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: body,
              ),
            ),
          ),
        ],
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
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
    return Container(
      color: const Color(0x80000000),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              Text(message, style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (cancelLabel != null)
                    Expanded(
                      child: GestureDetector(
                        onTap: onCancel ?? () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              cancelLabel!,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (cancelLabel != null && actionLabel != null)
                    const SizedBox(width: AppSpacing.md),
                  if (actionLabel != null)
                    Expanded(
                      child: GestureDetector(
                        onTap: onAction ?? () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              actionLabel!,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
