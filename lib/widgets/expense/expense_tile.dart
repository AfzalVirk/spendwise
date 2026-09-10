import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';

/// A single expense row: category icon, name/note, time and amount.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    required this.currency,
    this.onTap,
    this.showDate = false,
  });

  final Expense expense;
  final String currency;
  final VoidCallback? onTap;

  /// When true shows "Sep 10 · 9:41 AM" instead of just the time.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (expense.note != null && expense.note!.isNotEmpty) expense.note!,
      showDate
          ? Formatters.dateAndTime(expense.dateTime)
          : Formatters.time(expense.dateTime),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.subtleFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Categories.iconFor(expense.category),
                  size: 22,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' · '),
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                Formatters.money(expense.amount, currency),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
