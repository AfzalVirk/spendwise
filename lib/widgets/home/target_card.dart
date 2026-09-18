import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/budget_insight.dart';
import '../../core/utils/formatters.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../common/animated_amount.dart';
import '../common/app_card.dart';

enum _BudgetView { today, thisMonth }

/// Large budget card: today's target OR this month's budget, with a
/// Today | This Month toggle. Shows an over-target/budget state when exceeded.
class TargetCard extends StatefulWidget {
  const TargetCard({super.key});

  @override
  State<TargetCard> createState() => _TargetCardState();
}

class _TargetCardState extends State<TargetCard> {
  _BudgetView _view = _BudgetView.today;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final currency = settings.currency;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Toggle row ───────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _view == _BudgetView.today ? "Today's Target" : _monthLabel(),
                style: AppTextStyles.label,
              ),
              _ViewToggle(
                view: _view,
                onChanged: (v) => setState(() => _view = v),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Content switches by view ──────────────────────────────────────
          if (_view == _BudgetView.today)
            _TodayView(
                settings: settings, expenses: expenses, currency: currency)
          else
            _MonthView(
                settings: settings, expenses: expenses, currency: currency),
        ],
      ),
    );
  }

  /// E.g. "September Budget"
  String _monthLabel() {
    final now = DateTime.now();
    return '${DateFormat('MMMM').format(now)} Budget';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today view (unchanged behavior)
// ─────────────────────────────────────────────────────────────────────────────

class _TodayView extends StatelessWidget {
  const _TodayView({
    required this.settings,
    required this.expenses,
    required this.currency,
  });

  final SettingsProvider settings;
  final ExpenseProvider expenses;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final target = settings.dailyTarget;
    final spent = expenses.todayTotal;
    final remaining = expenses.remainingToday(target);
    final progress = expenses.progressToday(target);
    final isOver = expenses.isOverTarget(target);
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final percentLabel = '${(progress * 100).round()}% spent';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount — full width so 6-figure values never overflow.
        Text(
          Formatters.money(target, currency),
          style: AppTextStyles.largeAmount,
        ),
        if (isOver) ...[
          const SizedBox(height: 6),
          const _OverBadge(label: 'Over target')
        ],
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
        _ProgressBar(clamped: clamped, isOver: isOver),
        const SizedBox(height: 8),
        // Bottom row: percent on the left (or over-amount when over target).
        Text(
          isOver
              ? '${Formatters.money(remaining.abs(), currency)} over target'
              : percentLabel,
          style: AppTextStyles.caption.copyWith(
            color: isOver ? AppColors.overBudget : AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: SizedBox(
            width: 70,
            child: Divider(height: 4, color: AppColors.chartBar),
          ),
        ),
        const SizedBox(height: 10),
        // Motivational / state-aware insight line.
        Text(
          BudgetInsight.todayInsight(
            progress: progress,
            remaining: remaining,
            currency: currency,
          ),
          style: AppTextStyles.caption.copyWith(
            color: isOver ? AppColors.overBudget : AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// This Month view
// ─────────────────────────────────────────────────────────────────────────────

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.settings,
    required this.expenses,
    required this.currency,
  });

  final SettingsProvider settings;
  final ExpenseProvider expenses;
  final String currency;

  /// Days remaining in the current calendar month (handles all month lengths
  /// and leap years correctly using DateTime arithmetic).
  int _daysRemainingInMonth() {
    final now = DateTime.now();
    // Last day of this month: day 0 of next month = last day of this month.
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remaining = lastDay - now.day;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  Widget build(BuildContext context) {
    final budget = settings.currentMonthBudget;
    final spent = expenses.monthTotal;
    final remaining = expenses.remainingThisMonth(budget);
    final progress = expenses.progressThisMonth(budget);
    final isOver = budget > 0 && expenses.isOverMonthlyBudget(budget);
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final percentLabel =
        budget > 0 ? '${(progress * 100).round()}% spent' : 'No budget set';
    final daysLeft = _daysRemainingInMonth();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount — full width so 6-figure values never overflow.
        Text(
          budget > 0 ? Formatters.money(budget, currency) : 'Not set',
          style: AppTextStyles.largeAmount,
        ),
        if (isOver) ...[
          const SizedBox(height: 6),
          const _OverBadge(label: 'Over budget')
        ],
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
                  value: budget > 0 ? remaining.abs() : spent,
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
        _ProgressBar(clamped: clamped, isOver: isOver),
        const SizedBox(height: 8),
        // Bottom row: percent spent on the left, days left on the right.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOver
                  ? '${Formatters.money(remaining.abs(), currency)} over budget'
                  : percentLabel,
              style: AppTextStyles.caption.copyWith(
                color: isOver ? AppColors.overBudget : AppColors.secondaryText,
              ),
            ),
            Text(
              '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Center(
          child: SizedBox(
            width: 64,
            child: Divider(height: 1, color: AppColors.chartBar),
          ),
        ),
        const SizedBox(height: 10),
        // Actionable monthly insight (daily-rate or motivational).
        Text(
          BudgetInsight.monthInsight(
            progress: progress,
            remaining: remaining,
            daysLeft: daysLeft,
            currency: currency,
            hasBudget: budget > 0,
          ),
          style: AppTextStyles.caption.copyWith(
            color: isOver ? AppColors.overBudget : AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final _BudgetView view;
  final ValueChanged<_BudgetView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.subtleFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem('Today', _BudgetView.today),
          _toggleItem('This Month', _BudgetView.thisMonth),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, _BudgetView value) {
    final selected = view == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkFill : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OverBadge extends StatelessWidget {
  const _OverBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.subtleFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.overBudget,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.clamped, required this.isOver});
  final double clamped;
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
