import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/delete_account_screen.dart';

/// Smoke d’intégration léger (parcours UI sans backend réel).
void main() {
  testWidgets('parcours profil → suppression compte (UI)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(title: const Text('Accueil')),
              body: ListView(
                children: [
                  const ListTile(title: Text('Recherche')),
                  const ListTile(title: Text('Fiche')),
                  const ListTile(title: Text('Appel simulé')),
                  const ListTile(title: Text('Profil')),
                  ListTile(
                    title: const Text('Supprimer mon compte'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DeleteAccountScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Recherche'), findsOneWidget);
    expect(find.text('Fiche'), findsOneWidget);
    expect(find.text('Appel simulé'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cette action est définitive'), findsOneWidget);
    expect(find.text('Ouvrir la page web de suppression'), findsOneWidget);
  });
}
