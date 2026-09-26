import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/fcm_route_policy.dart';
import 'package:sdealsmobile/data/services/fcm_service.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/mobile/view/splashcreenm/brand_intro_config.dart';

import 'splashscreenEventM.dart';
import 'splashscreenStateM.dart';

class SplashscreenBlocM extends Bloc<SplashscreenEventM, SplashscreenStateM> {
  SplashscreenBlocM({required this.authCubit}) : super(SplashInitialM()) {
    on<LoadSplashM>(_onLoad);
  }

  final AuthCubit authCubit;

  Future<void> _onLoad(
    LoadSplashM event,
    Emitter<SplashscreenStateM> emit,
  ) async {
    emit(SplashLoadingM());

    final prefs = await SharedPreferences.getInstance();
    final seenVersion = prefs.getInt(BrandIntroConfig.prefSeenVersion) ?? 0;
    final showFull = seenVersion < BrandIntroConfig.brandIntroVersion;

    await _waitAuthSettled();

    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    final deepLink = FcmService.instance.consumePendingLaunchRoute();
    final destination = _resolveDestination(
      deepLink: deepLink,
      onboardingCompleted: onboardingCompleted,
    );
    if (destination.hold != null) {
      FcmService.instance.holdDestination(destination.hold!);
    }

    emit(SplashReadyM(
      showFullIntro: showFull,
      destination: destination.route,
      destinationExtra: destination.extra,
    ));
  }

  Future<void> _waitAuthSettled() async {
    // AuthCubit hydrate depuis le storage sans passer par AuthLoading.
    final deadline = DateTime.now().add(const Duration(milliseconds: 1200));
    while (authCubit.state is AuthInitial) {
      if (DateTime.now().isAfter(deadline)) break;
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  _SplashDestination _resolveDestination({
    required String? deepLink,
    required bool onboardingCompleted,
  }) {
    final auth = authCubit.state;
    final loggedIn = auth is AuthAuthenticated;
    final decision = FcmRoutePolicy.resolveSplash(
      pendingRoute: deepLink,
      onboardingCompleted: onboardingCompleted,
      loggedIn: loggedIn,
      openProviderHome: loggedIn && auth.activeRole == 'PRESTATAIRE',
      providerExtra: loggedIn ? auth.utilisateur : null,
    );
    return _SplashDestination(
      route: decision.route,
      extra: decision.extra,
      hold: decision.hold,
    );
  }
}

class _SplashDestination {
  final String route;
  final Object? extra;
  final String? hold;

  const _SplashDestination({required this.route, this.extra, this.hold});
}
