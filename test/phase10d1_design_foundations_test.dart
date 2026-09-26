import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

void main() {
  test('palette verte inchangée', () {
    expect(SDColors.primary500, const Color(0xFF1CBF3F));
    expect(SDColors.primary600, const Color(0xFF1AA12A));
    expect(SDColors.primary500, isNot(equals(SDColors.secondary500)));
  });

  test('tokens historiques non réécrits', () {
    expect(SDTypography.titleLarge.fontSize, 20);
    expect(SDTypography.pageTitle.fontSize, 28);
    expect(SDTypography.displayLarge.fontSize, 32);
    expect(SDTypography.priceDisplay.fontSize, 24);
    expect(SDTypography.priceMedium.fontSize, 18);
    expect(SDTypography.bodyLarge.fontSize, 16);
    expect(SDSpacing.sm, 16);
    expect(SDSpacing.buttonHeight, 56);
    expect(SDSpacing.buttonHeightCompact, 48);
    expect(SDSpacing.inputHeight, 56);
    expect(SDAnimations.short, const Duration(milliseconds: 200));
    expect(SDAnimations.bounce, Curves.elasticOut);
  });

  test('rôles typographiques client', () {
    expect(SDTypography.fontFamily, 'Inter');
    expect(SDTypography.screenTitle.fontSize, 22);
    expect(SDTypography.screenTitle.fontWeight, FontWeight.w600);
    expect(SDTypography.screenTitle.height, 1.3);
    expect(SDTypography.sectionTitle.fontSize, 18);
    expect(SDTypography.sectionTitle.fontWeight, FontWeight.w600);
    expect(SDTypography.cardTitle.fontSize, 16);
    expect(SDTypography.cardTitle.fontWeight, FontWeight.w600);
    expect(SDTypography.body.fontSize, 15);
    expect(SDTypography.body.fontWeight, FontWeight.w400);
    expect(SDTypography.body.height, 1.4);
    expect(SDTypography.caption.fontSize, 13);
    expect(SDTypography.caption.fontWeight, FontWeight.w400);
    expect(SDTypography.price.fontSize, 16);
    expect(SDTypography.price.fontWeight, FontWeight.w600);
    expect(SDTypography.screenTitle.fontSize, isNot(32));
    expect(SDTypography.price.fontSize, SDTypography.cardTitle.fontSize);
  });

  test('espacements et rayons sont des alias, pas une deuxième échelle', () {
    expect(SDSpacing.unit, 4);
    expect(SDSpacing.spaceMinimal, 4);
    expect(SDSpacing.spaceSmall, 8);
    expect(SDSpacing.spaceRelated, 12);
    expect(SDSpacing.screenMargin, 16);
    expect(SDSpacing.spaceBlock, 24);
    expect(SDSpacing.spaceLarge, 32);
    expect(SDSpacing.clientHorizontalMargin, 16);
    expect(SDSpacing.cardInterval, 12);
    expect(SDSpacing.sectionInterval, 24);
    expect(SDSpacing.radiusChip, 8);
    expect(SDSpacing.radiusButton, 12);
    expect(SDSpacing.radiusField, 12);
    expect(SDSpacing.radiusCard, 16);
    expect(SDSpacing.radiusSheet, 24);
    expect(SDSpacing.radiusButton, SDSpacing.borderRadiusMedium);
    expect(SDSpacing.radiusChip, SDSpacing.borderRadiusSmall);
    expect(SDSpacing.minTouchTarget, 48);
    expect(SDSpacing.iconStandard, 24);
    expect(SDSpacing.iconInformative, 20);
    expect(SDClientIcons.standard, SDSpacing.iconStandard);
    expect(SDClientIcons.touchTarget, SDSpacing.minTouchTarget);
  });

  test('durées client et reduce motion', () {
    expect(SDClientMotion.touchFeedback, const Duration(milliseconds: 100));
    expect(SDClientMotion.stateChange, const Duration(milliseconds: 150));
    expect(SDClientMotion.sheetOpen, const Duration(milliseconds: 200));
    expect(SDClientMotion.skeleton, const Duration(milliseconds: 150));
    expect(SDClientMotion.favorite, const Duration(milliseconds: 120));
    expect(SDClientMotion.touchCurve, Curves.easeOut);
    expect(SDClientMotion.stateCurve, Curves.easeOutCubic);
    expect(SDClientMotion.sheetCurve, Curves.easeOutCubic);
    expect(SDClientMotion.favoriteCurve, isNot(Curves.elasticOut));
  });

  testWidgets('reduce motion rend la durée nulle', (tester) async {
    late Duration resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            resolved = SDClientMotion.resolve(
              context,
              SDClientMotion.sheetOpen,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(resolved, Duration.zero);
  });

  test('états : timeout distinct du hors connexion', () {
    expect(
      SDContentStatePolicy.classify(
        offline: false,
        timedOut: true,
        failed: false,
      ),
      SDContentState.error,
    );
    expect(
      SDContentStatePolicy.classify(
        offline: true,
        timedOut: true,
        failed: true,
      ),
      SDContentState.offline,
    );
    expect(SDContentState.values, hasLength(7));
  });

  test('confiance et navigation validées, sans deuxième palette', () {
    expect(SDClientTrust.identityVerifiedLabel(verified: true),
        'Identité vérifiée');
    expect(SDClientTrust.identityVerifiedLabel(verified: false), isNull);
    expect(SDClientLocationPolicy.fallbackCity, 'Abidjan');
    expect(SDClientNav.destinations, [
      'Accueil',
      'Explorer',
      'Messagerie',
      'Profil',
    ]);
    expect(SDClientNav.destinations, isNot(contains('Publier')));
    expect(SDClientElevation.card, 0);
    expect(SDClientElevation.cardBorder, SDColors.neutral200);
    expect(SDClientElevation.focus, SDColors.primary600);
    final theme = SDClientTheme.standard();
    expect(theme.screenTitle.fontSize, 22);
    expect(theme.price, SDTypography.price);
    expect(theme.lerp(theme, 0.5).body.fontSize, 15);
  });

  testWidgets('composants SD existants compilent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: SDWhiteAppBar.appBar(title: 'Titre'),
          body: ListView(
            children: const [
              SDButton(text: 'Appeler'),
              SDInput(label: 'Ville'),
              SDCard(child: Text('Carte')),
              SDErrorState(message: 'Erreur'),
              SDLoadingInline(),
              GuestAuthState(
                title: 'Connexion',
                description: 'Mur invité',
                icon: Icons.lock_outline,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Appeler'), findsOneWidget);
    expect(find.text('Erreur'), findsOneWidget);
    expect(find.text('Connexion'), findsOneWidget);
  });
}
