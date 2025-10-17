import 'package:flutter/widgets.dart';
import '../../theme/app_theme.dart';

/// Input de texto reutilizable
class AppTextInput extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AppTextInput({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    super.key,
  });

  @override
  State<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends State<AppTextInput> {
  late FocusNode _focusNode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _focusNode.hasFocus
                  ? AppColors.primary
                  : (_error != null ? AppColors.error : AppColors.grey),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: EditableText(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    style: AppTextStyles.bodyMedium,
                    cursorColor: AppColors.primary,
                    backgroundCursorColor: AppColors.grey,
                    keyboardType: widget.keyboardType,
                    obscureText: widget.obscureText,
                    maxLines: widget.maxLines,
                    minLines: 1,
                    onChanged: (value) {
                      final error = widget.validator?.call(value);
                      setState(() => _error = error);
                      widget.onChanged?.call(value);
                    },
                  ),
                ),
                if (widget.suffixIcon != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  widget.suffixIcon!,
                ],
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _error!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// Checkbox reutilizable
class AppCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  const AppCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
              color: widget.value ? AppColors.primary : AppColors.white,
            ),
            child: widget.value
                ? const Center(
                    child: Text(
                      '✓',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            widget.label,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
