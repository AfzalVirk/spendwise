import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';

/// Money value that counts up/down smoothly when it changes.
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({
    super.key,
    required this.value,
    required this.currency,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  final double value;
  final String currency;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return Text(Formatters.money(animated, currency), style: style);
      },
    );
  }
}
