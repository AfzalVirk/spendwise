import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../models/expense.dart';

/// Data decoded from a backup file, ready to be applied.
class BackupData {
  BackupData({
    required this.name,
    required this.dailyTarget,
    required this.currency,
    required this.expenses,
  });

  final String name;
  final double dailyTarget;
  final String currency;
  final List<Expense> expenses;
}

/// Thrown for any invalid/unreadable backup file. The message is safe to
/// show to the user.
class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// JSON export/import of all app data.
class BackupService {
  BackupService._();

  /// Builds the portable JSON backup string.
  static String encodeBackup({
    required String name,
    required double dailyTarget,
    required String currency,
    required List<Expense> expenses,
  }) {
    final map = {
      'app': AppConstants.appName,
      'backupVersion': AppConstants.backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'settings': {
        'name': name,
        'dailyTarget': dailyTarget,
        'currency': currency,
      },
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Lets the user pick a destination and writes the backup there.
  /// Returns the saved path, or null if the user cancelled.
  static Future<String?> exportBackup({
    required String name,
    required double dailyTarget,
    required String currency,
    required List<Expense> expenses,
  }) async {
    final json = encodeBackup(
      name: name,
      dailyTarget: dailyTarget,
      currency: currency,
      expenses: expenses,
    );
    final bytes = utf8.encode(json);
    final fileName =
        'spendwise_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';

    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save SpendWise backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      return path;
    } on UnsupportedError {
      // Fall back to the app documents directory if the platform has no
      // save dialog.
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }
  }

  /// Lets the user pick a backup file, then validates and decodes it.
  /// Returns null if the user cancelled the picker.
  static Future<BackupData?> pickAndDecodeBackup() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select SpendWise backup',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    String content;
    try {
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        throw BackupException('Could not read the selected file.');
      }
    } on BackupException {
      rethrow;
    } catch (_) {
      throw BackupException('Could not read the selected file.');
    }

    return decodeBackup(content);
  }

  /// Validates structure + version and converts JSON into [BackupData].
  static BackupData decodeBackup(String content) {
    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } catch (_) {
      throw BackupException('This file is not valid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw BackupException('This file is not a SpendWise backup.');
    }
    if (decoded['app'] != AppConstants.appName) {
      throw BackupException('This file is not a SpendWise backup.');
    }
    if (decoded['backupVersion'] != AppConstants.backupVersion) {
      throw BackupException('This backup was made with an unsupported '
          'version of SpendWise.');
    }

    final settings = decoded['settings'];
    final rawExpenses = decoded['expenses'];
    if (settings is! Map<String, dynamic> || rawExpenses is! List) {
      throw BackupException('This backup file is incomplete or damaged.');
    }

    final expenses = <Expense>[];
    for (final item in rawExpenses) {
      if (item is! Map<String, dynamic>) {
        throw BackupException('This backup file is incomplete or damaged.');
      }
      try {
        var expense = Expense.fromJson(item);
        if (!Categories.isValid(expense.category)) {
          expense = expense.copyWith(category: Categories.other);
        }
        expenses.add(expense);
      } catch (_) {
        throw BackupException('This backup file is incomplete or damaged.');
      }
    }

    return BackupData(
      name: (settings['name'] as String?) ?? '',
      dailyTarget: (settings['dailyTarget'] as num?)?.toDouble() ??
          AppConstants.defaultDailyTarget,
      currency:
          (settings['currency'] as String?) ?? AppConstants.defaultCurrency,
      expenses: expenses,
    );
  }
}
