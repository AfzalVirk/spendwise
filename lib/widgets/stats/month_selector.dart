import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Left / right month navigation row:  <  September 2026  >
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.isCurrentMonth,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final bool isCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MonthArrowButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        MonthArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: isCurrentMonth ? null : onNext,
        ),
      ],
    );
  }
}

/// A small rounded icon button used as a prev/next arrow.
class MonthArrowButton extends StatelessWidget {
  const MonthArrowButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.subtleFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? AppColors.primaryText : AppColors.tertiaryText,
        ),
      ),
    );
  }
}
