import 'package:flutter/widgets.dart';
import '../../theme/app_theme.dart';

/// Dropdown/Select personalizado
class AppSelect<T> extends StatefulWidget {
  final List<DropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final bool enabled;

  const AppSelect({
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.enabled = true,
    super.key,
  });

  @override
  State<AppSelect<T>> createState() => _AppSelectState<T>();
}

class _AppSelectState<T> extends State<AppSelect<T>> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items.cast<DropdownItem<T>?>().firstWhere(
          (item) => item?.value == widget.value,
          orElse: () => null,
        );

    return Column(
      children: [
        GestureDetector(
          onTap: widget.enabled ? () => setState(() => _isOpen = !_isOpen) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: widget.enabled ? AppColors.white : AppColors.grey,
              border: Border.all(
                color: _isOpen ? AppColors.primary : AppColors.greyDark,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedItem?.label ?? widget.hint ?? 'Seleccionar...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selectedItem != null ? AppColors.black : AppColors.greyDark,
                    ),
                  ),
                ),
                Text(
                  _isOpen ? '▲' : '▼',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.grey),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: widget.items.map((item) {
                final isSelected = item.value == widget.value;
                return GestureDetector(
                  onTap: () {
                    setState(() => _isOpen = false);
                    widget.onChanged?.call(item.value);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLight : AppColors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class DropdownItem<T> {
  final String label;
  final T value;

  const DropdownItem({required this.label, required this.value});
}