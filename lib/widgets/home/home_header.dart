import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../providers/settings_provider.dart';

/// Branding, dynamic greeting and today's date.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select<SettingsProvider, String>((s) => s.name);
    final greeting = Formatters.greeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.darkFill,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/icon/logo.svg',
                width: 27,
                height: 27,
                colorFilter: const ColorFilter.mode(
                  AppColors.onPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('SpendWise', style: AppTextStyles.title),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          name.isEmpty ? '$greeting 👋' : '$greeting, $name 👋',
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.fullDate(DateTime.now()),
          style: AppTextStyles.bodySecondary,
        ),
      ],
    );
  }
}
