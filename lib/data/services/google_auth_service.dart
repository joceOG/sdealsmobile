import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Connexion Google native → idToken pour le backend.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  GoogleSignIn? _signIn;
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';
    await GoogleSignIn.instance.initialize(
      serverClientId: webClientId.isEmpty ? null : webClientId,
    );
    _signIn = GoogleSignIn.instance;
    _initialized = true;
  }

  /// Retourne l'idToken Google, ou null si annulé.
  Future<String?> signInForIdToken() async {
    await _ensureInit();
    final google = _signIn!;
    try {
      final account = await google.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'idToken Google manquant. Vérifiez GOOGLE_WEB_CLIENT_ID dans .env',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      if (kDebugMode) {
        print('[GoogleAuth] $e');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInit();
      await _signIn?.signOut();
    } catch (_) {}
  }
}
