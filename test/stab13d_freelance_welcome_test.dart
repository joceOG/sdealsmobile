import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/freelance_registration/screens/freelance_welcome_screen.dart';

Future<void> _pumpWelcome(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        padding: const EdgeInsets.only(bottom: 24),
      ),
      child: const MaterialApp(
        home: FreelanceWelcomeScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STAB-13D — Welcome Freelance', () {
    testWidgets('contenu talent-first + CTA sticky', (tester) async {
      await _pumpWelcome(tester);

      expect(
        find.text('Développez votre activité freelance avec Soutrali Deals'),
        findsOneWidget,
      );
      expect(find.textContaining('compétences'), findsWidgets);
      expect(find.text('Trouvez de nouvelles missions'), findsOneWidget);
      expect(find.text('Mettez en avant votre expertise'), findsOneWidget);
      expect(find.text('Gérez vos échanges simplement'), findsOneWidget);
      expect(find.text('Pour créer votre profil, préparez :'), findsOneWidget);
      expect(
        find.text('Vous pourrez compléter certaines informations plus tard.'),
        findsOneWidget,
      );
      expect(find.text('Créer mon profil freelance'), findsOneWidget);

      // Vocabulaire interdit
      expect(find.textContaining('gig'), findsNothing);
      expect(find.textContaining('package'), findsNothing);
      expect(find.textContaining('boutique'), findsNothing);
      expect(find.textContaining('zone d’intervention'), findsNothing);
      expect(find.textContaining('zone d\'intervention'), findsNothing);
    });

    testWidgets('hero asset freelance + bouton fermer', (tester) async {
      await _pumpWelcome(tester);
      expect(find.byTooltip('Fermer'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });

    for (final size in [
      const Size(320, 568),
      const Size(360, 640),
      const Size(390, 844),
      const Size(412, 915),
    ]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
            '${size.width.toInt()}×${size.height.toInt()} scale $scale',
            (tester) async {
          await _pumpWelcome(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          expect(find.text('Créer mon profil freelance'), findsOneWidget);

          // Scroll pour vérifier le contenu bas de page
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -280),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          expect(find.text('Créer mon profil freelance'), findsOneWidget);
        });
      }
    }
  });
}
