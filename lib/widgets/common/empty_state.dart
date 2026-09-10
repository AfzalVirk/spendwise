import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'fade_slide_in.dart';

/// Clean empty-state placeholder.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title = 'Nothing here yet',
    this.message = 'Add your first expense and start tracking your spending.',
    this.icon = Icons.receipt_long_outlined,
    this.compact = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 24 : 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.subtleFill,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppTextStyles.title),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  message,
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
