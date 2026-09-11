
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../core/utils/formatters.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';

enum HistoryFilter { today, yesterday, pickDate }

/// Manages all expense data and derived totals.
class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider() {
    _box = HiveService.expensesBox;
    _reload();
  }

  late final Box<Expense> _box;

  /// All expenses, newest first.
  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;
  bool get isEmpty => _expenses.isEmpty;

  void _reload() {
    _expenses = _box.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  // ---------------------------------------------------------------- CRUD

  Future<void> addExpense({
    required double amount,
    required String category,
    DateTime? dateTime,
    String? note,
  }) async {
    final expense = Expense(
      id: Expense.newId(),
      amount: amount,
      category: category,
      dateTime: dateTime ?? DateTime.now(),
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
    );
    await _box.put(expense.id, expense);
    _reload();
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _box.put(expense.id, expense);
    _reload();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
    _reload();
    notifyListeners();
  }

  /// Replaces all stored expenses (used by backup restore).
  Future<void> replaceAll(List<Expense> newExpenses) async {
    await _box.clear();
    await _box.putAll({for (final e in newExpenses) e.id: e});
    _reload();
    notifyListeners();
  }

  // -------------------------------------------------------------- Totals

  double _sum(Iterable<Expense> items) =>
      items.fold(0, (total, e) => total + e.amount);

  double get todayTotal =>
      _sum(_expenses.where((e) => DateUtilsX.isToday(e.dateTime)));

  double get yesterdayTotal {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _sum(
      _expenses.where((e) => DateUtilsX.isSameDay(e.dateTime, yesterday)),
    );
  }

  double get weekTotal =>
      _sum(_expenses.where((e) => DateUtilsX.isInCurrentWeek(e.dateTime)));

  double get monthTotal =>
      _sum(_expenses.where((e) => DateUtilsX.isInCurrentMonth(e.dateTime)));

  /// Remaining budget for today; negative means over target.
  double remainingToday(double dailyTarget) => dailyTarget - todayTotal;

  /// Fraction of the daily target spent today (may exceed 1.0).
  double progressToday(double dailyTarget) =>
      dailyTarget <= 0 ? 0 : todayTotal / dailyTarget;

  bool isOverTarget(double dailyTarget) => todayTotal > dailyTarget;

  // --------------------------------------------------------- Monthly budget helpers

  /// Remaining from the monthly budget; negative means over budget.
  double remainingThisMonth(double monthlyBudget) =>
      monthlyBudget - monthTotal;

  /// Fraction of the monthly budget spent (may exceed 1.0).
  double progressThisMonth(double monthlyBudget) =>
      monthlyBudget <= 0 ? 0 : monthTotal / monthlyBudget;

  bool isOverMonthlyBudget(double monthlyBudget) =>
      monthTotal > monthlyBudget;

  // ------------------------------------------------------------- Queries

  List<Expense> recentExpenses([int count = 4]) =>
      _expenses.take(count).toList();

  /// Returns expenses filtered by the given [HistoryFilter].
  /// [pickedDate] is required when filter is [HistoryFilter.pickDate].
  List<Expense> expensesForFilter(
    HistoryFilter filter, {
    DateTime? pickedDate,
  }) {
    switch (filter) {
      case HistoryFilter.today:
        return _expenses
            .where((e) => DateUtilsX.isToday(e.dateTime))
            .toList();
      case HistoryFilter.yesterday:
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        return _expenses
            .where((e) => DateUtilsX.isSameDay(e.dateTime, yesterday))
            .toList();
      case HistoryFilter.pickDate:
        if (pickedDate == null) return [];
        return _expenses
            .where((e) => DateUtilsX.isSameDay(e.dateTime, pickedDate))
            .toList();
    }
  }

  /// Returns all expenses for a specific calendar day.
  List<Expense> expensesForDate(DateTime date) =>
      _expenses
          .where((e) => DateUtilsX.isSameDay(e.dateTime, date))
          .toList();

  /// Groups a (newest-first) list by calendar day, preserving order.
  Map<DateTime, List<Expense>> groupByDate(List<Expense> items) {
    final map = <DateTime, List<Expense>>{};
    for (final e in items) {
      final day = DateUtilsX.dayOf(e.dateTime);
      map.putIfAbsent(day, () => []).add(e);
    }
    return map;
  }

  // --------------------------------------------------------- Chart data

  /// Totals for Mon..Sun of the current week (7 values).
  List<double> weeklyChartData() {
    final start = DateUtilsX.startOfWeek(DateTime.now());
    final totals = List<double>.filled(7, 0);
    for (final e in _expenses) {
      final day = DateUtilsX.dayOf(e.dateTime);
      final index = day.difference(start).inDays;
      if (index >= 0 && index < 7) {
        totals[index] += e.amount;
      }
    }
    return totals;
  }

  /// Totals per week of the current month (4-5 values, W1..Wn).
  List<double> monthlyChartData() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final weekCount = ((daysInMonth + 6) / 7).floor();
    final totals = List<double>.filled(weekCount, 0);
    for (final e in _expenses) {
      if (!DateUtilsX.isInCurrentMonth(e.dateTime)) continue;
      final index = ((e.dateTime.day - 1) / 7).floor();
      if (index >= 0 && index < weekCount) {
        totals[index] += e.amount;
      }
    }
    return totals;
  }
}

