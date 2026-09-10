import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_page_route.dart';
import '../../providers/settings_provider.dart';
import '../main/main_shell.dart';
import '../setup/setup_screen.dart';

/// Splash: supplied Lottie logo animation + app name, then a fade into
/// Setup (first launch) or Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Hard upper bound in case the animation fails to load.
    Future.delayed(const Duration(milliseconds: 2200), _navigateNext);
  }

  void _navigateNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final setupComplete = context.read<SettingsProvider>().setupComplete;
    Navigator.of(context).pushReplacement(
      FadeSlideUpRoute(
        page: setupComplete ? const MainShell() : const SetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/logoanimation.json',
                width: 180,
                height: 180,
                repeat: false,
                onLoaded: (composition) {
                  // Leave shortly after the animation completes,
                  // staying in the ~1.5-2s target window.
                  final duration = composition.duration;
                  final wait = duration > const Duration(milliseconds: 1900)
                      ? const Duration(milliseconds: 1900)
                      : duration + const Duration(milliseconds: 200);
                  Future.delayed(wait, _navigateNext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
