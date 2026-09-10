import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../common/app_card.dart';

enum ChartRange { week, month }

/// Home dashboard spending overview with a Week | Month toggle and an
/// animated monochrome bar chart driven by real stored expenses.
class SpendingOverviewCard extends StatefulWidget {
  const SpendingOverviewCard({super.key});

  @override
  State<SpendingOverviewCard> createState() => _SpendingOverviewCardState();
}

class _SpendingOverviewCardState extends State<SpendingOverviewCard> {
  ChartRange _range = ChartRange.week;

  static const List<String> _weekLabels = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currency = context.watch<SettingsProvider>().currency;

    final isWeek = _range == ChartRange.week;
    final values =
        isWeek ? provider.weeklyChartData() : provider.monthlyChartData();
    final labels =
        isWeek ? _weekLabels : [for (var i = 1; i <= values.length; i++) 'W$i'];
    final total = isWeek ? provider.weekTotal : provider.monthTotal;
    final maxValue = values.fold<double>(0, (max, v) => v > max ? v : max);
    final hasData = maxValue > 0;

    // Index highlighted in solid black: today's weekday or current week.
    final activeIndex = isWeek
        ? DateTime.now().weekday - 1
        : ((DateTime.now().day - 1) / 7).floor();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spending Overview', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.money(total, currency)} '
                      '${isWeek ? 'this week' : 'this month'}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              _RangeToggle(
                range: _range,
                onChanged: (range) => setState(() => _range = range),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: hasData
                ? _AnimatedBars(
                    key: ValueKey(_range),
                    values: values,
                    labels: labels,
                    maxValue: maxValue,
                    activeIndex: activeIndex,
                    currency: currency,
                  )
                : Center(
                    child: Text(
                      isWeek
                          ? 'No spending recorded this week'
                          : 'No spending recorded this month',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.range, required this.onChanged});

  final ChartRange range;
  final ValueChanged<ChartRange> onChanged;

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
          _toggleItem(context, 'Week', ChartRange.week),
          _toggleItem(context, 'Month', ChartRange.month),
        ],
      ),
    );
  }

  Widget _toggleItem(BuildContext context, String label, ChartRange value) {
    final selected = range == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

/// Bars that grow upward when the chart (re)appears.
class _AnimatedBars extends StatelessWidget {
  const _AnimatedBars({
    super.key,
    required this.values,
    required this.labels,
    required this.maxValue,
    required this.activeIndex,
    required this.currency,
  });

  final List<double> values;
  final List<String> labels;
  final double maxValue;
  final int activeIndex;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return BarChart(
          BarChartData(
            maxY: maxValue * 1.2,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.darkFill,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    Formatters.money(values[group.x], currency),
                    AppTextStyles.caption.copyWith(color: AppColors.onPrimary),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[index],
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: index == activeIndex
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: index == activeIndex
                              ? AppColors.primaryText
                              : AppColors.secondaryText,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < values.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i] * t,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      color: i == activeIndex
                          ? AppColors.chartBarActive
                          : AppColors.chartBar,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
