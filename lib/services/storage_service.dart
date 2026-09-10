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
}
