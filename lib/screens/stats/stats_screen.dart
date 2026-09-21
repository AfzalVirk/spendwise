import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/stats/month_selector.dart';
import '../../widgets/stats/month_year_picker.dart';
import '../../widgets/stats/stats_content.dart';
import '../../widgets/stats/stats_data.dart';

/// Stats screen: month-by-month spending and budget summary.
///
/// Widget hierarchy:
///   StatsScreen (screen / StatefulWidget)
///     ├── MonthSelector        ← lib/widgets/stats/month_selector.dart
///     └── StatsContent         ← lib/widgets/stats/stats_content.dart
///           ├── StatsRow
///           ├── StatsSectionLabel
///           ├── StatsBudgetMessage
///           └── StatsEmptyMonth
///
/// Data:
///   StatsData.compute()        ← lib/widgets/stats/stats_data.dart
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  // The month currently displayed.
  late DateTime _month;

  // +1 = forward (new content enters from right),
  // -1 = backward (new content enters from left).
  int _slideDirection = 0;

  // Entrance animation for the header only.
  late final AnimationController _entranceCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _headerFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _goPrev() {
    setState(() {
      _slideDirection = -1;
      _month = DateTime(_month.year, _month.month - 1);
    });
  }

  void _goNext() {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() {
      _slideDirection = 1;
      _month = next;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthYearPicker(
      context: context,
      initialMonth: _month,
    );
    if (picked == null || !mounted) return;
    // Determine slide direction based on whether picked month is before or after.
    final direction = picked.isBefore(_month) ? -1 : 1;
    setState(() {
      _slideDirection = direction;
      _month = picked;
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currency;
    final dailyTarget = settings.dailyTarget;
    final monthlyBudget = settings.getMonthlyBudget(_month.year, _month.month);

    final monthExpenses = expenses
        .where((e) =>
            e.dateTime.year == _month.year && e.dateTime.month == _month.month)
        .toList();

    final stats = StatsData.compute(
      monthExpenses: monthExpenses,
      month: _month,
      dailyTarget: dailyTarget,
      monthlyBudget: monthlyBudget,
    );

    return SafeArea(
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Stats', style: AppTextStyles.heading),
                        const Spacer(),
                        IconButton(
                          onPressed: _pickMonth,
                          icon: const Icon(Icons.calendar_month_outlined),
                          tooltip: 'Jump to month',
                          style: IconButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFF1F1F2), // AppColors.subtleFill
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MonthSelector(
                      month: _month,
                      isCurrentMonth: _isCurrentMonth,
                      onPrev: _goPrev,
                      onNext: _goNext,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Content with horizontal slide on month change ─────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final inSlide = Tween<Offset>(
                  begin: Offset(_slideDirection.toDouble(), 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: inSlide, child: child),
                );
              },
              child: StatsContent(
                key: ValueKey('${_month.year}-${_month.month}'),
                stats: stats,
                currency: currency,
                month: _month,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
