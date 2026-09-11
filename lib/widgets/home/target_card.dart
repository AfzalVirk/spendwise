import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../common/animated_amount.dart';
import '../common/app_card.dart';

/// Large budget card: today's target, spent, remaining and animated
/// progress. Shows an over-target state when the budget is exceeded.
class TargetCard extends StatelessWidget {
  const TargetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final expenses = context.watch<ExpenseProvider>();

    final target = settings.dailyTarget;
    final currency = settings.currency;
    final spent = expenses.todayTotal;
    final remaining = expenses.remainingToday(target);
    final progress = expenses.progressToday(target);
    final isOver = expenses.isOverTarget(target);
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final percentLabel = '${(progress * 100).round()}% spent';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Target", style: AppTextStyles.label),
              if (isOver)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.subtleFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Over target',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.overBudget,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.money(target, currency),
            style: AppTextStyles.largeAmount,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  label: 'Spent',
                  child: AnimatedAmount(
                    value: spent,
                    currency: currency,
                    style: AppTextStyles.amount,
                  ),
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              const SizedBox(width: 20),
              Expanded(
                child: _StatBlock(
                  label: isOver ? 'Over by' : 'Remaining',
                  child: AnimatedAmount(
                    value: remaining.abs(),
                    currency: currency,
                    style: AppTextStyles.amount.copyWith(
                      color:
                          isOver ? AppColors.overBudget : AppColors.primaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: clamped),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.progressTrack,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOver ? AppColors.overBudget : AppColors.progressFill,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOver
                ? '${Formatters.money(remaining.abs(), currency)} over target'
                : percentLabel,
            style: AppTextStyles.caption.copyWith(
              color: isOver ? AppColors.overBudget : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: child),
      ],
    );
  }
}
