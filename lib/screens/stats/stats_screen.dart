import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/app_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  // The month currently displayed.
  late DateTime _month;

  // Controls the horizontal slide when changing months.
  // +1 = sliding to next month (new content enters from right)
  // -1 = sliding to prev month (new content enters from left)
  int _slideDirection = 0;

  // Entrance animation for the header only.
  late final AnimationController _entranceCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _headerFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _goPrev() {
    setState(() {
      _slideDirection = -1;
      _month = DateTime(_month.year, _month.month - 1);
    });
  }

  void _goNext() {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    // Don't allow going beyond the current month.
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() {
      _slideDirection = 1;
      _month = next;
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currency;
    final dailyTarget = settings.dailyTarget;
    final monthlyBudget = settings.getMonthlyBudget(_month.year, _month.month);

    // Filter expenses for the selected month.
    final monthExpenses = expenses
        .where((e) =>
            e.dateTime.year == _month.year && e.dateTime.month == _month.month)
        .toList();

    final stats = _StatsData.compute(
      monthExpenses: monthExpenses,
      month: _month,
      dailyTarget: dailyTarget,
      monthlyBudget: monthlyBudget,
    );

    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stats', style: AppTextStyles.heading),
                    const SizedBox(height: 16),
                    _MonthSelector(
                      month: _month,
                      isCurrentMonth: _isCurrentMonth,
                      onPrev: _goPrev,
                      onNext: _goNext,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Scrollable content with horizontal slide transition ──────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                // Incoming content slides from the appropriate side.
                final inSlide = Tween<Offset>(
                  begin: Offset(_slideDirection.toDouble(), 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: inSlide, child: child),
                );
              },
              child: _StatsContent(
                key: ValueKey('${_month.year}-${_month.month}'),
                stats: stats,
                currency: currency,
                month: _month,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Month Selector ──────

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
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
        _ArrowButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: isCurrentMonth ? null : onNext,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

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

// ─────────────────────────────────────────────────────────── Stats Data ──────

class _DayStats {
  final DateTime date;
  final double total;
  _DayStats(this.date, this.total);
}

class _StatsData {
  const _StatsData({
    required this.overBudgetDays,
    required this.lowestDay,
    required this.highestDay,
    required this.avgDailySpending,
    required this.totalSpent,
    required this.monthlyBudget,
    required this.noSpendDays,
    required this.daysInMonth,
  });

  final int overBudgetDays;
  final _DayStats? lowestDay;
  final _DayStats? highestDay;
  final double avgDailySpending;
  final double totalSpent;
  final double monthlyBudget;
  final int noSpendDays;
  final int daysInMonth;

  double get saved => monthlyBudget > 0 ? monthlyBudget - totalSpent : 0;
  bool get isOverMonthlyBudget =>
      monthlyBudget > 0 && totalSpent > monthlyBudget;

  factory _StatsData.compute({
    required List<Expense> monthExpenses,
    required DateTime month,
    required double dailyTarget,
    required double monthlyBudget,
  }) {
    final now = DateTime.now();
    final lastDay = (month.year == now.year && month.month == now.month)
        ? now.day
        : DateTime(month.year, month.month + 1, 0).day;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // Build a map of total per day.
    final Map<int, double> dayTotals = {};
    for (final e in monthExpenses) {
      dayTotals[e.dateTime.day] = (dayTotals[e.dateTime.day] ?? 0) + e.amount;
    }

    int overBudgetDays = 0;
    int noSpendDays = 0;
    _DayStats? lowestDay;
    _DayStats? highestDay;

    for (int d = 1; d <= lastDay; d++) {
      final total = dayTotals[d] ?? 0;
      if (total == 0) {
        noSpendDays++;
        continue;
      }
      if (dailyTarget > 0 && total > dailyTarget) overBudgetDays++;

      final dayDate = DateTime(month.year, month.month, d);
      if (lowestDay == null || total < lowestDay.total) {
        lowestDay = _DayStats(dayDate, total);
      }
      if (highestDay == null || total > highestDay.total) {
        highestDay = _DayStats(dayDate, total);
      }
    }

    final spendingDays = lastDay - noSpendDays;
    final totalSpent = monthExpenses.fold(0.0, (s, e) => s + e.amount);
    final avg = spendingDays > 0 ? totalSpent / spendingDays : 0.0;

    return _StatsData(
      overBudgetDays: overBudgetDays,
      lowestDay: lowestDay,
      highestDay: highestDay,
      avgDailySpending: avg,
      totalSpent: totalSpent,
      monthlyBudget: monthlyBudget,
      noSpendDays: noSpendDays,
      daysInMonth: daysInMonth,
    );
  }
}

// ──────────────────────────────────────────────────────── Stats Content ──────

class _StatsContent extends StatelessWidget {
  const _StatsContent({
    super.key,
    required this.stats,
    required this.currency,
    required this.month,
  });

  final _StatsData stats;
  final String currency;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    if (stats.totalSpent == 0 && stats.monthlyBudget == 0) {
      return _EmptyMonth(month: month);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        // ── Days Section ────────────────────────────────────────────
        const _SectionLabel(label: 'DAYS'),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              _StatRow(
                icon: Icons.trending_up_rounded,
                label: 'Over Budget Days',
                value: '${stats.overBudgetDays}',
                valueColor: stats.overBudgetDays > 0
                    ? AppColors.overBudget
                    : AppColors.primaryText,
              ),
              const Divider(height: 1, color: AppColors.divider),
              _StatRow(
                icon: Icons.arrow_downward_rounded,
                label: 'Lowest Expense Day',
                value: stats.lowestDay != null
                    ? '${DateFormat('MMM d').format(stats.lowestDay!.date)}  ·  ${Formatters.money(stats.lowestDay!.total, currency)}'
                    : '—',
              ),
              const Divider(height: 1, color: AppColors.divider),
              _StatRow(
                icon: Icons.arrow_upward_rounded,
                label: 'Highest Expense Day',
                value: stats.highestDay != null
                    ? '${DateFormat('MMM d').format(stats.highestDay!.date)}  ·  ${Formatters.money(stats.highestDay!.total, currency)}'
                    : '—',
              ),
              const Divider(height: 1, color: AppColors.divider),
              _StatRow(
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
        const _SectionLabel(label: 'MONTH'),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              _StatRow(
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
              _StatRow(
                icon: Icons.receipt_long_outlined,
                label: 'Total Spent',
                value: Formatters.money(stats.totalSpent, currency),
              ),
              if (stats.monthlyBudget > 0) ...[
                const Divider(height: 1, color: AppColors.divider),
                _StatRow(
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
              _StatRow(
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
          _BudgetMessage(stats: stats, currency: currency),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.label.copyWith(fontSize: 12, letterSpacing: 0.8),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
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

class _BudgetMessage extends StatelessWidget {
  const _BudgetMessage({required this.stats, required this.currency});

  final _StatsData stats;
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

class _EmptyMonth extends StatelessWidget {
  const _EmptyMonth({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_outlined,
                size: 48, color: AppColors.tertiaryText),
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
