import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sdealsmobile/data/errors/api_exception.dart';
import 'package:sdealsmobile/data/services/api_client.dart';

http.Response _json(int status, String body) => http.Response(
      body,
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('STAB-12A ApiErrorParser', () {
    test('{error} simple', () {
      final ex = ApiErrorParser.fromResponse(
        _json(400, '{"error":"Identifiants incorrects"}'),
      );
      expect(ex.message, 'Identifiants incorrects');
      expect(ex.statusCode, 400);
      expect(ex.toString(), isNot(contains('Exception:')));
      expect(ApiException.userFacing(ex), isNot(contains('Exception:')));
    });

    test('{message} simple', () {
      final ex = ApiErrorParser.fromResponse(
        _json(403, '{"message":"Action non autorisée sur cette ressource"}'),
      );
      expect(ex.message, 'Action non autorisée sur cette ressource');
      expect(ex.statusCode, 403);
    });

    test('{error, details[]} telephone express-validator', () {
      final ex = ApiErrorParser.fromResponse(
        _json(
          400,
          '''
{
  "error": "Données de validation invalides",
  "details": [
    { "path": "telephone", "msg": "Numéro invalide", "value": "+225SECRET" }
  ]
}
''',
        ),
      );
      expect(ex.message, contains('téléphone'));
      expect(ex.message.toLowerCase(), contains('invalide'));
      expect(ex.fieldErrors['telephone'], isNotNull);
      expect(ex.message, isNot(contains('SECRET')));
      expect(ex.toString(), isNot(contains('Exception:')));
      expect(ex.toString(), isNot(contains('Données de validation invalides')));
    });

    test('express-validator email', () {
      final ex = ApiErrorParser.fromResponse(
        _json(
          422,
          '''
{
  "error": "Données de validation invalides",
  "details": [
    { "field": "email", "msg": "Email invalide", "value": "x" }
  ]
}
''',
        ),
      );
      expect(ex.message, 'Email invalide.');
      expect(ex.fieldErrors['email'], isNotNull);
      expect(ex.primaryField, 'email');
    });

    test('409 téléphone déjà utilisé', () {
      final ex = ApiErrorParser.fromResponse(
        _json(409, '{"error":"Ce numéro de téléphone est déjà utilisé"}'),
      );
      expect(ex.statusCode, 409);
      expect(ex.message.toLowerCase(), contains('déjà utilisé'));
    });

    test('429 rate limit', () {
      final ex = ApiErrorParser.fromResponse(
        _json(429, '{"error":"Too many requests"}'),
      );
      expect(ex.message, 'Trop de tentatives. Réessayez plus tard.');
    });

    test('500 → message générique', () {
      final ex = ApiErrorParser.fromResponse(
        _json(500, '{"error":"ECONNREFUSED 127.0.0.1:5432"}'),
      );
      expect(ex.message, 'Une erreur est survenue. Veuillez réessayer.');
      expect(ex.message, isNot(contains('ECONNREFUSED')));
    });

    test('HTML / non-JSON → message générique', () {
      final ex = ApiErrorParser.fromResponse(
        http.Response(
          '<html><body>nginx 502 Bad Gateway</body></html>',
          502,
          headers: {'content-type': 'text/html'},
        ),
      );
      expect(ex.message, 'Une erreur est survenue. Veuillez réessayer.');
      expect(ex.message, isNot(contains('nginx')));
      expect(ex.message, isNot(contains('<html')));
    });

    test('timeout', () {
      final ex = ApiErrorParser.fromCaught(TimeoutException('slow'));
      expect(ex.isTimeout, isTrue);
      expect(ex.message, contains('trop de temps'));
      expect(ex.toString(), isNot(contains('Exception:')));
    });

    test('erreur réseau SocketException', () {
      final ex = ApiErrorParser.fromCaught(
        const SocketException('Failed host lookup'),
      );
      expect(ex.isNetworkError, isTrue);
      expect(ex.message, contains('connexion internet'));
      expect(ApiException.userFacing(ex), isNot(contains('SocketException')));
    });

    test('ClientException → réseau', () {
      final ex = ApiErrorParser.fromCaught(
        http.ClientException('Connection closed'),
      );
      expect(ex.isNetworkError, isTrue);
    });

    test('aucune sortie utilisateur avec Exception:', () {
      final cases = <Object>[
        ApiException(message: 'Numéro de téléphone invalide.'),
        Exception('Données de validation invalides'),
        const SocketException('x'),
        TimeoutException('t'),
        FormatException('bad json'),
      ];
      for (final c in cases) {
        final ui = ApiException.userFacing(c);
        expect(ui, isNot(contains('Exception:')), reason: '$c → $ui');
        if (c is ApiException) {
          expect(c.toString(), isNot(contains('Exception:')));
        }
      }
    });

    test('code métier préservé dans ApiException.code', () {
      final ex = ApiErrorParser.fromResponse(
        _json(
          403,
          '{"error":"Vérification requise","code":"PHONE_VERIFICATION_REQUIRED"}',
        ),
      );
      expect(ex.code, 'PHONE_VERIFICATION_REQUIRED');
    });
  });

  group('STAB-12A Google / OTP codes métier', () {
    test('GooglePhoneVerificationRequiredException reste distincte', () {
      const e = GooglePhoneVerificationRequiredException(email: 'a@b.c');
      expect(e, isA<GooglePhoneVerificationRequiredException>());
      expect(e.email, 'a@b.c');
      // Ne doit PAS être aplatie en ApiException.userFacing générique
      // tant que le workflow catch le type métier.
      expect(e, isNot(isA<ApiException>()));
    });

    test('GoogleAccountLinkRequiredException reste distincte (STAB-12E)', () {
      const e = GoogleAccountLinkRequiredException(
        hint: 'Vous pourrez associer Google à votre compte après connexion.',
      );
      expect(e, isA<GoogleAccountLinkRequiredException>());
      expect(e.toString(), contains('associer Google'));
      expect(e, isNot(isA<ApiException>()));
    });

    test('OTP messages métier via ApiException.message', () {
      final expired = const ApiException(
        statusCode: 400,
        message: 'Code expiré. Demandez un nouveau code.',
        fieldErrors: {'code': 'Code expiré. Demandez un nouveau code.'},
      );
      final invalid = const ApiException(
        statusCode: 400,
        message: 'Code incorrect. Réessayez.',
        fieldErrors: {'code': 'Code incorrect. Réessayez.'},
      );
      expect(expired.userMessage, contains('expiré'));
      expect(invalid.userMessage, contains('incorrect'));
      expect(expired.fieldErrors['code'], isNotNull);
    });
  });

  group('STAB-12A ApiException.toString', () {
    test('toString == message UI (pas Exception:)', () {
      const ex = ApiException(message: 'Numéro de téléphone invalide.');
      expect('$ex', 'Numéro de téléphone invalide.');
      expect('Erreur: $ex', isNot(contains('Exception:')));
    });
  });
}
