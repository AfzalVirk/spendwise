import 'package:flutter/material.dart';

/// Centralized app-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'SpendWise';

  /// Default settings.
  static const double defaultDailyTarget = 1500;
  static const String defaultCurrency = 'Rs.';

  /// Currencies offered in Settings (a custom symbol can also be typed).
  static const List<String> currencies = [
    'Rs.',
    '\$',
    '€',
    '£',
    '₹',
    'AED',
  ];

  /// Backup format.
  static const int backupVersion = 1;
}

/// Expense categories, centralized so they are easy to modify later.
class Categories {
  Categories._();

  static const String breakfast = 'Breakfast';
  static const String lunch = 'Lunch';
  static const String dinner = 'Dinner';
  static const String other = 'Other';

  static const List<String> all = [
    breakfast,
    lunch,
    dinner,
    'Entertainment',
    'Shopping',
    'Transport',
    'Travel',
    'Bills',
    'Health',
    'Education',
    'Household',
    'Gifts',
    other,
  ];

  /// Quick-add options shown on the Home dashboard.
  static const List<String> quickAdd = [breakfast, lunch, dinner, other];

  static const Map<String, IconData> icons = {
    breakfast: Icons.free_breakfast_outlined,
    lunch: Icons.lunch_dining_outlined,
    dinner: Icons.dinner_dining_outlined,
    'Entertainment': Icons.movie_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'Transport': Icons.directions_bus_outlined,
    'Travel': Icons.flight_outlined,
    'Bills': Icons.receipt_long_outlined,
    'Health': Icons.medical_services_outlined,
    'Education': Icons.school_outlined,
    'Household': Icons.home_outlined,
    'Gifts': Icons.card_giftcard_outlined,
    other: Icons.category_outlined,
  };

  static IconData iconFor(String category) =>
      icons[category] ?? Icons.category_outlined;

  static bool isValid(String category) => all.contains(category);
}
