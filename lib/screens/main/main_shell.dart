import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_page_route.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../add_expense/add_expense_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

/// Root shell: Home | History | [Add] | Stats | Settings
/// Nav bar is a floating pill.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openAddExpense() {
    Navigator.of(context).push(SlideUpRoute(page: const AddExpenseScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Standard Android UX: if not on Home tab, go back to Home first.
        if (_index != 0) {
          setState(() => _index = 0);
          return;
        }

        // On Home tab: confirm exit.
        final shouldExit = await showConfirmDialog(
          context,
          title: 'Exit SpendWise?',
          message: 'Are you sure you want to exit the app?',
          confirmLabel: 'Yes',
          cancelLabel: 'No',
        );
        if (shouldExit) SystemNavigator.pop();
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.background,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: switch (_index) {
              0 => HomeScreen(onViewAll: () => setState(() => _index = 1)),
              1 => const HistoryScreen(),
              2 => const StatsScreen(),
              _ => const SettingsScreen(),
            },
          ),
        ),

        // ── Bottom app bar ────────────────────────────────────────────
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 11),
            child: _FloatingNavBar(
              index: _index,
              onChanged: (i) => setState(() => _index = i),
              onAdd: _openAddExpense,
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────── Floating nav bar ─

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.index,
    required this.onChanged,
    required this.onAdd,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onAdd;

  // Left side: indices 0 & 1  |  Right side: indices 2 & 3
  static const _left = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    (
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'History'
    ),
  ];

  static const _right = [
    (
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Stats'
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: AppColors.darkFill,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Left items ────────────────────────────────────────────
          for (var i = 0; i < _left.length; i++)
            Expanded(
              child: _NavItem(
                icon: _left[i].icon,
                activeIcon: _left[i].activeIcon,
                label: _left[i].label,
                selected: i == index,
                onTap: () => onChanged(i),
              ),
            ),

          // ── Centre Add Button ─────────────────────────────────────
          _AddExpenseButton(onPressed: onAdd),

          // ── Right items ───────────────────────────────────────────
          for (var i = 0; i < _right.length; i++)
            Expanded(
              child: _NavItem(
                icon: _right[i].icon,
                activeIcon: _right[i].activeIcon,
                label: _right[i].label,
                selected: (i + 2) == index,
                onTap: () => onChanged(i + 2),
              ),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────── Nav item ─────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : AppColors.tertiaryText;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Icon(
                selected ? activeIcon : icon,
                key: ValueKey(selected),
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.5,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── Centre add button ─

/// Press-scaling circular button. White background, black "+" icon.
class _AddExpenseButton extends StatefulWidget {
  const _AddExpenseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AddExpenseButton> createState() => _AddExpenseButtonState();
}

class _AddExpenseButtonState extends State<_AddExpenseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 110),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppColors.onPrimary, // white
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_rounded,
            size: 28,
            color: AppColors.darkFill, // black
          ),
        ),
      ),
    );
  }
}
