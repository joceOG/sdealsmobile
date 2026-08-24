import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/token_store.dart';

class _FakeBackend {
  _FakeBackend({
    required this.businessAccess,
    required this.refreshAccepted,
    this.issuedAccess = 'access-new',
    this.issuedRefresh = 'refresh-new',
    this.refreshDelay = Duration.zero,
    this.refreshFail = false,
    this.refreshThrow = false,
  });

  String businessAccess;
  String refreshAccepted;
  final String issuedAccess;
  final String issuedRefresh;
  final Duration refreshDelay;
  bool refreshFail;
  bool refreshThrow;

  int refreshCalls = 0;
  final List<String> refreshTokensPresented = [];

  Future<http.Response> onRefresh({
    required Map<String, String> headers,
    required String body,
  }) async {
    refreshCalls++;
    final presented =
        (jsonDecode(body) as Map<String, dynamic>)['refreshToken']?.toString() ??
            '';
    refreshTokensPresented.add(presented);

    if (refreshDelay > Duration.zero) {
      await Future<void>.delayed(refreshDelay);
    }
    if (refreshThrow) {
      throw Exception('network down');
    }
    if (refreshFail || presented != refreshAccepted) {
      return http.Response('{"error":"invalid"}', 401,
          headers: {'content-type': 'application/json'});
    }

    refreshAccepted = issuedRefresh;
    businessAccess = issuedAccess;
    return http.Response(
      jsonEncode({'token': issuedAccess, 'refreshToken': issuedRefresh}),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  Future<http.Response> onBusiness(HttpHeaders headers) async {
    final auth = headers.value('authorization');
    final token = auth?.startsWith('Bearer ') == true
        ? auth!.substring('Bearer '.length)
        : null;
    if (token == businessAccess) {
      return http.Response('{"ok":true}', 200,
          headers: {'content-type': 'application/json'});
    }
    return http.Response('{"error":"unauthorized"}', 401,
        headers: {'content-type': 'application/json'});
  }
}

void main() {
  late ApiClient client;
  late _FakeBackend backend;
  HttpServer? server;

  setUpAll(() {
    // Pas de TestWidgetsFlutterBinding : il court-circuite HttpClient (400).
    dotenv.testLoad(fileInput: 'API_URL=http://localhost/api\n');
  });

  setUp(() {
    TokenStore.debugReset();
    TokenStore.debugUseInMemory();
    ApiClient.debugResetRefreshState();
    ApiClient.onUnauthorized = null;
    ApiClient.onTokenRefreshed = null;
    client = ApiClient();
  });

  tearDown(() async {
    await server?.close(force: true);
    server = null;
    ApiClient.debugResetRefreshState();
    ApiClient.onUnauthorized = null;
    ApiClient.onTokenRefreshed = null;
    TokenStore.debugReset();
  });

  Future<void> seed({
    String access = 'access-old',
    String refresh = 'refresh-old',
  }) async {
    await TokenStore.saveTokens(accessToken: access, refreshToken: refresh);
  }

  Future<void> startHttpBackend(_FakeBackend b) async {
    backend = b;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen((req) async {
      final chunks = <int>[];
      await for (final c in req) {
        chunks.addAll(c);
      }
      final body = utf8.decode(chunks);
      http.Response res;
      if (req.uri.path.endsWith('/refresh-token')) {
        final headers = <String, String>{};
        req.headers.forEach((n, v) => headers[n] = v.join(','));
        res = await backend.onRefresh(headers: headers, body: body);
      } else {
        res = await backend.onBusiness(req.headers);
      }
      req.response.statusCode = res.statusCode;
      req.response.headers.contentType = ContentType.json;
      req.response.write(res.body);
      await req.response.close();
    });
    client.apiUrl = 'http://${server!.address.host}:${server!.port}/api';
  }

  void wireRefreshPoster(_FakeBackend b) {
    backend = b;
    ApiClient.debugRefreshPoster = ({
      required Uri uri,
      required Map<String, String> headers,
      required String body,
    }) =>
        backend.onRefresh(headers: headers, body: body);
  }

  test('access valide → aucun refresh', () async {
    await seed();
    await startHttpBackend(_FakeBackend(
      businessAccess: 'access-old',
      refreshAccepted: 'refresh-old',
    ));

    final res = await client.get('/secure', token: 'access-old');
    expect(res.statusCode, 200);
    expect(backend.refreshCalls, 0);
  });

  test('access expiré → refresh → retry réussi', () async {
    await seed();
    await startHttpBackend(_FakeBackend(
      businessAccess: 'access-new',
      refreshAccepted: 'refresh-old',
    ));

    final res = await client.get('/secure', token: 'access-old');
    expect(res.statusCode, 200);
    expect(backend.refreshCalls, 1);
    expect(await TokenStore.getAccessToken(), 'access-new');
    expect(await TokenStore.getRefreshToken(), 'refresh-new');
  });

  test(
    'BLOQUANT: 3×401 simultanés → 1 refresh rotatif → 3 retries OK',
    () async {
      await seed();
      await startHttpBackend(_FakeBackend(
        businessAccess: 'access-new',
        refreshAccepted: 'refresh-old',
        refreshDelay: const Duration(milliseconds: 80),
      ));

      final results = await Future.wait([
        client.get('/a', token: 'access-old'),
        client.get('/b', token: 'access-old'),
        client.get('/c', token: 'access-old'),
      ]);

      expect(results.map((r) => r.statusCode).toList(), [200, 200, 200]);
      expect(backend.refreshCalls, 1);
      expect(backend.refreshTokensPresented, ['refresh-old']);
      expect(await TokenStore.getAccessToken(), 'access-new');
      expect(await TokenStore.getRefreshToken(), 'refresh-new');
    },
  );

  test(
    '401 après refresh concurrent → retry token récent sans 2e refresh',
    () async {
      await seed();
      await startHttpBackend(_FakeBackend(
        businessAccess: 'access-new',
        refreshAccepted: 'refresh-old',
      ));

      final first = await client.refreshAccessToken(
        failedAccessToken: 'access-old',
      );
      expect(first, 'access-new');
      expect(backend.refreshCalls, 1);

      final res = await client.get('/secure', token: 'access-old');
      expect(res.statusCode, 200);
      expect(backend.refreshCalls, 1);
    },
  );

  test('refresh invalide → un seul logout', () async {
    await seed();
    await startHttpBackend(_FakeBackend(
      businessAccess: 'access-new',
      refreshAccepted: 'refresh-old',
      refreshFail: true,
    ));

    var logouts = 0;
    ApiClient.onUnauthorized = () => logouts++;

    await expectLater(
      () => client.get('/secure', token: 'access-old'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(backend.refreshCalls, 1);
    expect(logouts, 1);
  });

  test('exception réseau pendant refresh → flight libéré', () async {
    await seed();
    wireRefreshPoster(_FakeBackend(
      businessAccess: 'access-new',
      refreshAccepted: 'refresh-old',
      refreshThrow: true,
    ));

    expect(
      await client.refreshAccessToken(failedAccessToken: 'access-old'),
      isNull,
    );
    expect(ApiClient.debugRefreshCallCount, 1);

    ApiClient.debugRefreshPoster = ({
      required Uri uri,
      required Map<String, String> headers,
      required String body,
    }) async {
      backend.refreshCalls++;
      return http.Response(
        jsonEncode({'token': 'access-new', 'refreshToken': 'refresh-new'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    };

    expect(
      await client.refreshAccessToken(failedAccessToken: 'access-old'),
      'access-new',
    );
  });

  test('nouveau couple access/refresh persisté de façon cohérente', () async {
    await seed();
    wireRefreshPoster(_FakeBackend(
      businessAccess: 'access-new',
      refreshAccepted: 'refresh-old',
    ));

    await client.refreshAccessToken(failedAccessToken: 'access-old');
    final creds = await TokenStore.getCredentials();
    expect(creds?.accessToken, 'access-new');
    expect(creds?.refreshToken, 'refresh-new');
    expect(TokenStore.debugCache()?.accessToken, 'access-new');
    expect(TokenStore.debugCache()?.refreshToken, 'refresh-new');
  });

  test(
    'contrat AuthCubit: après refresh → Authenticated + TokenStore new + pas de logout',
    () async {
      await seed();
      wireRefreshPoster(_FakeBackend(
        businessAccess: 'access-new',
        refreshAccepted: 'refresh-old',
      ));

      // Miroir minimal du handler AuthCubit.onTokenRefreshed.
      var authState = 'AuthAuthenticated';
      var mirroredAccess = 'access-old';
      var mirroredRefresh = 'refresh-old';
      var logoutCount = 0;

      ApiClient.onTokenRefreshed = (a, r) {
        mirroredAccess = a;
        if (r != null && r.isNotEmpty) mirroredRefresh = r;
        authState = 'AuthAuthenticated';
      };
      ApiClient.onUnauthorized = () {
        logoutCount++;
        authState = 'AuthInitial';
      };

      await client.refreshAccessToken(failedAccessToken: 'access-old');

      expect(authState, 'AuthAuthenticated');
      expect(logoutCount, 0);
      expect(mirroredAccess, 'access-new');
      expect(mirroredRefresh, 'refresh-new');
      expect(await TokenStore.getAccessToken(), 'access-new');
      expect(await TokenStore.getRefreshToken(), 'refresh-new');
      expect(TokenStore.debugCache()?.accessToken, 'access-new');
      expect(TokenStore.debugCache()?.refreshToken, 'refresh-new');
    },
  );

  test('3 refreshAccessToken concurrents → 1 POST, même access', () async {
    await seed();
    wireRefreshPoster(_FakeBackend(
      businessAccess: 'access-new',
      refreshAccepted: 'refresh-old',
      refreshDelay: const Duration(milliseconds: 60),
    ));

    final results = await Future.wait([
      client.refreshAccessToken(failedAccessToken: 'access-old'),
      client.refreshAccessToken(failedAccessToken: 'access-old'),
      client.refreshAccessToken(failedAccessToken: 'access-old'),
    ]);

    expect(results, everyElement('access-new'));
    expect(backend.refreshCalls, 1);
    expect(backend.refreshTokensPresented, ['refresh-old']);
  });
}
