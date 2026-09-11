import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/confirm_dialog.dart';

/// Small settings screen: name, daily target, currency, backup, restore.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editName(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final value = await _promptText(
      context,
      title: 'Your name',
      initial: settings.name,
      hint: 'John',
    );
    if (value == null || value.trim().isEmpty) return;
    await settings.setName(value);
  }

  Future<void> _editTarget(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final value = await _promptText(
      context,
      title: 'Daily target',
      initial: Formatters.number(settings.dailyTarget),
      hint: '1500',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
    );
    if (value == null) return;
    final target = double.tryParse(value.replaceAll(',', ''));
    if (target == null || target <= 0) {
      if (context.mounted) {
        _showSnack(context, 'Please enter a valid target amount');
      }
      return;
    }
    await settings.setDailyTarget(target);
  }

  Future<void> _editMonthlyBudget(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final current = settings.currentMonthBudget;
    final value = await _promptText(
      context,
      title: 'Monthly budget',
      initial: current > 0 ? Formatters.number(current) : '',
      hint: '35000',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
    );
    if (value == null) return;
    final budget = double.tryParse(value.replaceAll(',', ''));
    if (budget == null || budget <= 0) {
      if (context.mounted) {
        _showSnack(context, 'Please enter a valid budget amount');
      }
      return;
    }
    await settings.setCurrentMonthBudget(budget);
  }

  Future<void> _editCurrency(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final controller = TextEditingController(text: settings.currency);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final currency in AppConstants.currencies)
                  ActionChip(
                    label: Text(currency),
                    backgroundColor: currency == settings.currency
                        ? AppColors.subtleFill
                        : AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () => Navigator.of(dialogContext).pop(currency),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Custom symbol',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null || value.trim().isEmpty) return;
    await settings.setCurrency(value);
  }

  Future<void> _backup(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final expenses = context.read<ExpenseProvider>();
    try {
      final path = await BackupService.exportBackup(
        name: settings.name,
        dailyTarget: settings.dailyTarget,
        currency: settings.currency,
        expenses: expenses.expenses,
      );
      if (!context.mounted) return;
      if (path == null) return; // user cancelled
      _showSnack(context, 'Backup saved');
    } catch (_) {
      if (!context.mounted) return;
      _showSnack(context, 'Could not save the backup. Please try again.');
    }
  }

  Future<void> _restore(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final expenses = context.read<ExpenseProvider>();
    try {
      final backup = await BackupService.pickAndDecodeBackup();
      if (backup == null || !context.mounted) return; // cancelled

      final confirmed = await showConfirmDialog(
        context,
        title: 'Restore backup?',
        message: 'This will replace your current SpendWise data with '
            '${backup.expenses.length} expense'
            '${backup.expenses.length == 1 ? '' : 's'} from the backup.',
        confirmLabel: 'Restore',
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;

      await settings.applyBackup(
        name: backup.name,
        dailyTarget: backup.dailyTarget,
        currency: backup.currency,
      );
      await expenses.replaceAll(backup.expenses);
      if (!context.mounted) return;
      _showSnack(context, 'Backup restored');
    } on BackupException catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.message);
    } catch (_) {
      if (!context.mounted) return;
      _showSnack(context, 'Could not restore this backup file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          const Text('Settings', style: AppTextStyles.heading),
          const SizedBox(height: 20),
          Text('PROFILE', style: _sectionLabel),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Name',
                  value: settings.name,
                  onTap: () => _editName(context),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.track_changes_outlined,
                  title: 'Daily Target',
                  value:
                      Formatters.money(settings.dailyTarget, settings.currency),
                  onTap: () => _editTarget(context),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Monthly Budget',
                  value: settings.currentMonthBudget > 0
                      ? Formatters.money(
                          settings.currentMonthBudget, settings.currency)
                      : 'Not set',
                  onTap: () => _editMonthlyBudget(context),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.payments_outlined,
                  title: 'Currency',
                  value: settings.currency,
                  onTap: () => _editCurrency(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('DATA', style: _sectionLabel),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.file_upload_outlined,
                  title: 'Backup Data',
                  value: 'Export as JSON',
                  onTap: () => _backup(context),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.file_download_outlined,
                  title: 'Restore Data',
                  value: 'Import a backup file',
                  onTap: () => _restore(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'SpendWise · Offline expense tracker',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }

  static final TextStyle _sectionLabel = AppTextStyles.label.copyWith(
    fontSize: 12,
    letterSpacing: 0.8,
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryText),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: AppTextStyles.bodyMedium),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                style: AppTextStyles.bodySecondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple single-field prompt dialog.
Future<String?> _promptText(
  BuildContext context, {
  required String title,
  required String initial,
  required String hint,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: keyboardType == null
            ? TextCapitalization.words
            : TextCapitalization.none,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
