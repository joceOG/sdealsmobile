// STAB-13 Responsive Final Gate — widget/render tests
//
// Chaque test pumpe dans un viewport physique précis et vérifie :
//   • aucun RenderFlex overflow (FlutterError → test fail automatique)
//   • hauteurs mesurées cohérentes avec SDCtaBarHeight
//   • scroll accessible avec clavier simulé (viewInsets.bottom)
//
// Les écrans qui dépendent de BLoC (Login, Accueil, Fiche prestataire)
// sont testés via leurs composants layout critiques, pas via le Scaffold complet.
// GuestAuthState, SDButton, SDEntityCard n'ont pas de dépendances → tests complets.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Définit le viewport physique du test et restaure après.
void _setViewport(WidgetTester tester, double w, double h) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

/// Encapsule un widget dans MaterialApp + MediaQuery + Scaffold.
///
/// [keyboard] = viewInsets.bottom, simule le clavier Android ouvert.
Widget _wrap(
  Widget child, {
  double scale = 1.0,
  double keyboard = 0,
  EdgeInsets safePad = EdgeInsets.zero,
}) {
  return MediaQuery(
    data: MediaQueryData(
      textScaler: TextScaler.linear(scale),
      viewInsets: EdgeInsets.only(bottom: keyboard),
      padding: safePad,
    ),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: child),
    ),
  );
}

/// Formulaire login simplifié — sans Image.asset ni GoRouter.
/// Reproduit la structure layout critique : header + champs + CTA.
Widget _loginForm({double keyboard = 0, double scale = 1.3}) {
  return _wrap(
    SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header sans asset image
          Text(
            'Connexion',
            textAlign: TextAlign.center,
            style: SDTypography.displayMedium.copyWith(color: SDColors.neutral900),
          ),
          const SizedBox(height: 8),
          Text(
            'Accédez à votre compte Soutrali Deals',
            textAlign: TextAlign.center,
            style: SDTypography.bodyLarge.copyWith(color: SDColors.neutral600),
          ),
          const SizedBox(height: 24),
          // Champs (TextField brut, même layout que SDInput)
          TextField(
            key: const Key('field_phone'),
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              hintText: '+225 07 00 00 00 00',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('field_password'),
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              hintText: '6 caractères minimum',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SDButton(
            key: const Key('cta_login'),
            text: 'Se connecter',
            fullWidth: true,
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          SDButton(
            key: const Key('cta_register'),
            text: 'Créer un compte',
            type: SDButtonType.outlined,
            fullWidth: true,
            onPressed: () {},
          ),
        ],
      ),
    ),
    scale: scale,
    keyboard: keyboard,
  );
}

/// Formulaire inscription simplifié (plus de champs → plus de scroll).
Widget _registerForm({double keyboard = 0, double scale = 1.3}) {
  return _wrap(
    SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Créer un compte',
            textAlign: TextAlign.center,
            style: SDTypography.displayMedium.copyWith(color: SDColors.neutral900),
          ),
          const SizedBox(height: 8),
          Text(
            'Rejoignez la communauté Soutrali Deals',
            textAlign: TextAlign.center,
            style: SDTypography.bodyLarge.copyWith(color: SDColors.neutral600),
          ),
          const SizedBox(height: 24),
          for (final label in ['Prénom', 'Nom *', 'Email *', 'Mot de passe *']) ...[
            TextField(
              obscureText: label.startsWith('Mot de passe'),
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          SDButton(
            key: const Key('cta_create'),
            text: 'Créer mon compte',
            fullWidth: true,
            onPressed: () {},
          ),
        ],
      ),
    ),
    scale: scale,
    keyboard: keyboard,
  );
}

/// Barre CTA du formulaire d'inscription avec Retour (step > 0).
Widget _ctaWithBack({double scale = 1.3}) {
  return _wrap(
    Column(
      children: [
        const Expanded(child: Placeholder()),
        Container(
          key: const Key('cta_bar'),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          color: SDColors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SDButton(
                text: 'Continuer',
                icon: Icons.arrow_forward_rounded,
                iconRight: true,
                fullWidth: true,
                onPressed: () {},
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Retour',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.neutral600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    scale: scale,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 1 — GuestAuthState : Messages invité + Profil invité
  // ═══════════════════════════════════════════════════════════════════════════

  group('STAB-13 G1 — GuestAuthState tous viewports', () {
    const cases = [
      (320.0, 568.0, 1.3, 'Messages invité'),
      (320.0, 568.0, 1.3, 'Profil invité'),
      (360.0, 640.0, 1.0, 'Messages invité'),
      (360.0, 640.0, 1.3, 'Messages invité'),
      (390.0, 844.0, 1.0, 'Profil invité'),
      (412.0, 915.0, 1.0, 'Messages invité'),
    ];

    for (final (w, h, s, label) in cases) {
      final isMessages = label.contains('Messages');
      testWidgets('$label — ${w.toInt()}×${h.toInt()} / scale $s', (tester) async {
        _setViewport(tester, w, h);

        await tester.pumpWidget(
          _wrap(
            isMessages
                ? const GuestAuthState(
                    pageTitle: 'Messages',
                    title: 'Connectez-vous pour accéder à vos messages',
                    description:
                        'Discutez directement avec les prestataires, freelances et vendeurs.',
                    icon: Icons.forum_outlined,
                  )
                : const GuestAuthState(
                    pageTitle: 'Profil',
                    title: 'Connectez-vous à votre profil',
                    description:
                        'Gérez vos informations, favoris, demandes et votre activité Soutrali Deals.',
                    icon: Icons.person_outline_rounded,
                  ),
            scale: s,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Aucune exception layout.
        expect(tester.takeException(), isNull,
            reason: 'Aucun overflow à ${w}×$h / scale $s');

        // 2. Les deux CTA doivent être rendus et trouvables.
        expect(find.text('Se connecter'), findsOneWidget,
            reason: 'CTA "Se connecter" manquant');
        expect(find.text('Créer un compte'), findsOneWidget,
            reason: 'CTA "Créer un compte" manquant');
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 2 — SDButton : hauteur stable à textScale 1.3
  // ═══════════════════════════════════════════════════════════════════════════

  group('STAB-13 G2 — SDButton hauteur stable', () {
    testWidgets('large (56 dp) stable à textScale 1.3 / texte long', (tester) async {
      _setViewport(tester, 320, 568);

      await tester.pumpWidget(
        _wrap(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SDButton(
                  text: 'Créer mon profil prestataire',
                  fullWidth: true,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                SDButton(
                  text: 'Demander un devis gratuit pour ce service',
                  fullWidth: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          scale: 1.3,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Chaque bouton ElevatedButton doit être à SDSpacing.buttonHeight (56 dp).
      for (final btn in tester.widgetList(find.byType(ElevatedButton))) {
        final h = tester.getSize(find.byWidget(btn)).height;
        expect(h, closeTo(SDSpacing.buttonHeight, 4.0),
            reason:
                'SDButton.large doit rester ${SDSpacing.buttonHeight}dp à textScale 1.3 '
                '(mesuré: ${h}dp)');
      }
    });

    testWidgets('outlined large (56 dp) stable à textScale 1.3', (tester) async {
      _setViewport(tester, 320, 568);

      await tester.pumpWidget(
        _wrap(
          Padding(
            padding: const EdgeInsets.all(16),
            child: SDButton(
              text: 'Créer un compte',
              type: SDButtonType.outlined,
              fullWidth: true,
              onPressed: () {},
            ),
          ),
          scale: 1.3,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      final h = tester.getSize(find.byType(OutlinedButton).first).height;
      expect(h, closeTo(SDSpacing.buttonHeight, 4.0));
    });

    testWidgets(
        'small — tapTargetSize.padded → zone layout ≥ 48dp (touch), tap déclenché',
        (tester) async {
      _setViewport(tester, 320, 568);

      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          Center(
            child: SDButton(
              text: 'Réessayer',
              size: SDButtonSize.small,
              onPressed: () => tapped = true,
            ),
          ),
          scale: 1.3,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      // tapTargetSize.padded étend la zone tactile au-delà des 40dp visuels.
      // Flutter rend le widget à 48dp de layout (zone transparente incluse).
      // C'est le comportement correct — la zone de touch ≥ 48dp est garantie.
      final h = tester.getSize(find.byType(ElevatedButton).first).height;
      expect(
        h,
        greaterThanOrEqualTo(48.0),
        reason:
            'tapTargetSize.padded doit donner une zone tactile ≥ 48dp '
            '(mesuré: ${h}dp)',
      );

      // Tap au centre : déclenche onPressed.
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      expect(tapped, isTrue,
          reason: 'SDButton.small doit répondre au tap');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 3 — SDCtaBarHeight : hauteurs réelles vs constantes
  // ═══════════════════════════════════════════════════════════════════════════

  group('STAB-13 G3 — SDCtaBarHeight mesure réelle', () {
    testWidgets('single — CTA two-button row ≤ SDCtaBarHeight.single + 8dp',
        (tester) async {
      _setViewport(tester, 320, 568);

      // Reproduit _buildBottomActions de provider_profile_screen.
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              const Expanded(child: Placeholder()),
              Container(
                key: const Key('cta_single'),
                padding: EdgeInsets.all(SDSpacing.sm), // all(16)
                color: SDColors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: SDButton(
                        text: 'Appeler',
                        type: SDButtonType.outlined,
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(width: SDSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: SDButton(
                        text: 'Demander un service',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          scale: 1.3,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      final ctaH = tester.getSize(find.byKey(const Key('cta_single'))).height;
      // La constante doit couvrir la hauteur réelle (marge +8dp acceptable).
      expect(
        SDCtaBarHeight.single,
        greaterThanOrEqualTo(ctaH - 8),
        reason:
            'SDCtaBarHeight.single (${SDCtaBarHeight.single}dp) doit ≥ '
            'hauteur réelle CTA (${ctaH}dp) − 8dp',
      );
    });

    testWidgets(
        'withBack — CTA + TextButton Retour ≤ SDCtaBarHeight.withBack + 8dp',
        (tester) async {
      _setViewport(tester, 320, 568);

      await tester.pumpWidget(_ctaWithBack(scale: 1.3));
      await tester.pump();
      expect(tester.takeException(), isNull);

      final ctaH = tester.getSize(find.byKey(const Key('cta_bar'))).height;
      expect(
        SDCtaBarHeight.withBack,
        greaterThanOrEqualTo(ctaH - 8),
        reason:
            'SDCtaBarHeight.withBack (${SDCtaBarHeight.withBack}dp) doit ≥ '
            'hauteur réelle CTA (${ctaH}dp) − 8dp',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 4 — Login / Register / Création profil + clavier simulé
  // ═══════════════════════════════════════════════════════════════════════════

  group('STAB-13 G4 — Formulaires auth + clavier', () {
    testWidgets('Login — 320×568 / scale 1.3 / sans clavier', (tester) async {
      _setViewport(tester, 320, 568);

      await tester.pumpWidget(_loginForm());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Se connecter'), findsWidgets);
      expect(find.text('Créer un compte'), findsWidgets);
    });

    testWidgets('Login — 320×568 / scale 1.3 / clavier 280dp', (tester) async {
      _setViewport(tester, 320, 568);

      await tester.pumpWidget(_loginForm(keyboard: 280));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Login — 320×568 / scale 1.3 / clavier 280dp — scroll jusqu\'au CTA',
        (tester) async {
      _setViewport(tester, 320, 568);

      await tester.pumpWidget(_loginForm(keyboard: 280));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Scroll complet vers le bas.
      final scroll = find.byType(SingleChildScrollView);
      await tester.drag(scroll, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Le dernier champ et le CTA restent atteignables.
      expect(find.byKey(const Key('cta_login')), findsOneWidget);
    });

    testWidgets('Register — 320×568 / scale 1.3 / sans clavier', (tester) async {
      _setViewport(tester, 320, 568);

      await tester.pumpWidget(_registerForm());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Register — 320×568 / scale 1.3 / clavier 260dp', (tester) async {
      _setViewport(tester, 320, 568);

      await tester.pumpWidget(_registerForm(keyboard: 260));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Register — 320×568 / scale 1.3 / clavier 260dp — scroll jusqu\'au CTA',
        (tester) async {
      _setViewport(tester, 320, 568);

      await tester.pumpWidget(_registerForm(keyboard: 260));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('cta_create')), findsOneWidget);
    });

    testWidgets(
        'Création profil (withBack CTA) — 320×568 / scale 1.3 / sans clavier',
        (tester) async {
      _setViewport(tester, 320, 568);

      await tester.pumpWidget(_ctaWithBack(scale: 1.3));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Continuer'), findsOneWidget);
      expect(find.text('Retour'), findsOneWidget);
    });

    // textScale 1.0 — viewports standards
    for (final (w, h) in [(360.0, 640.0), (390.0, 844.0), (412.0, 915.0)]) {
      testWidgets('Login — ${w.toInt()}×${h.toInt()} / scale 1.0', (tester) async {
        _setViewport(tester, w, h);

        await tester.pumpWidget(_loginForm(scale: 1.0));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Se connecter'), findsWidgets);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 5 — SDEntityCard — nom long / width: null
  // ═══════════════════════════════════════════════════════════════════════════

  group('STAB-13 G5 — SDEntityCard 320dp', () {
    testWidgets('liste horizontale — nom long / scale 1.3', (tester) async {
      _setViewport(tester, 320, 568);

      // La hauteur du container de liste adapte la hauteur à textScale 1.3
      // par la même règle que SDEntityCard.isCompact (adjustedHeight = h / ts).
      // À textScale 1.3 et 240dp → adjustedHeight = 184.6 → isCompact = true
      // → image 68dp → pas d'overflow.
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 240,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                SDEntityCard(
                  type: SDEntityCardType.provider,
                  title: 'Chapechape Residence',
                  subtitle: 'Plomberie',
                  fallbackIcon: Icons.handyman_rounded,
                  ratingText: '4.8/5',
                  metaText: 'Abidjan • 2.3km',
                  priceText: '5 000 FCFA /h',
                ),
                SDEntityCard(
                  type: SDEntityCardType.freelance,
                  title: 'Thomas Alexandre Kouamé Bédié',
                  subtitle: 'Développeur Flutter Senior',
                  fallbackIcon: Icons.laptop_mac_rounded,
                  ratingText: '5.0/5',
                ),
              ],
            ),
          ),
          scale: 1.3,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason:
              'SDEntityCard ne doit pas provoquer de RenderFlex overflow '
              'dans une liste horizontale 240dp à textScale 1.3');
    });

    testWidgets('width: null — ListView verticale pleine largeur / scale 1.3',
        (tester) async {
      _setViewport(tester, 320, 568);

      await tester.pumpWidget(
        _wrap(
          ListView(
            children: const [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  height: 220,
                  child: SDEntityCard(
                    width: null,
                    type: SDEntityCardType.provider,
                    title: 'Chapechape Residence',
                    subtitle: 'Électricité • Plomberie',
                    fallbackIcon: Icons.handyman_rounded,
                    ratingText: '4.8/5',
                    metaText: 'Abidjan • 2.3km',
                    statusText: 'Disponible',
                    priceText: '5 000 FCFA /h',
                    ctaLabel: 'Voir profil',
                  ),
                ),
              ),
            ],
          ),
          scale: 1.3,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 6 — heroHeight clamp
  // ═══════════════════════════════════════════════════════════════════════════

  group('STAB-13 G6 — heroHeight clamp', () {
    /// Hero mesuré via un Container dont la hauteur vient de SDResponsive.heroHeight.
    Future<double> _measureHero(WidgetTester tester, double w, double h) async {
      _setViewport(tester, w, h);
      double? heroH;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(w, h)),
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                heroH = SDResponsive.heroHeight(ctx);
                return Container(height: heroH!, color: Colors.blue);
              },
            ),
          ),
        ),
      );
      await tester.pump();
      return heroH!;
    }

    testWidgets('320×568 → clamped à 210dp minimum', (tester) async {
      final h = await _measureHero(tester, 320, 568);
      // 35 % × 568 = 198.8 < 210 → clamp → 210.
      expect(h, closeTo(210.0, 0.1));
    });

    testWidgets('360×640 → dans [210, 300]', (tester) async {
      final h = await _measureHero(tester, 360, 640);
      // 35 % × 640 = 224 → dans [210, 300]. ✓
      expect(h, greaterThanOrEqualTo(210.0));
      expect(h, lessThanOrEqualTo(300.0));
    });

    testWidgets('390×844 → dans [210, 300]', (tester) async {
      final h = await _measureHero(tester, 390, 844);
      expect(h, inInclusiveRange(210.0, 300.0));
    });

    testWidgets('412×915 → dans [210, 300]', (tester) async {
      final h = await _measureHero(tester, 412, 915);
      expect(h, inInclusiveRange(210.0, 300.0));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 7 — Stepper compact labels courts (320dp)
  // ═══════════════════════════════════════════════════════════════════════════

  group('STAB-13 G7 — Stepper labels courts < 360dp', () {
    testWidgets('isCompact → true à 320dp', (tester) async {
      _setViewport(tester, 320, 568);
      bool? compact;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(320, 568)),
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                compact = SDResponsive.isCompact(ctx);
                return const Placeholder();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(compact, isTrue, reason: '320dp < 360dp → isCompact doit être true');
    });

    testWidgets('isCompact → false à 360dp', (tester) async {
      _setViewport(tester, 360, 640);
      bool? compact;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(360, 640)),
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                compact = SDResponsive.isCompact(ctx);
                return const Placeholder();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(compact, isFalse, reason: '360dp = SDBreakpoints.compact → isCompact false');
    });

    testWidgets('stepper row 3 labels courts — 320dp / scale 1.3 / no overflow',
        (tester) async {
      _setViewport(tester, 320, 568);

      const labels = ['Infos', 'Activité', 'Tarifs'];
      await tester.pumpWidget(
        _wrap(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: List.generate(labels.length * 2 - 1, (i) {
                    if (i.isOdd) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: SDColors.neutral200,
                        ),
                      );
                    }
                    final step = i ~/ 2;
                    return Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: step == 0
                            ? SDColors.primary600
                            : SDColors.neutral100,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${step + 1}'),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    labels.length,
                    (i) => Expanded(
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          scale: 1.3,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Infos'), findsOneWidget);
      expect(find.text('Activité'), findsOneWidget);
      expect(find.text('Tarifs'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Barre CTA provider_profile_screen — Huawei Y9 Prime stress test
  // ─────────────────────────────────────────────────────────────────────────

  /// Reconstruit la barre CTA (Appeler / Demander un service) de manière
  /// identique à _buildBottomActions() dans provider_profile_screen.dart.
  ///
  /// On évite les dépendances BLoC/GoRouter en testant le widget layout pur.
  Widget _buildCtaBar({
    required double sysBottom,
    double scale = 1.0,
    bool emuiMode = false,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(scale),
        // emuiMode = cas Huawei Y9 Prime mesuré : padding et viewPadding à 0,
        // la barre système n'est remontée QUE dans systemGestureInsets.
        padding: EdgeInsets.zero,
        viewPadding:
            emuiMode ? EdgeInsets.zero : EdgeInsets.only(bottom: sysBottom),
        systemGestureInsets:
            emuiMode ? EdgeInsets.only(bottom: sysBottom) : EdgeInsets.zero,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          bottomNavigationBar: Builder(
            builder: (context) {
              final double bottom = SDResponsive.systemBottomInset(context);
              return Container(
                padding: EdgeInsets.fromLTRB(
                  SDSpacing.sm,
                  SDSpacing.sm,
                  SDSpacing.sm,
                  SDSpacing.sm + bottom,
                ),
                color: SDColors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.phone_outlined),
                        label: const Text(
                          'Appeler',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.send_rounded),
                        label: const Text(
                          'Demander un service',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );
  }

  group('CTA provider_profile — Huawei bottom inset stress', () {
    // Combinaisons testées : viewports × insets × textScale
    const List<(double, double)> viewports = [
      (320, 568), // compact (< 360dp)
      (360, 640), // Huawei Y9 Prime
    ];
    const List<double> insets = [0, 24, 48];
    const List<double> scales = [1.0, 1.3];

    for (final (w, h) in viewports) {
      for (final inset in insets) {
        for (final scale in scales) {
          testWidgets(
            'CTA ${w}dp / inset ${inset}dp / scale $scale — visible, ≥48dp, no overflow',
            (tester) async {
              _setViewport(tester, w, h);

              await tester.pumpWidget(
                _buildCtaBar(sysBottom: inset, scale: scale),
              );
              await tester.pump();

              // Aucune exception Flutter (overflow, contraintes infinies…)
              expect(tester.takeException(), isNull);

              // Les deux labels sont rendus
              expect(find.text('Appeler'), findsOneWidget);
              expect(find.text('Demander un service'), findsOneWidget);

              // Zone tactile bouton Appeler ≥ 48dp
              final appellerBtn = find.widgetWithText(OutlinedButton, 'Appeler');
              expect(appellerBtn, findsOneWidget);
              final appellerH = tester.getSize(appellerBtn).height;
              expect(appellerH, greaterThanOrEqualTo(48.0),
                  reason:
                      'Appeler tap-target height $appellerH < 48dp @ ${w}dp / scale $scale');

              // Zone tactile bouton Demander ≥ 48dp
              final demanderBtn =
                  find.widgetWithText(ElevatedButton, 'Demander un service');
              expect(demanderBtn, findsOneWidget);
              final demanderH = tester.getSize(demanderBtn).height;
              expect(demanderH, greaterThanOrEqualTo(48.0),
                  reason:
                      'Demander tap-target height $demanderH < 48dp @ ${w}dp / scale $scale');

              // Le Container CTA absorbe bien l'inset système
              // (hauteur totale ≥ 48dp bouton + 16dp top-pad + inset)
              final ctaContainer = find.ancestor(
                of: find.text('Appeler'),
                matching: find.byType(Container),
              );
              final ctaH = tester.getSize(ctaContainer.first).height;
              final expectedMin = 48.0 + 16.0 + inset;
              expect(ctaH, greaterThanOrEqualTo(expectedMin),
                  reason:
                      'CTA bar height $ctaH < $expectedMin @ ${w}dp / inset ${inset}dp');
            },
          );
        }
      }
    }

    // Cas EMUI mesuré sur Huawei Y9 Prime (overlay debug 25/08) :
    // MQ.padding = 0, MQ.viewPadding = 0, View.viewPadding = 0,
    // systemGestureInsets.bottom = 38.7 — seule source disponible.
    testWidgets(
      'CTA EMUI réel — gestureInsets 38.7 seul, padding/viewPadding = 0',
      (tester) async {
        _setViewport(tester, 360, 780);

        await tester.pumpWidget(
          _buildCtaBar(sysBottom: 38.7, emuiMode: true),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Appeler'), findsOneWidget);
        expect(find.text('Demander un service'), findsOneWidget);

        // La barre doit absorber les 38.7dp remontés par gestureInsets.
        final ctaContainer = find.ancestor(
          of: find.text('Appeler'),
          matching: find.byType(Container),
        );
        final ctaH = tester.getSize(ctaContainer.first).height;
        expect(ctaH, greaterThanOrEqualTo(48.0 + 16.0 + 38.7),
            reason: 'CTA bar doit inclure gestureInsets EMUI (38.7dp), '
                'hauteur mesurée: $ctaH');
      },
    );
  });
}
