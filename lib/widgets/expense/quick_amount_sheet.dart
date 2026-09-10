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
/// the user only types an amount and saves.
Future<void> showQuickAmountSheet(BuildContext context, String category) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
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
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    final amount = double.tryParse(text.replaceAll(',', ''));
    if (text.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount greater than zero');
      return;
    }

    await context.read<ExpenseProvider>().addExpense(
          amount: amount,
          category: widget.category,
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
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              style: AppTextStyles.amount,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '$currency ',
                prefixStyle: AppTextStyles.amount
                    .copyWith(color: AppColors.secondaryText),
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
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
