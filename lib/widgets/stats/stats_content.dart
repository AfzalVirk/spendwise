import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../common/app_card.dart';
import 'stats_data.dart';

/// The scrollable body of the Stats screen for a given month.
/// Shows the Days and Month sections, or an empty state if there's no data.
class StatsContent extends StatelessWidget {
  const StatsContent({
    super.key,
    required this.stats,
    required this.currency,
    required this.month,
  });

  final StatsData stats;
  final String currency;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    if (stats.totalSpent == 0 && stats.monthlyBudget == 0) {
      return StatsEmptyMonth(month: month);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        // ── Days Section ────────────────────────────────────────────
        const StatsSectionLabel(label: 'DAYS'),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              StatsRow(
                icon: Icons.trending_up_rounded,
                label: 'Over Budget Days',
                value: '${stats.overBudgetDays}',
                valueColor: stats.overBudgetDays > 0
                    ? AppColors.overBudget
                    : AppColors.primaryText,
              ),
              const Divider(height: 1, color: AppColors.divider),
              StatsRow(
                icon: Icons.arrow_downward_rounded,
                label: 'Lowest Expense Day',
                value: stats.lowestDay != null
                    ? '${DateFormat('MMM d').format(stats.lowestDay!.date)}  ·  ${Formatters.money(stats.lowestDay!.total, currency)}'
                    : '—',
              ),
              const Divider(height: 1, color: AppColors.divider),
              StatsRow(
                icon: Icons.arrow_upward_rounded,
                label: 'Highest Expense Day',
                value: stats.highestDay != null
                    ? '${DateFormat('MMM d').format(stats.highestDay!.date)}  ·  ${Formatters.money(stats.highestDay!.total, currency)}'
                    : '—',
              ),
              const Divider(height: 1, color: AppColors.divider),
              StatsRow(
                icon: Icons.bar_chart_rounded,
                label: 'Avg Daily Spending',
                value: stats.avgDailySpending > 0
                    ? Formatters.money(stats.avgDailySpending, currency)
                    : '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Month Section ────────────────────────────────────────────
        const StatsSectionLabel(label: 'MONTH'),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              StatsRow(
                icon: Icons.calendar_month_outlined,
                label: 'Monthly Budget',
                value: stats.monthlyBudget > 0
                    ? Formatters.money(stats.monthlyBudget, currency)
                    : 'Not set',
                valueColor: stats.monthlyBudget > 0
                    ? AppColors.primaryText
                    : AppColors.tertiaryText,
              ),
              const Divider(height: 1, color: AppColors.divider),
              StatsRow(
                icon: Icons.receipt_long_outlined,
                label: 'Total Spent',
                value: Formatters.money(stats.totalSpent, currency),
              ),
              if (stats.monthlyBudget > 0) ...[
                const Divider(height: 1, color: AppColors.divider),
                StatsRow(
                  icon: stats.isOverMonthlyBudget
                      ? Icons.sentiment_dissatisfied_outlined
                      : Icons.sentiment_satisfied_outlined,
                  label: stats.isOverMonthlyBudget ? 'Over Budget' : 'Saved',
                  value: Formatters.money(stats.saved.abs(), currency),
                  valueColor: stats.isOverMonthlyBudget
                      ? AppColors.overBudget
                      : AppColors.primaryText,
                ),
              ],
              const Divider(height: 1, color: AppColors.divider),
              StatsRow(
                icon: Icons.block_outlined,
                label: 'No-Spend Days',
                value: '${stats.noSpendDays}',
              ),
            ],
          ),
        ),

        // ── Budget message ───────────────────────────────────────────
        if (stats.monthlyBudget > 0) ...[
          const SizedBox(height: 16),
          StatsBudgetMessage(stats: stats, currency: currency),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────── Section label ──────

/// A small all-caps section heading (e.g. "DAYS", "MONTH").
class StatsSectionLabel extends StatelessWidget {
  const StatsSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.label.copyWith(fontSize: 12, letterSpacing: 0.8),
    );
  }
}

// ──────────────────────────────────────────────────────────── Stat row ──────

/// A single labelled row with an icon on the left and a value on the right.
class StatsRow extends StatelessWidget {
  const StatsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.secondaryText),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodySecondary.copyWith(
                color: valueColor ?? AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────── Budget banner ──────

/// A pill banner that shows whether the user was under or over budget.
class StatsBudgetMessage extends StatelessWidget {
  const StatsBudgetMessage({
    super.key,
    required this.stats,
    required this.currency,
  });

  final StatsData stats;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isOver = stats.isOverMonthlyBudget;
    final amount = Formatters.money(stats.saved.abs(), currency);
    final message = isOver
        ? 'You went $amount over budget.'
        : 'You stayed $amount under budget. 🎉';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOver
            ? AppColors.overBudget.withValues(alpha: 0.06)
            : AppColors.subtleFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOver
              ? AppColors.overBudget.withValues(alpha: 0.18)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOver
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 18,
            color: isOver ? AppColors.overBudget : AppColors.primaryText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySecondary.copyWith(
                color: isOver ? AppColors.overBudget : AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── Empty state ──────

/// Shown when a month has no expenses and no budget set.
class StatsEmptyMonth extends StatelessWidget {
  const StatsEmptyMonth({super.key, required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: AppColors.tertiaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'No data for ${DateFormat('MMMM').format(month)}',
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add some expenses to see your stats here.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
