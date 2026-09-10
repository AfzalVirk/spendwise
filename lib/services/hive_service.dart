import 'package:hive_flutter/hive_flutter.dart';

import '../models/expense.dart';

/// Owns Hive initialization and box access.
class HiveService {
  HiveService._();

  static const String expensesBoxName = 'expensesBox';
  static const String settingsBoxName = 'settingsBox';

  /// Must be called once before runApp, after
  /// WidgetsFlutterBinding.ensureInitialized().
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    await Hive.openBox<Expense>(expensesBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
  }

  static Box<Expense> get expensesBox => Hive.box<Expense>(expensesBoxName);

  static Box<dynamic> get settingsBox => Hive.box<dynamic>(settingsBoxName);
}
