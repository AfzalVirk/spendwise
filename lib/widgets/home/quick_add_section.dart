import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_page_route.dart';
import '../../screens/add_expense/add_expense_screen.dart';
import '../expense/quick_amount_sheet.dart';

/// Quick Add row: Breakfast / Lunch / Dinner open a one-field amount
/// sheet; Other opens the full Add Expense screen.
class QuickAddSection extends StatelessWidget {
  const QuickAddSection({super.key});

  void _onTap(BuildContext context, String category) {
    if (category == Categories.other) {
      Navigator.of(context).push(
        SlideUpRoute(page: const AddExpenseScreen()),
      );
    } else {
      showQuickAmountSheet(context, category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Add', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final category in Categories.quickAdd) ...[
              Expanded(
                child: _QuickAddButton(
                  category: category,
                  onTap: () => _onTap(context, category),
                ),
              ),
              if (category != Categories.quickAdd.last)
                const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.category, required this.onTap});

  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Quick add $category expense',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Categories.iconFor(category),
                  size: 22,
                  color: AppColors.primaryText,
                ),
                const SizedBox(height: 8),
                Text(
                  category,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
