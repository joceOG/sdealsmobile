import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Abstraction testable (STAB-09) — ne pas persister l'idToken.
abstract class GoogleSignInGateway {
  Future<String?> signInForIdToken();
  Future<void> signOut();
}

/// Connexion Google native → idToken pour le backend.
class GoogleAuthService implements GoogleSignInGateway {
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
  @override
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
      throw Exception(
        'Configuration Google invalide. Réessayez plus tard.',
      );
    } catch (e) {
      if (kDebugMode) {
        print('[GoogleAuth] $e');
      }
      final s = e.toString();
      if (s.contains('ApiException') ||
          s.contains('PlatformException') ||
          s.contains('DEVELOPER_ERROR') ||
          s.contains('sign_in_failed')) {
        throw Exception(
          'Configuration Google invalide. Réessayez plus tard.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureInit();
      await _signIn?.signOut();
    } catch (_) {}
  }
}
