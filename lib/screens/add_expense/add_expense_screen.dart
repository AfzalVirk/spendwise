import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/success_overlay.dart';
import '../../widgets/expense/category_grid.dart';

/// Full add/edit expense screen. Pass [existing] to edit an expense,
/// or [initialCategory] to pre-select a category.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.existing, this.initialCategory});

  final Expense? existing;
  final String? initialCategory;

  bool get isEditing => existing != null;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _category;
  late DateTime _dateTime;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amountController = TextEditingController(
      text: existing == null ? '' : Formatters.number(existing.amount),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _category =
        existing?.category ?? widget.initialCategory ?? Categories.breakfast;
    _dateTime = existing?.dateTime ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    final text = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(text);
    if (text.isEmpty || amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter a valid amount greater than zero');
      return;
    }

    final provider = context.read<ExpenseProvider>();
    if (widget.isEditing) {
      await provider.updateExpense(
        widget.existing!.copyWith(
          amount: amount,
          category: _category,
          dateTime: _dateTime,
          note: _noteController.text.trim(),
        ),
      );
    } else {
      await provider.addExpense(
        amount: amount,
        category: _category,
        dateTime: _dateTime,
        note: _noteController.text,
      );
    }

    if (!mounted) return;
    showSuccessCheck(context);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete expense?',
      message: 'This will permanently remove this expense.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<ExpenseProvider>().deleteExpense(widget.existing!.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currency;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete expense',
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  // Amount — the visual focus of the screen.
                  const Text('Amount', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    autofocus: !widget.isEditing,
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
                      errorText: _amountError,
                    ),
                    onChanged: (_) {
                      if (_amountError != null) {
                        setState(() => _amountError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Category', style: AppTextStyles.label),
                  const SizedBox(height: 10),
                  CategoryGrid(
                    selected: _category,
                    onSelected: (category) =>
                        setState(() => _category = category),
                  ),
                  const SizedBox(height: 24),
                  const Text('Date & Time', style: AppTextStyles.label),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerButton(
                          icon: Icons.calendar_today_outlined,
                          label: Formatters.friendlyDate(_dateTime),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PickerButton(
                          icon: Icons.schedule_outlined,
                          label: Formatters.time(_dateTime),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child:
                      Text(widget.isEditing ? 'Save Changes' : 'Save Expense'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.secondaryText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
