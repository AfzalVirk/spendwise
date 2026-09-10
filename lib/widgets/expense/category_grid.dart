import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Wrap of selectable category chips.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in Categories.all)
          _CategoryChip(
            category: category,
            isSelected: category == selected,
            onTap: () => onSelected(category),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Category $category',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.darkFill : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.darkFill : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Categories.iconFor(category),
                size: 17,
                color:
                    isSelected ? AppColors.onPrimary : AppColors.secondaryText,
              ),
              const SizedBox(width: 7),
              Text(
                category,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  color:
                      isSelected ? AppColors.onPrimary : AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
