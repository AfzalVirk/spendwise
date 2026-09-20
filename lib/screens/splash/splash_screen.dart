import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_page_route.dart';
import '../../providers/settings_provider.dart';
import '../main/main_shell.dart';
import '../setup/setup_screen.dart';

/// Splash: Lottie logo animation, then a fade into Setup or Home.
///
/// Animation starts only when BOTH conditions are true:
///   1. First frame has been painted (addPostFrameCallback) — so the user
///      can actually see it.
///   2. Lottie has decoded the JSON and set the controller duration (onLoaded).
///
/// This eliminates the "animation already finished" bug on slow/loaded phones,
/// where the Dart isolate runs for several hundred ms before the screen
/// becomes visible.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _navigated = false;

  // Two gate flags — animation starts only when both are true.
  bool _firstFramePainted = false;
  bool _durationSet = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // Gate 1: wait until the first frame is actually on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _firstFramePainted = true;
      _tryStart();
    });
  }

  /// Called by onLoaded once Lottie has decoded the JSON.
  void _onLottieLoaded(LottieComposition composition) {
    // Gate 2: duration is now known.
    _controller.duration = composition.duration;
    _durationSet = true;
    _tryStart();
  }

  /// Starts playback only when both gates are open.
  void _tryStart() {
    if (!_firstFramePainted || !_durationSet || !mounted) return;

    // Safety fallback — navigate after 3.5 s even if something goes wrong.
    Future.delayed(const Duration(milliseconds: 3500), _navigateNext);

    // Give Android OS time to finish its window-opening transition animation.
    // Flutter's first frame renders *before* the app window is actually fully
    // visible on screen on many Android devices. This delay ensures the user
    // actually sees the animation from the start.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      // Play exactly from frame 0 and navigate once finished.
      _controller.forward(from: 0.0).whenComplete(() {
        Future.delayed(const Duration(milliseconds: 200), _navigateNext);
      });
    });
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Lottie.asset(
            'assets/animations/logoanimation.json',
            controller: _controller,
            width: 180,
            height: 180,
            onLoaded: _onLottieLoaded,
          ),
        ),
      ),
    );
  }
}
