import '../../../models/expense.dart';

/// A single day's spending total, used in stats calculations.
class DayStats {
  const DayStats(this.date, this.total);

  final DateTime date;
  final double total;
}

/// Pre-computed statistics for a single calendar month.
class StatsData {
  const StatsData({
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
  final DayStats? lowestDay;
  final DayStats? highestDay;
  final double avgDailySpending;
  final double totalSpent;
  final double monthlyBudget;
  final int noSpendDays;
  final int daysInMonth;

  double get saved => monthlyBudget > 0 ? monthlyBudget - totalSpent : 0;
  bool get isOverMonthlyBudget =>
      monthlyBudget > 0 && totalSpent > monthlyBudget;

  factory StatsData.compute({
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
      dayTotals[e.dateTime.day] =
          (dayTotals[e.dateTime.day] ?? 0) + e.amount;
    }

    int overBudgetDays = 0;
    int noSpendDays = 0;
    DayStats? lowestDay;
    DayStats? highestDay;

    for (int d = 1; d <= lastDay; d++) {
      final total = dayTotals[d] ?? 0;
      if (total == 0) {
        noSpendDays++;
        continue;
      }
      if (dailyTarget > 0 && total > dailyTarget) overBudgetDays++;

      final dayDate = DateTime(month.year, month.month, d);
      if (lowestDay == null || total < lowestDay.total) {
        lowestDay = DayStats(dayDate, total);
      }
      if (highestDay == null || total > highestDay.total) {
        highestDay = DayStats(dayDate, total);
      }
    }

    final spendingDays = lastDay - noSpendDays;
    final totalSpent = monthExpenses.fold(0.0, (s, e) => s + e.amount);
    final avg = spendingDays > 0 ? totalSpent / spendingDays : 0.0;

    return StatsData(
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
