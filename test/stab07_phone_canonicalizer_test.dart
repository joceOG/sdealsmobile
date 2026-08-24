import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:sdealsmobile/data/utils/phone_canonicalizer.dart';

void main() {
  group('STAB-07 PhoneCanonicalizer', () {
    test('+21620113786 → accepté et inchangé', () {
      expect(
        PhoneCanonicalizer.toE164('+21620113786'),
        '+21620113786',
      );
    });

    test('0021620113786 → +21620113786', () {
      expect(
        PhoneCanonicalizer.toE164('0021620113786'),
        '+21620113786',
      );
    });

    test('pays Tunisie + 20113786 → +21620113786', () {
      expect(
        PhoneCanonicalizer.toE164('20113786', isoCode: IsoCode.TN),
        '+21620113786',
      );
    });

    test("pays Côte d'Ivoire + national valide → +225…", () {
      final e164 = PhoneCanonicalizer.toE164(
        '0708091011',
        isoCode: IsoCode.CI,
      );
      expect(e164, '+2250708091011');
      expect(e164.startsWith('+225'), isTrue);
    });

    test('national sans pays → refus', () {
      expect(
        () => PhoneCanonicalizer.toE164('20113786'),
        throwsA(isA<PhoneCanonicalizationException>()),
      );
    });

    test('espaces/tirets → normalisé', () {
      expect(
        PhoneCanonicalizer.toE164('+216 20-113-786'),
        '+21620113786',
      );
    });

    test('trop court → refus', () {
      expect(
        () => PhoneCanonicalizer.toE164('20', isoCode: IsoCode.TN),
        throwsA(isA<PhoneCanonicalizationException>()),
      );
    });

    test('impossible pour le pays (TN sous CI) → refus', () {
      expect(
        () => PhoneCanonicalizer.toE164('20113786', isoCode: IsoCode.CI),
        throwsA(isA<PhoneCanonicalizationException>()),
      );
    });

    test('formats alternatifs → même canonique', () {
      final a = PhoneCanonicalizer.toE164('+21620113786');
      final b = PhoneCanonicalizer.toE164('0021620113786');
      final c = PhoneCanonicalizer.toE164('20113786', isoCode: IsoCode.TN);
      expect(a, b);
      expect(b, c);
    });

    test('aucun +225 auto sur international non ivoirien', () {
      final e164 = PhoneCanonicalizer.toE164('+21620113786');
      expect(e164, '+21620113786');
      expect(e164.startsWith('+225'), isFalse);
    });

    test('normalizeLoginIdentifiant', () {
      expect(
        PhoneCanonicalizer.normalizeLoginIdentifiant('0021620113786'),
        '+21620113786',
      );
      expect(
        PhoneCanonicalizer.normalizeLoginIdentifiant(
          '20113786',
          isoCode: IsoCode.TN,
        ),
        '+21620113786',
      );
      expect(
        PhoneCanonicalizer.normalizeLoginIdentifiant('User@Example.COM'),
        'user@example.com',
      );
    });
  });
}
