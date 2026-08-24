import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/utils/phone_canonicalizer.dart';
import 'package:sdealsmobile/mobile/view/registerpagem/registerpageblocm/registerPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/registerpagem/registerpageblocm/registerPageEventM.dart';
import 'package:sdealsmobile/mobile/view/registerpagem/registerpageblocm/registerPageStateM.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    this.sendResult,
    this.verifyResult,
    this.registerResult,
    this.sendError,
    this.verifyError,
    this.registerError,
  });

  final Map<String, dynamic>? sendResult;
  final Map<String, dynamic>? verifyResult;
  final Map<String, dynamic>? registerResult;
  final Object? sendError;
  final Object? verifyError;
  final Object? registerError;

  int sendCalls = 0;
  int verifyCalls = 0;
  int registerCalls = 0;
  String? lastSendPhone;
  String? lastVerifyPhone;
  String? lastRegisterPhone;
  String? lastRegisterToken;

  @override
  Future<Map<String, dynamic>> sendPhoneOtp({
    required String telephone,
    String? phoneCountry,
  }) async {
    sendCalls++;
    lastSendPhone = telephone;
    if (sendError != null) throw sendError!;
    return sendResult ??
        {
          'success': true,
          'telephone': telephone,
          'expiresInSeconds': 600,
        };
  }

  @override
  Future<Map<String, dynamic>> verifyPhoneOtp({
    required String telephone,
    required String code,
    String? phoneCountry,
  }) async {
    verifyCalls++;
    lastVerifyPhone = telephone;
    if (verifyError != null) throw verifyError!;
    return verifyResult ??
        {
          'success': true,
          'telephone': telephone,
          'phoneVerificationToken': 'tok_$telephone',
        };
  }

  @override
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String phone,
    String? phoneCountry,
    required String password,
    String? email,
    String? phoneVerificationToken,
    String role = 'Client',
  }) async {
    registerCalls++;
    lastRegisterPhone = phone;
    lastRegisterToken = phoneVerificationToken;
    if (registerError != null) throw registerError!;
    return registerResult ??
        {
          'token': 'session-jwt',
          'utilisateur': {
            '_id': 'u1',
            'nom': 'Test',
            'prenom': 'User',
            'telephone': phone,
            'role': 'Client',
          },
        };
  }
}

RegisterSubmitted _form({
  String phone = '20113786',
  String country = 'TN',
}) {
  return RegisterSubmitted(
    fullName: 'Jean Dupont',
    email: '',
    phone: phone,
    phoneCountry: country,
    password: 'secret12',
    confirmPassword: 'secret12',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.testLoad(fileInput: 'API_URL=http://localhost:3000/api');

  group('STAB-08 register OTP flow', () {
    test('formulaire valide → OTP envoyé avant register (E.164 TN)', () async {
      final api = _FakeApiClient();
      final bloc = RegisterPageBlocM(apiClient: api);

      bloc.add(_form());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.otpSent,
          ),
        ),
      );

      expect(api.sendCalls, 1);
      expect(api.registerCalls, 0);
      expect(api.lastSendPhone, '+21620113786');
      expect(
        PhoneCanonicalizer.toE164('20113786', isoCode: IsoCode.TN),
        '+21620113786',
      );
      await bloc.close();
    });

    test('téléphone CI → E.164 exact', () async {
      final api = _FakeApiClient();
      final bloc = RegisterPageBlocM(apiClient: api);
      bloc.add(_form(phone: '0708091011', country: 'CI'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.otpSent,
          ),
        ),
      );
      expect(api.lastSendPhone, '+2250708091011');
      await bloc.close();
    });

    test('code correct → verify puis register avec token', () async {
      final api = _FakeApiClient();
      final bloc = RegisterPageBlocM(apiClient: api);
      bloc.add(_form());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.otpSent,
          ),
        ),
      );

      bloc.add(const OtpCodeSubmitted('123456'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.success,
          ),
        ),
      );

      expect(api.verifyCalls, 1);
      expect(api.registerCalls, 1);
      expect(api.lastRegisterPhone, '+21620113786');
      expect(api.lastRegisterToken, 'tok_+21620113786');
      expect(bloc.state.phoneVerificationToken, isNull);
      await bloc.close();
    });

    test('code incorrect → pas de register', () async {
      final api = _FakeApiClient(
        verifyError: Exception('Code incorrect. Réessayez.'),
      );
      final bloc = RegisterPageBlocM(apiClient: api);
      bloc.add(_form());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.otpSent,
          ),
        ),
      );
      bloc.add(const OtpCodeSubmitted('000000'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.error,
          ),
        ),
      );
      expect(api.registerCalls, 0);
      expect(bloc.state.errorMessage, contains('incorrect'));
      await bloc.close();
    });

    test('OTP expiré → message + resend possible', () async {
      final api = _FakeApiClient(
        verifyError: Exception('Code expiré. Demandez un nouveau code.'),
      );
      final bloc = RegisterPageBlocM(apiClient: api, resendCooldownSeconds: 0);
      bloc.add(_form());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.otpSent,
          ),
        ),
      );
      bloc.add(const OtpCodeSubmitted('123456'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) =>
                s.phase == RegisterPhase.error &&
                (s.errorMessage?.contains('expiré') ?? false),
          ),
        ),
      );
      expect(api.registerCalls, 0);
      bloc.add(const OtpResendRequested());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.otpSent,
          ),
        ),
      );
      expect(api.sendCalls, 2);
      await bloc.close();
    });

    test('erreur réseau send → Error, pas register', () async {
      final api = _FakeApiClient(
        sendError: Exception('Connexion impossible. Vérifiez votre réseau.'),
      );
      final bloc = RegisterPageBlocM(apiClient: api);
      bloc.add(_form());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.error,
          ),
        ),
      );
      expect(api.registerCalls, 0);
      expect(bloc.state.showOtpStep, isFalse);
      await bloc.close();
    });

    test('erreur réseau verify → pas de register', () async {
      final api = _FakeApiClient(
        verifyError:
            Exception('Connexion impossible. Vérifiez votre réseau.'),
      );
      final bloc = RegisterPageBlocM(apiClient: api);
      bloc.add(_form());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.otpSent,
          ),
        ),
      );
      bloc.add(const OtpCodeSubmitted('123456'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.error,
          ),
        ),
      );
      expect(api.registerCalls, 0);
      await bloc.close();
    });

    test('modification téléphone → ancienne vérification invalidée', () async {
      final api = _FakeApiClient();
      final bloc = RegisterPageBlocM(apiClient: api, resendCooldownSeconds: 0);
      bloc.add(_form());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.otpSent,
          ),
        ),
      );
      expect(bloc.state.pendingE164Phone, '+21620113786');

      bloc.add(const RegisterPhoneChanged(
        phone: '98765432',
        phoneCountry: 'TN',
      ));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) =>
                s.phase == RegisterPhase.initial &&
                s.phoneVerificationToken == null &&
                s.pendingE164Phone == null,
          ),
        ),
      );
      expect(api.registerCalls, 0);

      // Nouveau parcours pour B — pas de réutilisation du flux A
      bloc.add(_form(phone: '98765432', country: 'TN'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) =>
                s.phase == RegisterPhase.otpSent &&
                s.pendingE164Phone == '+21698765432',
          ),
        ),
      );
      expect(api.lastSendPhone, '+21698765432');
      await bloc.close();
    });

    test('double tap send → une seule requête (2e ignorée en otpSent)',
        () async {
      final api = _FakeApiClient();
      final bloc = RegisterPageBlocM(apiClient: api);
      bloc.add(_form());
      bloc.add(_form());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.otpSent,
          ),
        ),
      );
      // Laisse le 2e event se drain
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(api.sendCalls, 1);
      await bloc.close();
    });

    test('double tap verify → un seul register', () async {
      final api = _FakeApiClient();
      final bloc = RegisterPageBlocM(apiClient: api);
      bloc.add(_form());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.otpSent,
          ),
        ),
      );
      bloc.add(const OtpCodeSubmitted('123456'));
      bloc.add(const OtpCodeSubmitted('123456'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.success,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(api.verifyCalls, 1);
      expect(api.registerCalls, 1);
      await bloc.close();
    });

    test('phoneVerificationToken jamais exposé comme session token', () async {
      final api = _FakeApiClient();
      final bloc = RegisterPageBlocM(apiClient: api);
      bloc.add(_form());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.otpSent,
          ),
        ),
      );
      bloc.add(const OtpCodeSubmitted('123456'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<RegisterPageStateM>(
            (s) => s.phase == RegisterPhase.success,
          ),
        ),
      );
      expect(bloc.state.token, 'session-jwt');
      expect(bloc.state.phoneVerificationToken, isNull);
      expect(bloc.state.token, isNot(startsWith('tok_')));
      await bloc.close();
    });
  });
}
