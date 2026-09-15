import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/delete_account_screen.dart';
import 'package:sdealsmobile/data/utils/legal_urls.dart';

/// Smoke Soutrali Deals (remplace le template compteur).
void main() {
  testWidgets('smoke — marque + écran suppression compte', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Soutrali Deals')),
        ),
      ),
    );
    expect(find.text('Soutrali Deals'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: DeleteAccountScreen()));
    await tester.pump();

    expect(find.text('Supprimer mon compte'), findsWidgets);
    expect(find.textContaining('n’est pas une simple déconnexion'),
        findsOneWidget);
    expect(find.text('Confirmer la suppression'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  test('URL suppression compte stable', () {
    expect(LegalUrls.suppressionCompte, contains('/suppression-compte'));
    expect(LegalUrls.confidentialite, contains('/confidentialite'));
  });
}
