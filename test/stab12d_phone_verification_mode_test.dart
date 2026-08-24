import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/phone_verification_config.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/google_auth_service.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/loginpageblocm/loginPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/loginpageblocm/loginPageEventM.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/loginpageblocm/loginPageStateM.dart';
import 'package:sdealsmobile/mobile/view/registerpagem/registerpageblocm/registerPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/registerpagem/registerpageblocm/registerPageEventM.dart';
import 'package:sdealsmobile/mobile/view/registerpagem/registerpageblocm/registerPageStateM.dart';

class _FakeGoogleAuth implements GoogleSignInGateway {
  _FakeGoogleAuth(this.token);
  final String? token;
  @override
  Future<String?> signInForIdToken() async => token;
  @override
  Future<void> signOut() async {}
}

class _FakeLoginApi extends ApiClient {
  _FakeLoginApi({
    this.config = PhoneVerificationConfig.legacy,
    this.loginResult,
    this.loginError,
    this.verifyResult,
    this.verifyPhoneResult,
  });

  final PhoneVerificationConfig config;
  final Map<String, dynamic>? loginResult;
  final Object? loginError;
  final Map<String, dynamic>? verifyResult;
  final Map<String, dynamic>? verifyPhoneResult;

  int loginCalls = 0;
  int verifyPhoneCalls = 0;

  @override
  Future<PhoneVerificationConfig> fetchPhoneVerificationConfig({
    bool forceRefresh = false,
  }) async =>
      config;

  @override
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String role = 'client',
  }) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    return loginResult ??
        {
          'token': 'sess-deferred',
          'refreshToken': 'ref-deferred',
          'phoneVerificationSuggested': true,
          'utilisateur': {
            '_id': 'u1',
            'nom': 'Beta',
            'prenom': 'User',
            'telephone': '',
            'telephoneVerified': false,
            'role': 'Client',
          },
        };
  }

  @override
  Future<Map<String, dynamic>> verifyAuthenticatedUserPhone({
    required String telephone,
    String? phoneCountry,
    required String phoneVerificationToken,
  }) async {
    verifyPhoneCalls++;
    return verifyPhoneResult ??
        {
          'utilisateur': {
            '_id': 'u1',
            'telephone': telephone,
            'telephoneVerified': true,
            'role': 'Client',
          },
        };
  }

  @override
  Future<Map<String, dynamic>> verifyPhoneOtp({
    required String telephone,
    required String code,
    String? phoneCountry,
  }) async {
    return verifyResult ??
        {
          'phoneVerificationToken': 'otp-tok',
          'telephone': telephone,
        };
  }

  @override
  Future<Map<String, dynamic>> sendPhoneOtp({
    required String telephone,
    String? phoneCountry,
  }) async =>
      {'success': true};
}

class _FakeRegisterApi extends ApiClient {
  _FakeRegisterApi({
    this.config = const PhoneVerificationConfig(
      mode: 'deferred',
      signupRequiresOtp: false,
      googleRequiresPhone: false,
    ),
    this.registerResult,
  });

  final PhoneVerificationConfig config;
  final Map<String, dynamic>? registerResult;

  int registerCalls = 0;
  int sendCalls = 0;

  @override
  Future<PhoneVerificationConfig> fetchPhoneVerificationConfig({
    bool forceRefresh = false,
  }) async =>
      config;

  @override
  Future<Map<String, dynamic>> registerUser({
    required String nom,
    String? prenom,
    required String phone,
    String? phoneCountry,
    required String password,
    String? email,
    String? phoneVerificationToken,
    String role = 'Client',
  }) async {
    registerCalls++;
    return registerResult ??
        {
          'token': 'reg-tok',
          'utilisateur': {
            '_id': 'u2',
            'nom': nom,
            'prenom': prenom ?? '',
            'telephone': phone,
            'telephoneVerified': false,
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
    return {'success': true};
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:3000/api');
  });

  group('STAB-12D Google deferred', () {
    test('nouveau Google → session + telephoneVerified=false', () async {
      final bloc = LoginPageBlocM(
        apiClient: _FakeLoginApi(),
        googleAuth: _FakeGoogleAuth('google-tok'),
      );
      bloc.add(GoogleLoginSubmittedM(rememberMe: false));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LoginPageStateM>(
            (s) =>
                s is LoginPageSuccessM &&
                s.phoneVerificationSuggested &&
                s.utilisateur['telephoneVerified'] != true,
          ),
        ),
      );
      await bloc.close();
    });

    test('OTP volontaire → telephoneVerified=true', () async {
      final api = _FakeLoginApi();
      final bloc = LoginPageBlocM(apiClient: api, googleAuth: _FakeGoogleAuth('g'));
      bloc.add(
        StartDeferredPhoneVerifyM(
          token: 'sess',
          utilisateur: {'_id': 'u1', 'telephoneVerified': false},
          rememberMe: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(GooglePhoneSubmittedM(phone: '20113786', phoneCountry: 'TN'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LoginPageStateM>(
            (s) => s is LoginGooglePhoneRequiredM && s.phase == GooglePhonePhase.otpSent,
          ),
        ),
      );
      bloc.add(GoogleOtpSubmittedM('123456'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LoginPageStateM>(
            (s) =>
                s is LoginPageSuccessM &&
                s.utilisateur['telephoneVerified'] == true,
          ),
        ),
      );
      expect(api.verifyPhoneCalls, 1);
      await bloc.close();
    });

    test('Plus tard → session sans blocage', () async {
      final bloc = LoginPageBlocM(apiClient: _FakeLoginApi());
      bloc.add(
        StartDeferredPhoneVerifyM(
          token: 'sess',
          utilisateur: {'_id': 'u1'},
          rememberMe: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(GooglePhoneSkippedM());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LoginPageStateM>(
            (s) => s is LoginPageSuccessM && !s.phoneVerificationSuggested,
          ),
        ),
      );
      await bloc.close();
    });
  });

  group('STAB-12D inscription deferred', () {
    test('sans OTP → compte non vérifié, téléphone optionnel', () async {
      final api = _FakeRegisterApi();
      final bloc = RegisterPageBlocM(apiClient: api);
      bloc.add(RegisterSubmitted(
        prenom: 'Alice',
        nom: 'Dupont',
        phone: '',
        phoneCountry: 'TN',
        email: 'alice@example.com',
        password: 'Secret123!',
        confirmPassword: 'Secret123!',
      ));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) =>
                s.phase == RegisterPhase.success &&
                s.utilisateur?.telephoneVerified != true,
          ),
        ),
      );
      expect(api.registerCalls, 1);
      expect(api.sendCalls, 0);
      await bloc.close();
    });

    test('sans email → refusé en deferred', () async {
      final bloc = RegisterPageBlocM(apiClient: _FakeRegisterApi());
      bloc.add(const RegisterSubmitted(
        prenom: 'Alice',
        nom: 'Dupont',
        phone: '',
        phoneCountry: 'TN',
        email: '',
        password: 'Secret123!',
        confirmPassword: 'Secret123!',
      ));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) =>
                s.phase == RegisterPhase.error &&
                (s.errorMessage ?? '').contains('Email requis'),
          ),
        ),
      );
      await bloc.close();
    });

    test('téléphone fourni → inscription sans OTP send', () async {
      final api = _FakeRegisterApi();
      final bloc = RegisterPageBlocM(apiClient: api);
      bloc.add(RegisterSubmitted(
        prenom: 'Alice',
        nom: 'Dupont',
        phone: '20113786',
        phoneCountry: 'TN',
        email: 'alice@example.com',
        password: 'Secret123!',
        confirmPassword: 'Secret123!',
      ));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) =>
                s.phase == RegisterPhase.success &&
                s.utilisateur?.telephoneVerified != true,
          ),
        ),
      );
      expect(api.registerCalls, 1);
      expect(api.sendCalls, 0);
      await bloc.close();
    });
  });

  group('STAB-12D config', () {
    test('PhoneVerificationConfig deferred', () {
      final cfg = PhoneVerificationConfig.fromJson({
        'mode': 'deferred',
        'signupRequiresOtp': false,
        'googleRequiresPhone': false,
      });
      expect(cfg.isDeferred, isTrue);
      expect(cfg.signupRequiresOtp, isFalse);
    });
  });
}
