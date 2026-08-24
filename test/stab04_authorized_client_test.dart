import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/token_store.dart';

/// Backend minimal pour STAB-04 (JSON + multipart + public).
class _Stab04Backend {
  _Stab04Backend({
    required this.businessAccess,
    required this.refreshAccepted,
    this.issuedAccess = 'access-new',
    this.issuedRefresh = 'refresh-new',
    this.refreshFail = false,
  });

  String businessAccess;
  String refreshAccepted;
  final String issuedAccess;
  final String issuedRefresh;
  bool refreshFail;

  int refreshCalls = 0;
  int businessCalls = 0;
  int publicCalls = 0;
  int multipartCalls = 0;
  final List<String?> businessBearers = [];
  final List<Map<String, String>> multipartFields = [];
  final List<List<String>> multipartFileNames = [];
  bool publicSawAuthorization = false;

  Future<http.Response> onRefresh({required String body}) async {
    refreshCalls++;
    final presented =
        (jsonDecode(body) as Map<String, dynamic>)['refreshToken']?.toString() ??
            '';
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

  Future<http.Response> handle(HttpRequest req, List<int> bodyBytes) async {
    final path = req.uri.path;
    final auth = req.headers.value('authorization');
    final bearer = auth != null && auth.startsWith('Bearer ')
        ? auth.substring('Bearer '.length)
        : null;

    if (path.endsWith('/refresh-token')) {
      return onRefresh(body: utf8.decode(bodyBytes));
    }

    if (path.endsWith('/login') || path.endsWith('/categorie')) {
      publicCalls++;
      if (auth != null && auth.isNotEmpty) publicSawAuthorization = true;
      return http.Response('{"ok":true,"public":true}', 200,
          headers: {'content-type': 'application/json'});
    }

    if (path.contains('/upload/document') || path.endsWith('/message')) {
      multipartCalls++;
      businessCalls++;
      businessBearers.add(bearer);
      // Parse multipart boundaries loosely for field/file presence.
      final raw = utf8.decode(bodyBytes, allowMalformed: true);
      final fields = <String, String>{};
      for (final name in ['prestataireId', 'documentType', 'expediteur']) {
        final m = RegExp('name="$name"\\r?\\n\\r?\\n([^\\r\\n-]+)').firstMatch(raw);
        if (m != null) fields[name] = m.group(1)!.trim();
      }
      multipartFields.add(fields);
      final files = <String>[];
      for (final m in RegExp(r'filename="([^"]+)"').allMatches(raw)) {
        files.add(m.group(1)!);
      }
      multipartFileNames.add(files);

      if (bearer == businessAccess) {
        return http.Response(
          jsonEncode({'ok': true, 'url': 'https://cdn.example/doc.jpg'}),
          path.endsWith('/message') ? 201 : 200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"error":"unauthorized"}', 401,
          headers: {'content-type': 'application/json'});
    }

    // Endpoint métier JSON authentifié
    businessCalls++;
    businessBearers.add(bearer);
    if (bearer == businessAccess) {
      return http.Response('{"ok":true}', 200,
          headers: {'content-type': 'application/json'});
    }
    return http.Response('{"error":"unauthorized"}', 401,
        headers: {'content-type': 'application/json'});
  }
}

void main() {
  late ApiClient client;
  late _Stab04Backend backend;
  HttpServer? server;
  Directory? tmpDir;

  setUpAll(() {
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
    if (tmpDir != null && tmpDir!.existsSync()) {
      tmpDir!.deleteSync(recursive: true);
    }
    tmpDir = null;
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

  Future<void> startBackend(_Stab04Backend b) async {
    backend = b;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen((req) async {
      final chunks = <int>[];
      await for (final c in req) {
        chunks.addAll(c);
      }
      final res = await backend.handle(req, chunks);
      req.response.statusCode = res.statusCode;
      req.response.headers.contentType = ContentType.json;
      req.response.write(res.body);
      await req.response.close();
    });
    client.apiUrl = 'http://${server!.address.host}:${server!.port}/api';
  }

  File makeTempFile() {
    tmpDir ??= Directory.systemTemp.createTempSync('stab04_');
    final f = File('${tmpDir!.path}/doc.jpg');
    f.writeAsBytesSync(List<int>.generate(64, (i) => i));
    return f;
  }

  // A — requête authentifiée migrée, token valide → Bearer → 200
  test('A: GET authentifié valide → Bearer présent → 200', () async {
    await seed(access: 'access-ok', refresh: 'refresh-old');
    await startBackend(_Stab04Backend(
      businessAccess: 'access-ok',
      refreshAccepted: 'refresh-old',
    ));

    final res = await client.get('/prestataire/me');
    expect(res.statusCode, 200);
    expect(backend.refreshCalls, 0);
    expect(backend.businessBearers, ['access-ok']);
  });

  // B — access expiré → 1 refresh → retry → 200
  test('B: GET authentifié expiré → 1 refresh → retry → 200', () async {
    await seed();
    await startBackend(_Stab04Backend(
      businessAccess: 'access-new',
      refreshAccepted: 'refresh-old',
    ));

    final res = await client.get('/prestataire/me');
    expect(res.statusCode, 200);
    expect(backend.refreshCalls, 1);
    expect(backend.businessBearers, ['access-old', 'access-new']);
  });

  // C — multipart 401 → refresh → reconstruction → succès avec champs/fichiers
  test('C: multipart 401 → refresh → MultipartRequest reconstruit → succès',
      () async {
    await seed();
    await startBackend(_Stab04Backend(
      businessAccess: 'access-new',
      refreshAccepted: 'refresh-old',
    ));
    final file = makeTempFile();

    final res = await client.sendAuthorizedMultipart((access) async {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('${client.apiUrl}/upload/document'),
      );
      if (access != null) {
        req.headers['Authorization'] = 'Bearer $access';
      }
      req.fields['prestataireId'] = 'p1';
      req.fields['documentType'] = 'cniRecto';
      req.files.add(await http.MultipartFile.fromPath(
        'document',
        file.path,
        filename: 'cniRecto.jpg',
      ));
      return req;
    });

    expect(res.statusCode, 200);
    expect(backend.refreshCalls, 1);
    expect(backend.multipartCalls, 2); // 401 puis retry
    expect(backend.multipartFields.length, 2);
    for (final fields in backend.multipartFields) {
      expect(fields['prestataireId'], 'p1');
      expect(fields['documentType'], 'cniRecto');
    }
    for (final names in backend.multipartFileNames) {
      expect(names, contains('cniRecto.jpg'));
    }
    expect(backend.businessBearers, ['access-old', 'access-new']);
  });

  // D — refresh invalide → un seul logout
  test('D: refresh invalide → un seul logout', () async {
    await seed();
    await startBackend(_Stab04Backend(
      businessAccess: 'access-new',
      refreshAccepted: 'refresh-old',
      refreshFail: true,
    ));

    var logouts = 0;
    ApiClient.onUnauthorized = () => logouts++;

    await expectLater(
      () => client.get('/prestataire/me'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(backend.refreshCalls, 1);
    expect(logouts, 1);
  });

  // E — endpoint public sans Bearer / sans refresh
  test('E: endpoint public → pas de Bearer forcé, pas de refresh', () async {
    await seed();
    await startBackend(_Stab04Backend(
      businessAccess: 'access-old',
      refreshAccepted: 'refresh-old',
    ));

    // Appel public direct (hors _sendAuthorized) — login reste public.
    final res = await http.post(
      Uri.parse('${client.apiUrl}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': 'a@b.c', 'password': 'x'}),
    );
    expect(res.statusCode, 200);
    expect(backend.publicCalls, 1);
    expect(backend.publicSawAuthorization, isFalse);
    expect(backend.refreshCalls, 0);
  });

  // F — token renouvelé ailleurs → retry sans 2e refresh
  test('F: token déjà renouvelé ailleurs → retry sans 2e POST refresh',
      () async {
    await seed();
    await startBackend(_Stab04Backend(
      businessAccess: 'access-new',
      refreshAccepted: 'refresh-old',
    ));

    // Simule un refresh concurrent déjà appliqué dans TokenStore.
    await TokenStore.saveTokens(
      accessToken: 'access-new',
      refreshToken: 'refresh-new',
    );

    final res = await client.get('/prestataire/me', token: 'access-old');
    expect(res.statusCode, 200);
    // _resolveAccessToken préfère TokenStore → souvent 0 refresh ;
    // si un 401 arrive avec bearer obsolète passé explicitement, 0 refresh
    // grâce au retry sur token plus récent.
    expect(backend.refreshCalls, 0);
  });
}
