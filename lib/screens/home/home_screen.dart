import 'package:flutter/material.dart';

import '../../widgets/charts/spending_overview_card.dart';
import '../../widgets/common/fade_slide_in.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/quick_add_section.dart';
import '../../widgets/home/recent_expenses_section.dart';
import '../../widgets/home/target_card.dart';

/// Home dashboard: header, target card, quick add, chart, recent
/// expenses — with a subtle staggered entrance.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          const FadeSlideIn(child: HomeHeader()),
          const SizedBox(height: 24),
          const FadeSlideIn(
            delay: Duration(milliseconds: 70),
            child: TargetCard(),
          ),
          const SizedBox(height: 24),
          const FadeSlideIn(
            delay: Duration(milliseconds: 140),
            child: QuickAddSection(),
          ),
          const SizedBox(height: 24),
          const FadeSlideIn(
            delay: Duration(milliseconds: 210),
            child: SpendingOverviewCard(),
          ),
          const SizedBox(height: 24),
          FadeSlideIn(
            delay: const Duration(milliseconds: 280),
            child: RecentExpensesSection(onViewAll: onViewAll),
          ),
        ],
      ),
    );
  }
}
