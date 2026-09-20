import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';

/// Manages user settings: name, daily target, currency and setup state.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _name = StorageService.name;
    _dailyTarget = StorageService.dailyTarget;
    _currency = StorageService.currency;
    _setupComplete = StorageService.setupComplete;
  }

  late String _name;
  late double _dailyTarget;
  late String _currency;
  late bool _setupComplete;

  String get name => _name;
  double get dailyTarget => _dailyTarget;
  String get currency => _currency;
  bool get setupComplete => _setupComplete;

  /// Returns all stored monthly budgets (used for backup export).
  Map<String, double> get monthlyBudgets => StorageService.getAllMonthlyBudgets();

  /// Returns the monthly budget for the given year/month.
  /// Returns 0 if none has been set for that month.
  double getMonthlyBudget(int year, int month) =>
      StorageService.getMonthlyBudget(year, month);

  /// Convenience getter for the current calendar month's budget.
  double get currentMonthBudget {
    final now = DateTime.now();
    return StorageService.getMonthlyBudget(now.year, now.month);
  }

  Future<void> setName(String value) async {
    _name = value.trim();
    await StorageService.setName(_name);
    notifyListeners();
  }

  Future<void> setDailyTarget(double value) async {
    _dailyTarget = value;
    await StorageService.setDailyTarget(value);
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value.trim();
    await StorageService.setCurrency(_currency);
    notifyListeners();
  }

  /// Sets the monthly budget for the current calendar month only.
  Future<void> setCurrentMonthBudget(double value) async {
    final now = DateTime.now();
    await StorageService.setMonthlyBudget(now.year, now.month, value);
    notifyListeners();
  }

  /// Called once from the setup screen.
  Future<void> completeSetup(String name) async {
    _name = name.trim();
    _setupComplete = true;
    await StorageService.setName(_name);
    await StorageService.setSetupComplete(true);
    notifyListeners();
  }

  /// Applies settings restored from a backup file.
  Future<void> applyBackup({
    required String name,
    required double dailyTarget,
    required String currency,
    required Map<String, double> monthlyBudgets,
  }) async {
    _name = name;
    _dailyTarget = dailyTarget;
    _currency = currency;
    _setupComplete = true;
    await StorageService.setName(name);
    await StorageService.setDailyTarget(dailyTarget);
    await StorageService.setCurrency(currency);
    await StorageService.setSetupComplete(true);
    await StorageService.setAllMonthlyBudgets(monthlyBudgets);
    notifyListeners();
  }
}

