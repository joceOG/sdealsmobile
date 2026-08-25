import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// STAB-13 — Couche responsive Soutrali Deals.
///
/// **Philosophie** : deux vrais seuils de composition, pas de profils device.
///
///   [compact] < 360 dp : layout « stress test » (< Huawei Y9 Prime).
///   [tablet]  ≥ 600 dp : mise en page deux colonnes.
///
/// Tout ce qui est entre 360 dp et 600 dp utilise les contraintes naturelles
/// Flutter (Flexible, Expanded, LayoutBuilder, clamp, FractionallySizedBox).
/// 390 dp et 412 dp sont des largeurs spécifiques Samsung/Redmi, pas des
/// changements de composition.
abstract final class SDBreakpoints {
  /// Seuil compact : < 360 dp — changement de composition requis.
  static const double compact = 360.0;

  /// Seuil tablette : ≥ 600 dp — mise en page élargie (colonnes).
  static const double tablet = 600.0;
}

/// Hauteurs CTA prédéfinies pour [SDResponsive.scrollPaddingBelowCta].
///
/// Ces constantes reflètent les hauteurs physiques des barres CTA dans
/// les écrans STAB-13. Elles sont stables quel que soit le textScale car
/// [SDSpacing.buttonHeight] est une contrainte physique (`minimumSize`),
/// non affectée par la mise à l'échelle du texte.
abstract final class SDCtaBarHeight {
  /// Barre à un bouton SDButton — 56 dp bouton + 16×2 padding conteneur = 88 dp.
  ///
  /// Stable à tout textScale car SDButton.minimumSize = 56 dp et le padding
  /// vertical est exclu du style → le bouton ne grossit jamais au-delà de 56 dp.
  /// Mesuré sur provider_profile_screen `EdgeInsets.all(SDSpacing.sm)`.
  static const double single = 88.0;

  /// Barre à deux boutons SDButton empilés (ex. GuestAuthState en sheet).
  /// 2×56 + 16 gap + 24 padding v = 152 dp.
  static const double double_ = 152.0;

  /// Barre avec bouton principal SDButton + TextButton « Retour » dessous.
  /// 12(top) + 56(btn) + 4(gap) + 48(TextButton padded à 1.3×) + 12(bottom) = 132 dp.
  /// Valeur mesurée par widget test à textScale 1.3 — inclut tapTargetSize.padded
  /// sur le TextButton natif qui ajoute ~12 dp de transparence de tap zone.
  static const double withBack = 136.0;
}

/// Helpers responsive — lecture de [MediaQuery] centralisée.
///
/// Usages STAB-13 :
///   - [isCompact] → labels stepper courts (serviceProviderRegistrationScreenM)
///   - [heroHeight] → hauteur hero fiche prestataire (provider_profile_screen)
///   - [scrollPaddingBelowCta] → padding scroll derrière barre CTA
class SDResponsive {
  SDResponsive._();

  // ─── Dimensions ──────────────────────────────────────────────────────────

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  // ─── Catégories ──────────────────────────────────────────────────────────

  /// Viewport < 360 dp — changement de composition.
  static bool isCompact(BuildContext context) =>
      screenWidth(context) < SDBreakpoints.compact;

  /// Alias pour compatibilité avec les appellants qui utilisent isXSmall.
  static bool isXSmall(BuildContext context) => isCompact(context);

  /// Viewport ≥ 600 dp — tablette.
  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= SDBreakpoints.tablet;

  // ─── Valeur adaptive ─────────────────────────────────────────────────────

  /// [compactValue] si < 360 dp, [standardValue] sinon.
  /// À utiliser uniquement pour de vrais changements de composition.
  static T value<T>(
    BuildContext context, {
    required T compactValue,
    required T standardValue,
  }) =>
      isCompact(context) ? compactValue : standardValue;

  // ─── Hero / décorations ──────────────────────────────────────────────────

  /// Hauteur hero clampée entre [minHeight] et [maxHeight], max [fraction]
  /// de la hauteur du viewport.
  ///
  /// Par défaut : 210–300 dp, jamais plus de 35 % de la hauteur écran.
  static double heroHeight(
    BuildContext context, {
    double minHeight = 210.0,
    double maxHeight = 300.0,
    double fraction = 0.35,
  }) =>
      (screenHeight(context) * fraction).clamp(minHeight, maxHeight);

  // ─── Illustration / état vide ────────────────────────────────────────────

  /// Hauteur illustration adaptative pour les états guest / empty.
  ///
  /// Plafonnée à 25 % du viewport pour les petits écrans (320×568).
  static double illustrationHeight(
    BuildContext context, {
    double preferred = 160.0,
    double minHeight = 80.0,
  }) =>
      (screenHeight(context) * 0.25).clamp(minHeight, preferred);

  // ─── Scroll / SafeArea ───────────────────────────────────────────────────

  /// Inset inférieur système fiable, cross-OEM (Huawei EMUI, Xiaomi MIUI…).
  ///
  /// Trois sources consultées dans l'ordre croissant de fiabilité :
  ///
  /// 1. [MediaQuery.paddingOf].bottom — source courante (peut valoir 0 sur EMUI).
  /// 2. [MediaQuery.viewPaddingOf].bottom — insets physiques bruts avant
  ///    ajustement clavier, plus fiable que `padding`.
  /// 3. [View.of].viewPadding.bottom / devicePixelRatio — source native Flutter
  ///    avant toute transformation par le layer MediaQuery. Sur certains EMUI,
  ///    les couches 1 et 2 peuvent être 0 alors que FlutterView possède l'inset.
  ///
  /// Le maximum des sources est retenu sans aucune condition `if Platform`.
  ///
  /// 4. [MediaQuery.systemGestureInsetsOf].bottom — mesure physique Huawei
  ///    Y9 Prime (EMUI) : la barre 3-boutons est remontée UNIQUEMENT dans
  ///    viewInsets/systemGestureInsets (38.7 dp), toutes les autres sources
  ///    valent 0. `systemGestureInsets` est préféré à `viewInsets` car il
  ///    n'est pas contaminé par le clavier (qui ferait un double padding).
  ///    Plafonné à 80 dp par sécurité : une barre système ne dépasse jamais
  ///    cette hauteur, ce qui exclut toute valeur aberrante.
  static double systemBottomInset(BuildContext context) {
    final p = MediaQuery.paddingOf(context).bottom;
    final vp = MediaQuery.viewPaddingOf(context).bottom;
    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    final fromView = view.viewPadding.bottom / dpr;
    // Source EMUI : gesture insets (MediaQuery + FlutterView), plafonnée.
    final gi = MediaQuery.systemGestureInsetsOf(context).bottom;
    final fromViewGesture = view.systemGestureInsets.bottom / dpr;
    final gesture =
        (gi > fromViewGesture ? gi : fromViewGesture).clamp(0.0, 80.0);
    double max = p;
    if (vp > max) max = vp;
    if (fromView > max) max = fromView;
    if (gesture > max) max = gesture;
    return max;
  }

  // ─── Debug / Instrumentation ─────────────────────────────────────────────

  /// Overlay debug [kDebugMode] uniquement — affiche tous les insets système
  /// de la vue courante. À placer dans un [Stack] en position flottante.
  ///
  /// Usage :
  /// ```dart
  /// Stack(children: [...body..., SDResponsive.debugInsetsOverlay(context)])
  /// ```
  static Widget debugInsetsOverlay(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final mq = MediaQuery.of(context);
    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    final vph = view.viewPadding;
    return Positioned(
      top: mq.padding.top + 8,
      left: 8,
      right: 8,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xCC000000),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'DPR: $dpr  W: ${mq.size.width.round()} H: ${mq.size.height.round()}\n'
            'MQ.pad.bot: ${mq.padding.bottom.toStringAsFixed(1)}\n'
            'MQ.viewPad.bot: ${mq.viewPadding.bottom.toStringAsFixed(1)}\n'
            'MQ.viewInsets.bot: ${mq.viewInsets.bottom.toStringAsFixed(1)}\n'
            'MQ.gestureInsets.bot: ${mq.systemGestureInsets.bottom.toStringAsFixed(1)}\n'
            'View.viewPad.bot/dpr: ${(vph.bottom / dpr).toStringAsFixed(1)}\n'
            'systemBottomInset: ${systemBottomInset(context).toStringAsFixed(1)}',
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 10.5,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  /// Padding inférieur d'un [SingleChildScrollView] derrière une barre CTA fixe.
  ///
  /// [ctaHeight] : utiliser [SDCtaBarHeight.single], [SDCtaBarHeight.withBack], etc.
  ///
  /// Utilise [systemBottomInset] pour être fiable sur tous les OEM.
  static double scrollPaddingBelowCta(
    BuildContext context, {
    double ctaHeight = SDCtaBarHeight.single,
  }) =>
      ctaHeight + systemBottomInset(context) + 12.0;

  // ─── Texte ───────────────────────────────────────────────────────────────

  static double textScale(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1.0);

  /// Vrai si l'utilisateur a agrandi les polices système (≥ 1.15).
  static bool isLargeText(BuildContext context) => textScale(context) >= 1.15;
}
