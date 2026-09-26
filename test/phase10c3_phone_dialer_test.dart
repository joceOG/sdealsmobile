import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/utils/phone_dialer.dart';

void main() {
  tearDown(PhoneDialer.resetForTest);

  test('numéro international avec +', () async {
    final logs = <String>[];
    Uri? seen;
    PhoneDialer.logStatus = logs.add;
    PhoneDialer.launch = (uri) async {
      seen = uri;
      return true;
    };
    PhoneDialer.canLaunchUrlCheck = (_) async => true;
    final result = await PhoneDialer.openDialer('+2250700000000');
    expect(result.opened, isTrue);
    expect(seen.toString(), 'tel:+2250700000000');
    expect(logs.join(' '), isNot(contains('0700000000')));
    expect(PhoneDialer.openCount, 1);
  });

  test('espaces, tirets et parenthèses', () {
    expect(PhoneDialer.normalize('+225 07 00 00 00 00'), '+2250700000000');
    expect(PhoneDialer.normalize('+225-07-00-00-00-00'), '+2250700000000');
    expect(PhoneDialer.normalize('(07) 00-00-00-00'), '0700000000');
    expect(PhoneDialer.buildTelUri('(07) 00-00-00-00').toString(),
        'tel:0700000000');
  });

  test('vide et invalide', () async {
    expect(await PhoneDialer.openDialer(null), isA<PhoneDialResult>());
    expect((await PhoneDialer.openDialer('   ')).outcome,
        PhoneDialOutcome.invalidNumber);
    expect((await PhoneDialer.openDialer('abc')).outcome,
        PhoneDialOutcome.invalidNumber);
    expect((await PhoneDialer.openDialer('12')).outcome,
        PhoneDialOutcome.invalidNumber);
    expect(PhoneDialer.normalize('+'), isNull);
    expect(PhoneDialer.normalize('++2250700000000'), isNull);
  });

  test('pas d’indicatif 225 ajouté', () {
    expect(PhoneDialer.normalize('0700000000'), '0700000000');
    expect(PhoneDialer.normalize('0700000000')!.startsWith('+225'), isFalse);
  });

  test('canLaunchUrl false', () async {
    PhoneDialer.canLaunchUrlCheck = (_) async => false;
    PhoneDialer.launch = (_) async => true;
    final result = await PhoneDialer.openDialer('+2250700000000');
    expect(result.outcome, PhoneDialOutcome.launchFailed);
    expect(PhoneDialer.openCount, 0);
  });

  test('composeur une seule fois si déjà en cours', () async {
    PhoneDialer.canLaunchUrlCheck = (_) async => true;
    PhoneDialer.launch = (uri) async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      return true;
    };
    final first = DialerSession.openOnce('+2250700000000');
    final second = DialerSession.openOnce('+2250700000000');
    final results = await Future.wait([first, second]);
    expect(PhoneDialer.openCount, 1);
    expect(results.where((r) => r.opened).length, 1);
    expect(
        results
            .where((r) => r.outcome == PhoneDialOutcome.alreadyOpening)
            .length,
        1);
  });
}
