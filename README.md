# SpendWise

A simple, fast, offline personal expense tracker built with Flutter.

Open the app → immediately understand today's spending → add an expense in seconds.

## Stack

- Flutter + Dart (null safety)
- Provider for state management
- Hive for offline local storage (no backend, no internet required)
- fl_chart for the dashboard chart
- intl for date/currency formatting
- Lottie for the splash logo animation
- file_picker + path_provider for JSON backup/restore

## Getting started

```
flutter pub get
flutter run
```

No code generation is required — the Hive `ExpenseAdapter` is hand-written.

Notes:

- **Gradle**: the wrapper is pinned to **Gradle 9.1.0**
  (`android/gradle/wrapper/gradle-wrapper.properties`) with AGP 8.13.0 and
  Kotlin 2.2.20. The Flutter tool injects the missing `gradlew` scripts and
  wrapper jar automatically on the first build, keeping the pinned version.
- **Fonts**: Open Sauce / Peace Sans are configured in
  `lib/core/theme/app_fonts.dart`. Drop the `.ttf` files into `assets/fonts/`
  and uncomment the `fonts:` section in `pubspec.yaml` to activate them; the
  app uses the default system font until then.

## Structure

```
lib/
├── main.dart                 # Hive init + MultiProvider + MaterialApp
├── core/                     # theme (colors/fonts/text styles/ThemeData),
│                             # constants (categories, currencies), utils
├── models/expense.dart       # Expense + hand-written Hive TypeAdapter
├── providers/                # ExpenseProvider, SettingsProvider
├── services/                 # HiveService, StorageService, BackupService
├── screens/                  # splash, setup, main shell, home,
│                             # add_expense (add + edit), history, settings
└── widgets/                  # common / home / expense / charts widgets
```

## Data

- Expenses and settings persist in Hive boxes (`expensesBox`, `settingsBox`).
- Backup exports everything as portable JSON; restore validates the file and
  asks for confirmation before replacing data.
