import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/services/fcm_token_errors.dart';

void main() {
  test('SERVICE_NOT_AVAILABLE est transitoire', () {
    expect(
      isTransientFcmTokenError(
        Exception(
          '[firebase_messaging/unknown] java.io.IOException: '
          'SERVICE_NOT_AVAILABLE',
        ),
      ),
      isTrue,
    );
  });

  test('erreur métier n’est pas transitoire', () {
    expect(isTransientFcmTokenError(StateError('API_URL manquant')), isFalse);
  });
}
