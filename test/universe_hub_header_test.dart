import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/universe_hub_header.dart';

void main() {
  testWidgets('même header Freelance / Métiers (copie différente)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              UniverseHubHeader(
                copy: UniverseHubCopy.freelance,
                onSearch: () {},
                onFilter: () {},
              ),
              UniverseHubHeader(
                copy: UniverseHubCopy.metiers,
                onSearch: () {},
                onFilter: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(UniverseHubHeader), findsNWidgets(2));
    expect(find.byType(SDCircleCloseButton), findsNWidgets(2));
    expect(find.byIcon(Icons.tune_rounded), findsNWidgets(2));
    expect(find.text('Freelance'), findsOneWidget);
    expect(find.text('Des talents pour vos projets'), findsOneWidget);
    expect(find.text('Métiers'), findsOneWidget);
    expect(find.text('Des pros près de chez vous'), findsOneWidget);
    expect(find.text('Quel service recherchez-vous ?'), findsNWidgets(2));
  });
}
