import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shows a year-and-month picker dialog.
///
/// Returns the selected [DateTime] (normalised to day=1) or null if cancelled.
Future<DateTime?> showMonthYearPicker({
  required BuildContext context,
  required DateTime initialMonth,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => _MonthYearPickerDialog(initialMonth: initialMonth),
  );
}

class _MonthYearPickerDialog extends StatefulWidget {
  const _MonthYearPickerDialog({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _year;
  late int _selectedMonth;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr',
    'May', 'Jun', 'Jul', 'Aug',
    'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
    _selectedMonth = widget.initialMonth.month;
  }

  bool _isFutureMonth(int month) {
    final now = DateTime.now();
    return _year > now.year ||
        (_year == now.year && month > now.month);
  }

  // Real selected state during interaction
  DateTime get _current => DateTime(_year, _selectedMonth);

  void _confirm() => Navigator.of(context).pop(_current);
  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canGoForward = _year < now.year;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Year navigation ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _YearArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => setState(() => _year--),
                ),
                Text('$_year', style: AppTextStyles.title),
                _YearArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: canGoForward
                      ? () => setState(() => _year++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Month grid ───────────────────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.6,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: 12,
              itemBuilder: (_, i) {
                final month = i + 1;
                final isDisabled = _isFutureMonth(month);
                final isSelected = _selectedMonth == month;

                return GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () => setState(() => _selectedMonth = month),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.darkFill
                          : AppColors.subtleFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _monthNames[i],
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? AppColors.tertiaryText
                            : isSelected
                                ? AppColors.onPrimary
                                : AppColors.primaryText,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Actions ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.darkFill,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isFutureMonth(_selectedMonth) ? null : _confirm,
                  child: const Text('Go'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _YearArrow extends StatelessWidget {
  const _YearArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.subtleFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? AppColors.primaryText : AppColors.tertiaryText,
        ),
      ),
    );
  }
}
