import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

void main() {
  testWidgets('SDIllustration réserve 264 dp et le ratio 5:4', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SDIllustration(
              asset: SDIllustrations.profileGuest,
              fallback: Text('secours'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final box = tester.getSize(find.byType(SDIllustration));
    expect(box.width, SDIllustration.nominalWidth);
    expect(box.height, closeTo(SDIllustration.nominalWidth * 4 / 5, 0.01));
  });

  testWidgets('Reduce Motion fige le Lottie sur sa frame de repos',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(
          body: SDIllustration(
            asset: SDIllustrations.profileGuest,
          ),
        ),
      ),
    );
    await tester.pump();

    final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    expect(lottie.animate, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GuestAuthState affiche l’illustration fournie', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GuestAuthState(
            pageTitle: 'Profil',
            title: 'Connectez-vous à votre profil',
            description: 'Description',
            illustration: SDIllustration(
              asset: SDIllustrations.profileGuest,
              fallback: Text('illustration-profil'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Connectez-vous à votre profil'), findsOneWidget);
    expect(find.byType(SDIllustration), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
