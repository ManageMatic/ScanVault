import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';

/// Reusable group of selectable pill filter chips conforming to Stitch specifications.
class FilterChipGroup<T> extends StatelessWidget {
  final List<T> options;
  final T selectedValue;
  final String Function(T) labelBuilder;
  final IconData Function(T)? iconBuilder;
  final ValueChanged<T> onSelected;

  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.labelBuilder,
    this.iconBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.map((option) {
          final isSelected = option == selectedValue;
          final label = labelBuilder(option);
          final icon = iconBuilder != null ? iconBuilder!(option) : null;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(option),
                borderRadius: AppDimens.roundedFull,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppColors.primaryFixedDim : AppColors.primary)
                        : (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow),
                    borderRadius: AppDimens.roundedFull,
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected
                              ? (isDark ? AppColors.onPrimaryFixed : Colors.white)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected
                              ? (isDark ? AppColors.onPrimaryFixed : Colors.white)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
