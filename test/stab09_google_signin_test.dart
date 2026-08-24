import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/google_auth_service.dart';
import 'package:sdealsmobile/data/utils/phone_canonicalizer.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/loginpageblocm/loginPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/loginpageblocm/loginPageEventM.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/loginpageblocm/loginPageStateM.dart';

class _FakeApi extends ApiClient {
  _FakeApi({
    this.loginGoogleResult,
    this.loginGoogleError,
    this.completeResult,
    this.completeError,
    this.sendError,
    this.verifyError,
  });

  final Map<String, dynamic>? loginGoogleResult;
  final Object? loginGoogleError;
  final Map<String, dynamic>? completeResult;
  final Object? completeError;
  final Object? sendError;
  final Object? verifyError;

  int loginGoogleCalls = 0;
  int completeCalls = 0;
  int sendCalls = 0;
  int verifyCalls = 0;
  String? lastCompletePhone;
  String? lastCompleteToken;

  @override
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String role = 'client',
  }) async {
    loginGoogleCalls++;
    if (loginGoogleError != null) throw loginGoogleError!;
    return loginGoogleResult ??
        {
          'token': 'session',
          'refreshToken': 'refresh',
          'utilisateur': {
            '_id': 'u1',
            'nom': 'A',
            'prenom': 'B',
            'telephone': '+21620113786',
            'telephoneVerified': true,
            'role': 'Client',
          },
        };
  }

  @override
  Future<Map<String, dynamic>> completeGoogleSignIn({
    required String idToken,
    required String telephone,
    String? phoneCountry,
    required String phoneVerificationToken,
    String role = 'client',
  }) async {
    completeCalls++;
    lastCompletePhone = telephone;
    lastCompleteToken = phoneVerificationToken;
    if (completeError != null) throw completeError!;
    return completeResult ??
        {
          'token': 'session-new',
          'refreshToken': 'refresh-new',
          'utilisateur': {
            '_id': 'u2',
            'nom': 'New',
            'prenom': 'G',
            'telephone': telephone,
            'telephoneVerified': true,
            'role': 'Client',
          },
        };
  }

  @override
  Future<Map<String, dynamic>> sendPhoneOtp({
    required String telephone,
    String? phoneCountry,
  }) async {
    sendCalls++;
    if (sendError != null) throw sendError!;
    return {'success': true, 'telephone': telephone};
  }

  @override
  Future<Map<String, dynamic>> verifyPhoneOtp({
    required String telephone,
    required String code,
    String? phoneCountry,
  }) async {
    verifyCalls++;
    if (verifyError != null) throw verifyError!;
    return {
      'telephone': telephone,
      'phoneVerificationToken': 'pvtok_$telephone',
    };
  }
}

class _FakeGoogle implements GoogleSignInGateway {
  _FakeGoogle({this.idToken, this.error, this.cancel = false});
  final String? idToken;
  final Object? error;
  final bool cancel;
  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  Future<String?> signInForIdToken() async {
    signInCalls++;
    if (cancel) return null;
    if (error != null) throw error!;
    return idToken ?? 'google-id-token';
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.testLoad(fileInput: 'API_URL=http://localhost:3000/api\nGOOGLE_WEB_CLIENT_ID=web.apps.googleusercontent.com');

  group('STAB-09 Google Sign-In', () {
    test('Google annulé → retour propre', () async {
      final api = _FakeApi();
      final google = _FakeGoogle(cancel: true);
      final bloc = LoginPageBlocM(apiClient: api, googleAuth: google);
      bloc.add(GoogleLoginSubmittedM(rememberMe: false));
      await expectLater(
        bloc.stream,
        emitsThrough(isA<LoginPageInitialM>()),
      );
      expect(api.loginGoogleCalls, 0);
      await bloc.close();
    });

    test('Google compte vérifié → Success', () async {
      final api = _FakeApi();
      final google = _FakeGoogle(idToken: 'tok');
      final bloc = LoginPageBlocM(apiClient: api, googleAuth: google);
      bloc.add(GoogleLoginSubmittedM(rememberMe: false));
      await expectLater(
        bloc.stream,
        emitsThrough(isA<LoginPageSuccessM>()),
      );
      expect(api.loginGoogleCalls, 1);
      await bloc.close();
    });

    test('nouveau Google → écran téléphone/OTP puis session', () async {
      final api = _FakeApi(
        loginGoogleError: const GooglePhoneVerificationRequiredException(
          email: 'n@example.com',
        ),
      );
      final google = _FakeGoogle(idToken: 'tok-new');
      final bloc = LoginPageBlocM(
        apiClient: api,
        googleAuth: google,
        resendCooldownSeconds: 0,
      );
      bloc.add(GoogleLoginSubmittedM(rememberMe: false));
      await expectLater(
        bloc.stream,
        emitsThrough(isA<LoginGooglePhoneRequiredM>()),
      );

      bloc.add(GooglePhoneSubmittedM(phone: '20113786', phoneCountry: 'TN'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LoginPageStateM>(
            (s) =>
                s is LoginGooglePhoneRequiredM &&
                s.phase == GooglePhonePhase.otpSent &&
                s.e164Phone == '+21620113786',
          ),
        ),
      );
      expect(
        PhoneCanonicalizer.toE164('20113786', isoCode: IsoCode.TN),
        '+21620113786',
      );

      bloc.add(GoogleOtpSubmittedM('123456'));
      await expectLater(
        bloc.stream,
        emitsThrough(isA<LoginPageSuccessM>()),
      );
      expect(api.completeCalls, 1);
      expect(api.lastCompletePhone, '+21620113786');
      expect(api.lastCompleteToken, 'pvtok_+21620113786');
      await bloc.close();
    });

    test('CI E.164 correct dans onboarding Google', () async {
      final api = _FakeApi(
        loginGoogleError: const GooglePhoneVerificationRequiredException(),
      );
      final bloc = LoginPageBlocM(
        apiClient: api,
        googleAuth: _FakeGoogle(),
        resendCooldownSeconds: 0,
      );
      bloc.add(GoogleLoginSubmittedM(rememberMe: false));
      await expectLater(
        bloc.stream,
        emitsThrough(isA<LoginGooglePhoneRequiredM>()),
      );
      bloc.add(GooglePhoneSubmittedM(phone: '0708091011', phoneCountry: 'CI'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LoginPageStateM>(
            (s) =>
                s is LoginGooglePhoneRequiredM &&
                s.e164Phone == '+2250708091011',
          ),
        ),
      );
      await bloc.close();
    });

    test('OTP faux → aucune session', () async {
      final api = _FakeApi(
        loginGoogleError: const GooglePhoneVerificationRequiredException(),
        verifyError: Exception('Code incorrect. Réessayez.'),
      );
      final bloc = LoginPageBlocM(
        apiClient: api,
        googleAuth: _FakeGoogle(),
        resendCooldownSeconds: 0,
      );
      bloc.add(GoogleLoginSubmittedM(rememberMe: false));
      await expectLater(
        bloc.stream,
        emitsThrough(isA<LoginGooglePhoneRequiredM>()),
      );
      bloc.add(GooglePhoneSubmittedM(phone: '20113786', phoneCountry: 'TN'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LoginPageStateM>(
            (s) =>
                s is LoginGooglePhoneRequiredM &&
                s.phase == GooglePhonePhase.otpSent,
          ),
        ),
      );
      bloc.add(GoogleOtpSubmittedM('000000'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LoginPageStateM>(
            (s) =>
                s is LoginGooglePhoneRequiredM &&
                s.phase == GooglePhonePhase.error,
          ),
        ),
      );
      expect(api.completeCalls, 0);
      await bloc.close();
    });

    test('changement téléphone invalide token précédent', () async {
      final api = _FakeApi(
        loginGoogleError: const GooglePhoneVerificationRequiredException(),
      );
      final bloc = LoginPageBlocM(
        apiClient: api,
        googleAuth: _FakeGoogle(),
        resendCooldownSeconds: 0,
      );
      bloc.add(GoogleLoginSubmittedM(rememberMe: false));
      await expectLater(
        bloc.stream,
        emitsThrough(isA<LoginGooglePhoneRequiredM>()),
      );
      bloc.add(GooglePhoneSubmittedM(phone: '20113786', phoneCountry: 'TN'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LoginPageStateM>(
            (s) =>
                s is LoginGooglePhoneRequiredM &&
                s.phase == GooglePhonePhase.otpSent,
          ),
        ),
      );
      bloc.add(GooglePhoneChangedM(phone: '98765432', phoneCountry: 'TN'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LoginPageStateM>(
            (s) =>
                s is LoginGooglePhoneRequiredM &&
                s.phase == GooglePhonePhase.collectPhone &&
                s.phoneVerificationToken == null &&
                s.e164Phone == null,
          ),
        ),
      );
      await bloc.close();
    });

    test('double tap Google → une tentative', () async {
      final api = _FakeApi();
      final google = _FakeGoogle(idToken: 'tok');
      final bloc = LoginPageBlocM(apiClient: api, googleAuth: google);
      bloc.add(GoogleLoginSubmittedM(rememberMe: false));
      bloc.add(GoogleLoginSubmittedM(rememberMe: false));
      await expectLater(
        bloc.stream,
        emitsThrough(isA<LoginPageSuccessM>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(google.signInCalls, 1);
      expect(api.loginGoogleCalls, 1);
      await bloc.close();
    });

    test('backend inaccessible → erreur utilisateur', () async {
      final api = _FakeApi(
        loginGoogleError:
            Exception('Connexion impossible. Vérifiez votre réseau.'),
      );
      final bloc = LoginPageBlocM(
        apiClient: api,
        googleAuth: _FakeGoogle(),
      );
      bloc.add(GoogleLoginSubmittedM(rememberMe: false));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LoginPageStateM>(
            (s) =>
                s is LoginPageFailureM &&
                s.error.contains('Connexion impossible'),
          ),
        ),
      );
      await bloc.close();
    });
  });
}
