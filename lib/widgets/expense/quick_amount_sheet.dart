import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../common/success_overlay.dart';

/// Bottom sheet for lightning-fast quick add: category is already known,
/// the user only types an amount (and optional note) and saves.
Future<void> showQuickAmountSheet(BuildContext context, String category) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _QuickAmountSheet(category: category),
    ),
  );
}

class _QuickAmountSheet extends StatefulWidget {
  const _QuickAmountSheet({required this.category});

  final String category;

  @override
  State<_QuickAmountSheet> createState() => _QuickAmountSheetState();
}

class _QuickAmountSheetState extends State<_QuickAmountSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(text);
    if (text.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount greater than zero');
      return;
    }

    final note = _noteController.text.trim();
    await context.read<ExpenseProvider>().addExpense(
          amount: amount,
          category: widget.category,
          note: note.isEmpty ? null : note,
        );
    if (!mounted) return;
    showSuccessCheck(context);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currency;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category icon + name
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.subtleFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Categories.iconFor(widget.category),
                    size: 20,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(width: 12),
                Text(widget.category, style: AppTextStyles.title),
              ],
            ),
            const SizedBox(height: 20),

            // ── Amount field — same style as AddExpenseScreen ──────────────
            const Text('Amount', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              style: AppTextStyles.largeAmount.copyWith(fontSize: 34),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: AppTextStyles.largeAmount.copyWith(
                  fontSize: 34,
                  color: AppColors.tertiaryText,
                ),
                prefixText: '$currency ',
                prefixStyle: AppTextStyles.largeAmount.copyWith(
                  fontSize: 34,
                  color: AppColors.secondaryText,
                ),
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _save(),
            ),

            const SizedBox(height: 20),

            // ── Note field ────────────────────────────────────────────────
            const Text('Note (optional)', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 100,
              decoration: const InputDecoration(
                hintText: 'e.g. Coffee with friends',
                counterText: '',
              ),
              onSubmitted: (_) => _save(),
            ),

            const SizedBox(height: 20),

            // ── Save button ───────────────────────────────────────────────
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
