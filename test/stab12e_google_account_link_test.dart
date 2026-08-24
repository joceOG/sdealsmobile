import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/google_auth_service.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/loginpageblocm/loginPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/loginpageblocm/loginPageEventM.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/loginpageblocm/loginPageStateM.dart';

class _FakeApi extends ApiClient {
  _FakeApi(this.linkError);

  final GoogleAccountLinkRequiredException linkError;

  @override
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String role = 'client',
  }) async {
    throw linkError;
  }
}

class _FakeGoogleAuth implements GoogleSignInGateway {
  _FakeGoogleAuth(this._token);
  final String? _token;
  int signOutCalls = 0;

  @override
  Future<String?> signInForIdToken() async => _token;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.testLoad(
    fileInput:
        'API_URL=http://localhost:3000/api\nGOOGLE_WEB_CLIENT_ID=web.apps.googleusercontent.com',
  );

  test('STAB-12E — ACCOUNT_LINK_REQUIRED → échec login, signOut Google', () async {
    const linkError = GoogleAccountLinkRequiredException(
      message:
          'Un compte existe déjà avec cette adresse email. '
          'Connectez-vous avec votre email et votre mot de passe.',
      hint: 'Vous pourrez associer Google à votre compte après connexion.',
    );

    final google = _FakeGoogleAuth('id-token');
    final bloc = LoginPageBlocM(
      apiClient: _FakeApi(linkError),
      googleAuth: google,
    );

    bloc.add(GoogleLoginSubmittedM());
    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<LoginPageLoadingM>(),
        predicate<LoginPageFailureM>(
          (s) =>
              s.error.contains('Connectez-vous avec votre email') &&
              s.error.contains('associer Google'),
        ),
      ]),
    );

    expect(google.signOutCalls, 1);
    await bloc.close();
  });
}
