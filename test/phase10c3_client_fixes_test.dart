import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/config/client_feature_flags.dart';
import 'package:sdealsmobile/data/errors/api_exception.dart';
import 'package:sdealsmobile/data/services/fcm_route_policy.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/data/utils/network_user_message.dart';

void main() {
  tearDown(() {
    ProtectedActionStore.instance.clear();
    PendingLaunchDestination.clear();
  });

  test('intention consommée une fois et effacée au logout', () {
    ProtectedActionStore.instance.set(
      const ProtectedActionIntent(
        type: ProtectedActionType.callProvider,
        originRoute: 'providerProfile',
        technicalId: 'p1',
      ),
    );
    expect(ProtectedActionStore.instance.consume()?.type,
        ProtectedActionType.callProvider);
    expect(ProtectedActionStore.instance.consume(), isNull);

    ProtectedActionStore.instance.set(
      const ProtectedActionIntent(
        type: ProtectedActionType.requestService,
        originRoute: 'providerProfile',
        technicalId: 'p1',
      ),
    );
    PendingLaunchDestination.hold('/chat/abc');
    SessionExit.clearPending();
    expect(ProtectedActionStore.instance.hasPending, isFalse);
    expect(PendingLaunchDestination.peek(), isNull);
    expect(SessionExit.destination, '/homepage');
  });

  test('origine non autorisée refusée', () {
    expect(
      () => ProtectedActionStore.instance.set(
        const ProtectedActionIntent(
          type: ProtectedActionType.publish,
          originRoute: 'https://evil.example/login?token=secret',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('messages réseau distincts', () {
    expect(
      userFacingNetworkMessage(const SocketException('failed host lookup')),
      offlineUserMessage,
    );
    expect(
      userFacingNetworkMessage(TimeoutException('timed out')),
      timeoutUserMessage,
    );
    expect(
      userFacingNetworkMessage(ApiException.timeout()),
      timeoutUserMessage,
    );
    expect(
      userFacingNetworkMessage(
          const ApiException(message: 'x', statusCode: 503)),
      serverUserMessage,
    );
    expect(
      userFacingNetworkMessage(
          const ApiException(message: 'auth', statusCode: 401)),
      '',
    );
    expect(
      userFacingNetworkMessage(
        const SocketException('reset'),
        deviceOnline: true,
      ),
      isNot(offlineUserMessage),
    );
    expect(homeBannerDisplayMessage(timeoutUserMessage), timeoutUserMessage);
    expect(homeBannerLooksOffline(timeoutUserMessage), isFalse);
    expect(homeBannerLooksOffline(offlineUserMessage), isTrue);
  });

  test('É-marché masqué sans trou de libellés', () {
    expect(ClientFeatureFlags.emarketEnabled, isFalse);
    expect(ClientFeatureFlags.homeUniverseTitles, ['Métiers', 'Freelance']);
    expect(ClientFeatureFlags.homeUniverseTitles, isNot(contains('É-marché')));
    expect(ClientFeatureFlags.publishTitles, isNot(contains('Boutique')));
    expect(ClientFeatureFlags.explorerChipLabels,
        isNot(contains('Vente & Achat')));
    expect(ClientFeatureFlags.searchTabLabels, isNot(contains('Shop')));
    expect(ClientFeatureFlags.searchTabLabels, isNot(contains('Boutiques')));
    expect(ClientFeatureFlags.homeUniverseTitles, isNot(contains('')));
    expect(ClientFeatureFlags.clampSearchTabIndex(4), 0);
  });

  test('routes et écran boutique restent référencés par le flag activable', () {
    expect(ClientFeatureFlags.homeUniversesWhenEnabled, contains('É-marché'));
    expect(ClientFeatureFlags.publishWhenEnabled, contains('Boutique'));
  });

  group('FCM allowlist', () {
    test('route autorisée', () {
      final d = FcmRoutePolicy.decide(
        {'conversationId': 'abc_1'},
        loggedIn: true,
      );
      expect(d.route, '/chat/abc_1');
      expect(d.resumeAfterAuth, isNull);
    });

    test('route inconnue ignorée', () {
      final d = FcmRoutePolicy.decide(
        {'route': 'https://evil.example/steal'},
        loggedIn: true,
      );
      expect(d.route, '/homepage');
      expect(FcmRoutePolicy.mapToAllowedRoute({'route': '/wallet/secrets'}),
          isNull);
    });

    test('route protégée invité', () {
      final d = FcmRoutePolicy.decide(
        {'missionId': 'm1'},
        loggedIn: false,
      );
      expect(d.route, '/login');
      expect(d.resumeAfterAuth, '/mission-details/m1');
    });

    test('destination consommée une fois puis logout', () {
      PendingLaunchDestination.hold('/chat/abc');
      expect(PendingLaunchDestination.consume(), '/chat/abc');
      expect(PendingLaunchDestination.consume(), isNull);
      PendingLaunchDestination.hold('/chat/abc');
      SessionExit.clearPending();
      expect(PendingLaunchDestination.peek(), isNull);
    });

    test('onboarding puis destination', () {
      final splash = FcmRoutePolicy.resolveSplash(
        pendingRoute: '/chat/abc',
        onboardingCompleted: false,
        loggedIn: false,
        openProviderHome: false,
      );
      expect(splash.route, '/onboarding');
      expect(splash.hold, '/chat/abc');
    });

    test('sans destination → accueil', () {
      expect(
        FcmRoutePolicy.decide(const {}, loggedIn: true).route,
        '/homepage',
      );
    });
  });
}
