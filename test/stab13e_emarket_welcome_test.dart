import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/seller_registration/screens/emarket_welcome_screen.dart';

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
        home: EmarketWelcomeScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STAB-13E — Welcome É-marché', () {
    testWidgets('contenu product-first + CTA sticky', (tester) async {
      await _pumpWelcome(tester);

      expect(
        find.text('Ouvrez votre boutique sur Soutrali Deals'),
        findsOneWidget,
      );
      expect(find.textContaining('produits'), findsWidgets);
      expect(find.text('Vendez vos produits plus facilement'), findsOneWidget);
      expect(find.text('Développez votre visibilité'), findsOneWidget);
      expect(
        find.text('Gérez votre boutique depuis l’application'),
        findsOneWidget,
      );
      expect(find.text('Pour ouvrir votre boutique, préparez :'), findsOneWidget);
      expect(
        find.text(
          'Vous pourrez ajouter d’autres produits et compléter votre boutique plus tard.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ouvrir ma boutique'), findsOneWidget);

      // Vocabulaire interdit
      expect(find.textContaining('mission'), findsNothing);
      expect(find.textContaining('prestation'), findsNothing);
      expect(find.textContaining('freelance'), findsNothing);
      expect(find.textContaining('portfolio'), findsNothing);
      expect(find.textContaining('zone d’intervention'), findsNothing);
      expect(find.textContaining('zone d\'intervention'), findsNothing);
    });

    testWidgets('hero asset e-marche + bouton fermer', (tester) async {
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
          expect(find.text('Ouvrir ma boutique'), findsOneWidget);

          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -280),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          expect(find.text('Ouvrir ma boutique'), findsOneWidget);
        });
      }
    }
  });
}
