import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';

void main() {
  testWidgets('sheet d’auth explique le contact sans ouvrir le composeur',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const ProtectedAuthSheet(
                    explanation:
                        'Connectez-vous pour contacter ce professionnel',
                  ),
                );
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('Connectez-vous pour contacter ce professionnel'),
        findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('S\'inscrire'), findsOneWidget);
    expect(find.text('tel:'), findsNothing);
  });
}
