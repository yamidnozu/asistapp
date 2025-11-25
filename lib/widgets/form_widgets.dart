import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme_extensions.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final GlobalKey<FormFieldState>? fieldKey;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final String? initialValue;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.focusNode,
    this.fieldKey,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.initialValue,
    this.errorText,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Material(
      color: Colors.transparent,
      child: TextFormField(
        key: fieldKey,
        focusNode: focusNode,
        controller: controller,
        initialValue: initialValue,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        enabled: enabled,
        onChanged: onChanged,
        onTap: onTap,
        validator: validator,
        inputFormatters: inputFormatters,
        style: textStyles.bodyLarge,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          hintStyle: textStyles.bodyMedium.withColor(colors.textMuted),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.error, width: 2),
          ),
          filled: true,
          fillColor: enabled ? colors.surface : colors.surface.withValues(alpha: 0.5),
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          labelStyle: textStyles.bodyMedium.withColor(colors.textSecondary),
        ),
      ),
    );
  }
}

class CustomDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final String labelText;
  final String hintText;
  final List<DropdownMenuItem<T>> items;
  final String? Function(T?)? validator;
  final FocusNode? focusNode;
  final GlobalKey<FormFieldState>? fieldKey;
  final void Function(T?)? onChanged;
  final bool enabled;

  const CustomDropdownFormField({
    super.key,
    this.value,
    required this.labelText,
    required this.hintText,
    required this.items,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
    this.fieldKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Material(
      color: Colors.transparent,
      child: DropdownButtonFormField<T>(
        key: fieldKey,
        value: value,
        focusNode: focusNode,
        items: items,
        onChanged: enabled ? onChanged : null,
        validator: validator,
        style: textStyles.bodyLarge,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          hintStyle: textStyles.bodyMedium.withColor(colors.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.error, width: 2),
          ),
          filled: true,
          fillColor: enabled ? colors.surface : colors.surface.withValues(alpha: 0.5),
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          labelStyle: textStyles.bodyMedium.withColor(colors.textSecondary),
        ),
        dropdownColor: colors.surface,
      ),
    );
  }
}

class CustomCheckboxFormField extends StatelessWidget {
  final bool value;
  final String title;
  final String? subtitle;
  final void Function(bool?)? onChanged;
  final String? Function(bool?)? validator;
  final bool enabled;

  const CustomCheckboxFormField({
    super.key,
    required this.value,
    required this.title,
    this.subtitle,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return FormField<bool>(
      initialValue: value,
      validator: validator,
      builder: (FormFieldState<bool> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: state.value ?? false,
              onChanged: enabled ? (bool? newValue) {
                state.didChange(newValue);
                onChanged?.call(newValue);
              } : null,
              title: Text(
                title,
                style: textStyles.bodyLarge,
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle!,
                      style: textStyles.bodySmall.withColor(colors.textSecondary),
                    )
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: colors.primary,
              checkColor: Theme.of(context).colorScheme.onPrimary,
              tileColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(spacing.borderRadius),
              ),
              side: BorderSide(color: colors.borderLight),
            ),
            if (state.hasError)
              Padding(
                padding: EdgeInsets.only(left: spacing.lg, top: spacing.xs),
                child: Text(
                  state.errorText!,
                  style: textStyles.bodySmall.withColor(colors.error),
                ),
              ),
          ],
        );
      },
    );
  }
}

class CustomSwitchFormField extends StatelessWidget {
  final bool value;
  final String title;
  final String? subtitle;
  final void Function(bool)? onChanged;
  final bool enabled;

  const CustomSwitchFormField({
    super.key,
    required this.value,
    required this.title,
    this.subtitle,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Material(
      color: Colors.transparent,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.borderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            children: [
              Icon(
                value ? Icons.check_circle : Icons.cancel,
                color: value ? colors.success : colors.error,
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textStyles.bodyLarge,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: textStyles.bodySmall.withColor(colors.textSecondary),
                      ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeColor: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}