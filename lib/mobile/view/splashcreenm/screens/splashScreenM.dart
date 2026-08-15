import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../design_system/design_system.dart';
import '../brand_intro_config.dart';
import '../splashscreenblocm/splashscreenBlocM.dart';
import '../splashscreenblocm/splashscreenStateM.dart';

/// Pipeline de lancement :
/// 1. Native : blanc + soutra_splash centré (ratio conservé)
/// 2. SplashShell Flutter : immédiatement même logo (zéro vide)
/// 3. Lottie FULL/SHORT en overlay
///
/// Règles logo : BoxFit.contain uniquement, largeur max seule, jamais fill.
class SplashScreenM extends StatefulWidget {
  const SplashScreenM({super.key});

  @override
  State<SplashScreenM> createState() => _SplashScreenMState();
}

class _SplashScreenMState extends State<SplashScreenM>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  SplashReadyM? _ready;
  bool _navigated = false;
  bool _showFull = true;
  bool _skipRequested = false;
  bool _animStarted = false;
  bool _animCompleted = false;
  bool _lottieFailed = false;
  bool _lottieVisible = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animCompleted = true;
          _tryNavigate(reason: 'anim_complete');
        }
      });

    _loadIntroMode();

    Future<void>.delayed(BrandIntroConfig.absoluteReadyTimeout, () {
      if (!mounted || _navigated) return;
      _tryNavigate(reason: 'timeout');
    });
  }

  Future<void> _loadIntroMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final seen = prefs.getInt(BrandIntroConfig.prefSeenVersion) ?? 0;
    final full = seen < BrandIntroConfig.brandIntroVersion;
    if (full == _showFull || _animStarted) return;
    setState(() => _showFull = full);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onReady(SplashReadyM state) {
    _ready = state;
    if (!_animStarted && state.showFullIntro != _showFull) {
      setState(() => _showFull = state.showFullIntro);
    }
    _tryNavigate(reason: 'app_ready');
  }

  void _onSkipTap() {
    if (!_showFull || _navigated) return;
    _skipRequested = true;
    _tryNavigate(reason: 'skip');
  }

  void _startAnim(Duration d) {
    if (_animStarted || _navigated) return;
    _anim.duration = d;
    _animStarted = true;
    _animCompleted = false;
    if (!_lottieVisible) {
      setState(() => _lottieVisible = true);
    }
    _anim.forward(from: 0);
  }

  Future<void> _tryNavigate({required String reason}) async {
    if (_navigated || !mounted) return;
    final ready = _ready;
    final timedOut = reason == 'timeout';
    if (ready == null && !timedOut) return;

    final animDone = _animCompleted || _skipRequested || timedOut;
    if (!animDone) return;

    if (timedOut && !_animStarted && !_skipRequested) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || _navigated) return;
    }

    final dest = ready?.destination ?? '/homepage';
    final extra = ready?.destinationExtra;
    final wasFull = ready?.showFullIntro ?? _showFull;

    _navigated = true;

    if (wasFull) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        BrandIntroConfig.prefSeenVersion,
        BrandIntroConfig.brandIntroVersion,
      );
    }

    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    if (extra != null) {
      context.go(dest, extra: extra);
    } else {
      context.go(dest);
    }
  }

  Duration _clampDuration(Duration raw) {
    final max = _showFull ? BrandIntroConfig.fullMax : BrandIntroConfig.shortMax;
    final minTarget =
        _showFull ? BrandIntroConfig.fullTarget : BrandIntroConfig.shortTarget;
    var d = raw;
    if (d > max) d = max;
    if (d < const Duration(milliseconds: 400)) d = minTarget;
    return d;
  }

  /// Largeur max seule — la hauteur suit le ratio du PNG.
  double _logoMaxWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final fromFraction = w * BrandIntroConfig.logoWidthFraction;
    final maxByPadding = w - (BrandIntroConfig.logoHorizontalPadding * 2);
    return fromFraction
        .clamp(168.0, BrandIntroConfig.logoMaxWidth)
        .clamp(0.0, maxByPadding);
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = _logoMaxWidth(context);

    return BlocListener<SplashscreenBlocM, SplashscreenStateM>(
      listener: (context, state) {
        if (state is SplashReadyM) _onReady(state);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onSkipTap,
        child: Scaffold(
          backgroundColor: SDColors.white,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BrandIntroConfig.logoHorizontalPadding,
                ),
                child: _buildSplashShell(maxWidth),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// SplashShell : logo toujours visible → Lottie overlay.
  Widget _buildSplashShell(double maxWidth) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          BrandIntroConfig.splashMarkAsset,
          width: maxWidth,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
        if (!_lottieFailed) _buildLottieOverlay(maxWidth),
      ],
    );
  }

  Widget _buildLottieOverlay(double maxWidth) {
    final path = BrandIntroConfig.lottiePath(full: _showFull);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _lottieVisible ? 1 : 0,
        duration: const Duration(milliseconds: 120),
        child: Lottie.asset(
          path,
          width: maxWidth,
          controller: _anim,
          repeat: false,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          onLoaded: (composition) {
            if (!mounted || _navigated) return;
            _startAnim(_clampDuration(composition.duration));
          },
          errorBuilder: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _lottieFailed) return;
              setState(() => _lottieFailed = true);
              _startAnim(
                _showFull
                    ? BrandIntroConfig.fullTarget
                    : BrandIntroConfig.shortTarget,
              );
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
