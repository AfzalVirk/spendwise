import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_page_route.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/fade_slide_in.dart';
import '../../widgets/expense/expense_tile.dart';
import '../add_expense/add_expense_screen.dart';

/// Continuous scrollable history grouped by date, with simple filters.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _filter = HistoryFilter.month;

  static const _filters = [
    (filter: HistoryFilter.today, label: 'Today'),
    (filter: HistoryFilter.week, label: 'This Week'),
    (filter: HistoryFilter.month, label: 'This Month'),
    (filter: HistoryFilter.all, label: 'All'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currency = context.watch<SettingsProvider>().currency;

    final filtered = provider.expensesForFilter(_filter);
    final grouped = provider.groupByDate(filtered);
    final total = filtered.fold<double>(0, (sum, e) => sum + e.amount);

    // Flatten groups into a single list of rows for ListView.builder.
    final rows = <_HistoryRow>[];
    grouped.forEach((day, expenses) {
      rows.add(_HistoryRow.header(
        day,
        expenses.fold<double>(0, (sum, e) => sum + e.amount),
      ));
      for (final e in expenses) {
        rows.add(_HistoryRow.expense(e));
      }
    });

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('History', style: AppTextStyles.heading),
                const SizedBox(height: 4),
                Text(
                  '${filtered.length} expense${filtered.length == 1 ? '' : 's'}'
                  ' · ${Formatters.money(total, currency)}',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final item in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: item.label,
                      selected: _filter == item.filter,
                      onTap: () => setState(() => _filter = item.filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: rows.isEmpty
                  ? EmptyState(
                      key: ValueKey('empty-$_filter'),
                      title: 'Nothing here yet',
                      message: _filter == HistoryFilter.all
                          ? 'Add your first expense and start tracking '
                              'your spending.'
                          : 'No expenses recorded for this period.',
                    )
                  : ListView.builder(
                      key: ValueKey(_filter),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        if (row.isHeader) {
                          return _DateHeader(
                            date: row.date!,
                            total: row.dayTotal!,
                            currency: currency,
                            isFirst: index == 0,
                          );
                        }
                        return ExpenseTile(
                          expense: row.expense!,
                          currency: currency,
                          onTap: () => Navigator.of(context).push(
                            SlideUpRoute(
                              page:
                                  AddExpenseScreen(existing: row.expense),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow {
  _HistoryRow.header(this.date, this.dayTotal)
      : expense = null,
        isHeader = true;

  _HistoryRow.expense(this.expense)
      : date = null,
        dayTotal = null,
        isHeader = false;

  final bool isHeader;
  final DateTime? date;
  final double? dayTotal;
  final Expense? expense;
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.date,
    required this.total,
    required this.currency,
    required this.isFirst,
  });

  final DateTime date;
  final double total;
  final String currency;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 8 : 24, bottom: 6),
      child: FadeSlideIn(
        offset: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Formatters.friendlyDate(date).toUpperCase(),
              style: AppTextStyles.label.copyWith(
                letterSpacing: 0.8,
                fontSize: 12,
              ),
            ),
            Text(
              Formatters.money(total, currency),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.darkFill : AppColors.surface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: selected ? AppColors.darkFill : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.onPrimary : AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}
