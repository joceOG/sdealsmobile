import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';

void main() {
  test('toJson n’embarque jamais password / tokens', () {
    final u = Utilisateur(
      idutilisateur: 'u1',
      nom: 'Test',
      prenom: 'Synth',
      email: 'synth@example.test',
      password: 'SECRET_SHOULD_NOT_PERSIST',
      telephone: '+2250700000000',
      role: 'CLIENT',
      token: 'jwt-secret',
      tokens: ['fcm-or-jwt'],
    );
    final json = u.toJson();
    expect(json.containsKey('password'), isFalse);
    expect(json.containsKey('token'), isFalse);
    expect(json.containsKey('tokens'), isFalse);
    expect(jsonEncode(json), isNot(contains('SECRET_SHOULD_NOT_PERSIST')));
    expect(jsonEncode(json), isNot(contains('jwt-secret')));
  });

  test('sanitizePersistedJson retire les secrets legacy', () {
    final cleaned = Utilisateur.sanitizePersistedJson({
      '_id': 'u1',
      'nom': 'A',
      'email': 'a@test.com',
      'password': 'legacy',
      'token': 't',
      'tokens': ['x'],
      'refreshToken': 'r',
      'fcmToken': 'f',
      'telephone': '+22501',
      'role': 'CLIENT',
    });
    expect(cleaned.containsKey('password'), isFalse);
    expect(cleaned.containsKey('token'), isFalse);
    expect(cleaned.containsKey('tokens'), isFalse);
    expect(cleaned.containsKey('refreshToken'), isFalse);
    expect(cleaned.containsKey('fcmToken'), isFalse);
    expect(cleaned['telephone'], '+22501');
  });

  test('migration prefs : auth_user sans clé password', () async {
    SharedPreferences.setMockInitialValues({
      'auth_user': jsonEncode({
        '_id': 'u2',
        'nom': 'Legacy',
        'email': 'legacy@test.com',
        'password': 'should-be-stripped',
        'telephone': '+22502',
        'role': 'CLIENT',
        'token': 'legacy-jwt',
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final raw = Map<String, dynamic>.from(
      jsonDecode(prefs.getString('auth_user')!) as Map,
    );
    final sanitized = Utilisateur.sanitizePersistedJson(raw);
    final user = Utilisateur.fromJson(sanitized);
    await prefs.setString('auth_user', jsonEncode(user.toJson()));
    final stored = prefs.getString('auth_user')!;
    expect(stored.contains('password'), isFalse);
    expect(stored.contains('should-be-stripped'), isFalse);
    expect(stored.contains('legacy-jwt'), isFalse);
    expect(stored.contains('legacy@test.com'), isTrue);
  });
}
