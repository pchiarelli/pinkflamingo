import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_shell.dart';
import '../theme/app_theme.dart';

/// Animated launch screen: the flamingo drops in with a bounce, balances with a
/// gentle sway, and the wordmark fades up — then it hands off to the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _sway;
  late final AnimationController _exit;

  late final Animation<double> _flamingoScale;
  late final Animation<double> _flamingoFade;
  late final Animation<double> _wordFade;
  late final Animation<Offset> _wordSlide;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _sway = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _flamingoScale = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    );
    _flamingoFade = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _glow = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
    );
    _wordFade = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );
    _wordSlide = Tween(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    ));

    _run();
  }

  Future<void> _run() async {
    await _entry.forward();
    _sway.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _sway.stop();
    await _exit.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _entry.dispose();
    _sway.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_entry, _sway, _exit]),
        builder: (context, _) {
          return Opacity(
            opacity: 1 - _exit.value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFFFF0F8)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // soft pink glow behind the flamingo
                          Opacity(
                            opacity: _glow.value * 0.5,
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.pinkLight,
                                    Color(0x00FFB6DD),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: _flamingoFade.value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: _flamingoScale.value.clamp(0.0, 1.2),
                              child: Transform.rotate(
                                alignment: Alignment.bottomCenter,
                                angle: _swayAngle(),
                                child: Image.asset(
                                  'assets/images/flamingo.png',
                                  height: 200,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _wordFade,
                      child: SlideTransition(
                        position: _wordSlide,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 38,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: AppColors.magenta,
                              height: 1.05,
                            ),
                            children: [
                              TextSpan(text: 'Pink\n'),
                              TextSpan(text: 'Flamingo'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _swayAngle() {
    if (!_sway.isAnimating && _sway.value == 0) return 0;
    // gentle balance wobble around the standing leg
    return math.sin(_sway.value * math.pi) * 0.05;
  }
}
