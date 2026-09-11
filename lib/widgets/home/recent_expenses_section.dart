import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_page_route.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/add_expense/add_expense_screen.dart';
import '../common/app_card.dart';
import '../common/empty_state.dart';
import '../expense/expense_tile.dart';

/// The 4 most recent expenses with a "View All" link to History.
class RecentExpensesSection extends StatelessWidget {
  const RecentExpensesSection({super.key, required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final recent = provider.recentExpenses(4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Expenses', style: AppTextStyles.bodyMedium),
            if (recent.isNotEmpty)
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View All',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (recent.isEmpty)
          const AppCard(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: EmptyState(compact: true),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (final expense in recent)
                  ExpenseTile(
                    expense: expense,
                    currency: currency,
                    showDate: true,
                    onTap: () => Navigator.of(context).push(
                      SlideUpRoute(
                        page: AddExpenseScreen(existing: expense),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
