import '../core/constants/app_constants.dart';
import 'hive_service.dart';

/// Thin typed wrapper over the settings box.
class StorageService {
  StorageService._();

  static const String _keyName = 'name';
  static const String _keyDailyTarget = 'dailyTarget';
  static const String _keyCurrency = 'currency';
  static const String _keySetupComplete = 'setupComplete';

  static String get name =>
      HiveService.settingsBox.get(_keyName, defaultValue: '') as String;

  static double get dailyTarget => (HiveService.settingsBox.get(
        _keyDailyTarget,
        defaultValue: AppConstants.defaultDailyTarget,
      ) as num)
          .toDouble();

  static String get currency => HiveService.settingsBox.get(
        _keyCurrency,
        defaultValue: AppConstants.defaultCurrency,
      ) as String;

  static bool get setupComplete => HiveService.settingsBox
      .get(_keySetupComplete, defaultValue: false) as bool;

  static Future<void> setName(String value) =>
      HiveService.settingsBox.put(_keyName, value);

  static Future<void> setDailyTarget(double value) =>
      HiveService.settingsBox.put(_keyDailyTarget, value);

  static Future<void> setCurrency(String value) =>
      HiveService.settingsBox.put(_keyCurrency, value);

  static Future<void> setSetupComplete(bool value) =>
      HiveService.settingsBox.put(_keySetupComplete, value);

  // --------------------------------------------------------- Monthly budget

  /// Returns the key used to store a specific month's budget.
  /// Example: "monthlyBudget_2026_9" for September 2026.
  static String _monthlyBudgetKey(int year, int month) =>
      'monthlyBudget_${year}_$month';

  /// Returns the monthly budget for the given year/month,
  /// or 0 if none has been set for that month yet.
  static double getMonthlyBudget(int year, int month) {
    final raw = HiveService.settingsBox
        .get(_monthlyBudgetKey(year, month), defaultValue: 0.0);
    return (raw as num).toDouble();
  }

  /// Saves the monthly budget specifically for the given year/month.
  static Future<void> setMonthlyBudget(int year, int month, double value) =>
      HiveService.settingsBox.put(_monthlyBudgetKey(year, month), value);

  /// Returns a map of all stored monthly budgets.
  static Map<String, double> getAllMonthlyBudgets() {
    final Map<String, double> budgets = {};
    for (final key in HiveService.settingsBox.keys) {
      if (key is String && key.startsWith('monthlyBudget_')) {
        budgets[key] = (HiveService.settingsBox.get(key) as num).toDouble();
      }
    }
    return budgets;
  }

  /// Sets multiple monthly budgets at once (used for backup restore).
  static Future<void> setAllMonthlyBudgets(Map<String, double> budgets) async {
    for (final entry in budgets.entries) {
      await HiveService.settingsBox.put(entry.key, entry.value);
    }
  }
}
