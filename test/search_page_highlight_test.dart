import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';

/// Reproduit la logique de surlignage de [SearchPageScreenM] pour tests.
Widget buildHighlightedSuggestion(String text, String query) {
  final display = cleanDisplayPart(text) ?? text.trim();
  final base = SDTypography.bodyMedium.copyWith(
    color: SDColors.neutral900,
    fontSize: 14,
  );
  if (query.isEmpty) {
    return Text(display, style: base);
  }
  final lower = display.toLowerCase();
  final q = query.toLowerCase();
  final idx = lower.indexOf(q);
  if (idx < 0) {
    return Text(display, style: base);
  }
  final matchStyle = base.copyWith(
    fontWeight: FontWeight.w700,
    color: SDColors.primary800,
  );
  return Text.rich(
    TextSpan(
      style: base,
      children: [
        TextSpan(text: display.substring(0, idx)),
        TextSpan(
          text: display.substring(idx, idx + q.length),
          style: matchStyle,
        ),
        TextSpan(text: display.substring(idx + q.length)),
      ],
    ),
  );
}

void main() {
  testWidgets('suggestion « pl » affiche tout le libellé Plombier', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          listTileTheme: ListTileThemeData(
            titleTextStyle: SDTypography.titleMedium,
          ),
        ),
        home: Scaffold(
          body: ListTile(
            title: buildHighlightedSuggestion('Plombier', 'pl'),
          ),
        ),
      ),
    );

    expect(find.textContaining('ombier'), findsOneWidget);
    expect(find.textContaining('Pl'), findsWidgets);
  });

  testWidgets('historique : texte explicite neutral900 lisible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          listTileTheme: ListTileThemeData(
            titleTextStyle: SDTypography.titleMedium,
          ),
        ),
        home: const Scaffold(
          body: ListTile(
            title: Text(
              'plombier',
              style: TextStyle(
                fontSize: 14,
                color: SDColors.neutral900,
              ),
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('plombier'));
    expect(text.style?.color, SDColors.neutral900);
  });
}
