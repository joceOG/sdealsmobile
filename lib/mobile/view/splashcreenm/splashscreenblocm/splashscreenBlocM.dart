import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/auth_professional_access.dart';
import 'package:sdealsmobile/data/services/startup_trace.dart';
import 'package:sdealsmobile/data/services/fcm_route_policy.dart';
import 'package:sdealsmobile/data/services/fcm_service.dart';
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
    StartupTrace.mark('splash load');

    final prefs = await _prefsOrNull();
    final seenVersion = prefs?.getInt(BrandIntroConfig.prefSeenVersion) ?? 0;
    final showFull = seenVersion < BrandIntroConfig.brandIntroVersion;

    await _waitAuthSettled();
    StartupTrace.mark(
        'auth settled ${authCubit.state.runtimeType} ${authCubit.restoreStatus.value.name}');

    try {
      await FcmService.instance
          .captureColdStart()
          .timeout(const Duration(milliseconds: 900));
      StartupTrace.mark('fcm cold start end');
    } catch (e) {
      StartupTrace.mark('fcm cold start ${e.runtimeType}');
    }

    final onboardingCompleted = prefs?.getBool('onboarding_completed') ?? false;

    final deepLink = FcmService.instance.consumePendingLaunchRoute();
    final destination = _resolveDestination(
      deepLink: deepLink,
      onboardingCompleted: onboardingCompleted,
    );
    if (destination.hold != null) {
      FcmService.instance.holdDestination(destination.hold!);
    }

    if (authCubit.restoreStatus.value == SessionRestoreStatus.restoring) {
      // L'interface va s'ouvrir avant la fin de la restauration.
      authCubit.markInterfaceShownBeforeRestore();
    }
    StartupTrace.mark('splash ready');
    emit(SplashReadyM(
      showFullIntro: showFull,
      destination: destination.route,
      destinationExtra: destination.extra,
    ));
  }

  Future<SharedPreferences?> _prefsOrNull() async {
    try {
      return await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      StartupTrace.mark('prefs ${e.runtimeType}');
      return null;
    }
  }

  Future<void> _waitAuthSettled() async {
    // AuthCubit hydrate depuis le storage sans passer par AuthLoading.
    // Avant : sondage de l'état jusqu'à 500 ms ; un invité reste AuthInitial
    // et attendait toujours les 500 ms. On attend la fin réelle de la
    // restauration, avec le même plafond (la FCM cold start lit l'état auth).
    if (authCubit.state is! AuthInitial) return;
    try {
      await authCubit.sessionRestored
          .timeout(const Duration(milliseconds: 500));
    } on TimeoutException {
      StartupTrace.mark('auth restore timeout');
    }
  }

  _SplashDestination _resolveDestination({
    required String? deepLink,
    required bool onboardingCompleted,
  }) {
    final auth = authCubit.state;
    final loggedIn = auth is AuthAuthenticated;
    // Restauration encore en cours après le délai d'attente : ni invité,
    // ni accès pro ; la destination est conservée (voir SessionRestoreResolver).
    final sessionPending =
        authCubit.restoreStatus.value == SessionRestoreStatus.restoring;
    final decision = FcmRoutePolicy.resolveSplash(
      pendingRoute: deepLink,
      onboardingCompleted: onboardingCompleted,
      loggedIn: loggedIn,
      // Même règle que Home : rôle actif ET capacité opérationnelle.
      openProviderHome: loggedIn &&
          auth.activeRole == 'PRESTATAIRE' &&
          auth.canOperatePrestataire,
      providerExtra: loggedIn ? auth.utilisateur : null,
      sessionPending: sessionPending,
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
