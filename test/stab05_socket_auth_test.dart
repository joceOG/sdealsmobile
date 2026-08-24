import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/token_store.dart';
import 'package:sdealsmobile/data/services/websocket_service.dart';

void main() {
  late WebSocketService ws;
  var logoutCalls = 0;

  setUp(() {
    TokenStore.debugReset();
    TokenStore.debugUseInMemory();
    ApiClient.debugResetRefreshState();
    ApiClient.onUnauthorized = () => logoutCalls++;
    ApiClient.onTokenRefreshed = null;
    logoutCalls = 0;
    WebSocketService.debugReset();
    WebSocketService.debugSkipRealSocket = true;
    ws = WebSocketService();
  });

  tearDown(() {
    WebSocketService.debugReset();
    ApiClient.onUnauthorized = null;
    ApiClient.debugResetRefreshState();
    TokenStore.debugReset();
  });

  Future<void> seedRest({
    String access = 'access-ok',
    String refresh = 'refresh-ok',
  }) async {
    await TokenStore.saveTokens(accessToken: access, refreshToken: refresh);
  }

  // A
  test('A: session valide → socket-token → authenticated', () async {
    await seedRest();
    var fetches = 0;
    WebSocketService.debugSocketTokenFetcher = () async {
      fetches++;
      return 'sock-A';
    };

    await ws.authenticate(userId: 'user-A');

    expect(ws.currentUserId, 'user-A');
    expect(ws.debugSession.socketAuthenticated, isTrue);
    expect(fetches, 1);
    expect(ws.debugTokensIssued, ['sock-A']);
    expect(logoutCalls, 0);
  });

  // B
  test('B: access refresh path → nouveau socket-token → pas de logout', () async {
    await seedRest(access: 'access-old', refresh: 'refresh-ok');
    var n = 0;
    WebSocketService.debugSocketTokenFetcher = () async {
      n++;
      if (n == 1) {
        await TokenStore.saveTokens(
          accessToken: 'access-new',
          refreshToken: 'refresh-new',
        );
      }
      return 'sock-after-refresh';
    };

    await ws.authenticate(userId: 'user-A');

    expect(ws.debugSession.socketAuthenticated, isTrue);
    expect(await TokenStore.getAccessToken(), 'access-new');
    expect(logoutCalls, 0);
    expect(ws.debugTokensIssued.last, 'sock-after-refresh');
  });

  // C
  test('C: reconnexion → nouveau socket-token (pas de réutilisation)', () async {
    await seedRest();
    var n = 0;
    WebSocketService.debugSocketTokenFetcher = () async {
      n++;
      return 'sock-$n';
    };

    await ws.authenticate(userId: 'user-A');
    expect(ws.debugTokensIssued, ['sock-1']);

    ws.debugSession.clearEphemeralToken();
    await ws.authenticate(userId: 'user-A');

    expect(ws.debugTokenFetchCount, 2);
    expect(ws.debugTokensIssued, ['sock-1', 'sock-2']);
  });

  // D
  test('D: 3 authenticate simultanés → 1 seul fetch token', () async {
    await seedRest();
    var n = 0;
    WebSocketService.debugSocketTokenFetcher = () async {
      n++;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      return 'sock-shared';
    };

    await Future.wait([
      ws.authenticate(userId: 'user-A'),
      ws.authenticate(userId: 'user-A'),
      ws.authenticate(userId: 'user-A'),
    ]);

    expect(n, 1);
    expect(ws.debugSession.socketAuthenticated, isTrue);
    expect(ws.debugTokensIssued, ['sock-shared']);
  });

  // E
  test('E: échec temporaire socket-token → pas de logout REST', () async {
    await seedRest();
    WebSocketService.debugSocketTokenFetcher = () async {
      throw Exception('network blip');
    };

    await ws.authenticate(userId: 'user-A');

    expect(logoutCalls, 0);
    expect(await TokenStore.getAccessToken(), 'access-ok');
    expect(ws.debugSession.socketAuthenticated, isFalse);
  });

  // F
  test('F: logout → lock + listeners nettoyés + connect no-op', () async {
    await seedRest();
    WebSocketService.debugSocketTokenFetcher = () async => 'sock-x';
    await ws.authenticate(userId: 'user-A');
    ws.onNewMessage((_) {});
    expect(ws.debugNewMessageListenerCount(), 1);

    ws.disconnectForLogout();

    expect(ws.debugLogoutLocked, isTrue);
    expect(ws.currentUserId, isNull);
    expect(ws.debugNewMessageListenerCount(), 0);
    expect(ws.debugJoinedConversations, isEmpty);
    expect(ws.isConnected, isFalse);

    var fetches = 0;
    WebSocketService.debugSocketTokenFetcher = () async {
      fetches++;
      return 'nope';
    };
    await ws.connect();
    expect(fetches, 0);
    expect(ws.debugLogoutLocked, isTrue);
  });

  // G
  test('G: logout A → login B → aucun état A', () async {
    await seedRest();
    WebSocketService.debugSocketTokenFetcher = () async => 'sock-A';
    await ws.authenticate(userId: 'user-A');
    ws.joinConversation('conv-A');
    ws.onNewMessage((_) {});

    ws.disconnectForLogout();

    WebSocketService.debugSocketTokenFetcher = () async => 'sock-B';
    await ws.authenticate(userId: 'user-B');

    expect(ws.currentUserId, 'user-B');
    expect(ws.debugTokensIssued.contains('sock-B'), isTrue);
    expect(ws.debugJoinedConversations.contains('conv-A'), isFalse);
    expect(ws.debugNewMessageListenerCount(), 0);
  });

  // H
  test('H: plusieurs reconnexions → un seul callback new-message', () async {
    await seedRest();
    WebSocketService.debugSocketTokenFetcher = () async => 'sock';
    var hits = 0;
    void cb(dynamic _) => hits++;

    await ws.authenticate(userId: 'user-A');
    ws.onNewMessage(cb);
    ws.onNewMessage(cb);
    expect(ws.debugNewMessageListenerCount(), 1);

    ws.debugSession.clearEphemeralToken();
    await ws.authenticate(userId: 'user-A');
    ws.onNewMessage(cb);
    expect(ws.debugNewMessageListenerCount(), 1);

    ws.debugDispatchNewMessage({'id': 'm1'});
    expect(hits, 1);
  });

  // I
  test('I: rooms conservées pour rejoin après re-auth même user', () async {
    await seedRest();
    WebSocketService.debugSocketTokenFetcher = () async => 'sock';
    await ws.authenticate(userId: 'user-A');
    ws.joinConversation('conv-1');
    ws.joinConversation('conv-2');
    expect(ws.debugJoinedConversations, {'conv-1', 'conv-2'});

    ws.debugSession.clearEphemeralToken();
    await ws.authenticate(userId: 'user-A');
    expect(ws.debugJoinedConversations, {'conv-1', 'conv-2'});
  });

  // J
  test('J: resumeIfNeeded — no-op si authentifié ; re-fetch si perdu', () async {
    await seedRest();
    var n = 0;
    WebSocketService.debugSocketTokenFetcher = () async {
      n++;
      return 'sock-$n';
    };

    await ws.authenticate(userId: 'user-A');
    expect(n, 1);

    await ws.resumeIfNeeded();
    expect(n, 1);

    ws.debugSession.clearEphemeralToken();
    await ws.resumeIfNeeded();
    expect(n, greaterThanOrEqualTo(2));
  });

  // K — concurrence : réponse socket-token A en vol après logout/login B
  test(
      'K: fetch A en vol → logout/login B → réponse A ignorée (pas d’état A)',
      () async {
    await seedRest();
    final completerA = Completer<String>();
    var phase = 'A';
    WebSocketService.debugSocketTokenFetcher = () async {
      if (phase == 'A') return completerA.future;
      return 'sock-B';
    };

    final authA = ws.authenticate(userId: 'user-A');
    // Laisser le fetch A démarrer et rester en attente.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(ws.debugSession.tokenFetchCount, 1);

    ws.disconnectForLogout();
    final genAfterLogout = ws.debugSession.connectGeneration;

    phase = 'B';
    WebSocketService.debugSocketTokenFetcher = () async => 'sock-B';
    await ws.authenticate(userId: 'user-B');
    expect(ws.currentUserId, 'user-B');
    expect(ws.debugSession.socketAuthenticated, isTrue);
    expect(ws.debugTokensIssued, ['sock-B']);

    // Réponse A arrive trop tard.
    completerA.complete('sock-A-stale');
    await authA;
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(ws.currentUserId, 'user-B');
    expect(ws.debugTokensIssued.contains('sock-A-stale'), isFalse);
    expect(ws.debugTokensIssued, ['sock-B']);
    expect(ws.debugSession.connectGeneration, greaterThan(genAfterLogout));
    expect(ws.debugSession.socketAuthenticated, isTrue);
  });
}
