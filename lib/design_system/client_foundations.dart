/// Fondations client 10D-1. Tokens et helpers sans interface.
/// Non installés dans [MaterialApp] : aucun écran ne change dans cette phase.
///
/// Interdictions de migration (10D-2 à 10D-5) :
/// * pas de titre 32 dp sur l'accueil ;
/// * pas de taille locale arbitraire ;
/// * pas de section entièrement en majuscules ;
/// * pas de prix avec une taille différente selon l'écran ;
/// * pas de PNG d'univers sur l'accueil cible ;
/// * Material Icons outlined au repos, filled pour l'élément actif, 24 dp ;
/// * photos réelles uniquement pour personnes, métiers ou réalisations ;
/// * un timeout n'est jamais stylé comme hors connexion.
library;

import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Élévation et bordures. Politique seulement : pas appliquée aux écrans.
class SDClientElevation {
  SDClientElevation._();

  /// Carte : pas d'ombre lourde. Bordure légère.
  static const double card = 0;

  static const double cardBorderWidth = 1;

  static const Color cardBorder = SDColors.neutral200;

  /// Barre basse : une élévation légère. Le blur 20 actuel de la barre
  /// sera aligné en 10D-2, pas ici.
  static const double bar = 4;

  static const double barBlur = 12;

  static const Color focus = SDColors.primary600;

  static const Color pressed = SDColors.primary700;

  static const Color disabled = SDColors.neutral500;
}

/// Tailles d'icônes. Les PNG d'univers ne sont pas supprimés dans cette phase.
class SDClientIcons {
  SDClientIcons._();

  static const double standard = SDSpacing.iconStandard;

  static const double informative = SDSpacing.iconInformative;

  static const double touchTarget = SDSpacing.minTouchTarget;
}

/// États sémantiques. Les widgets de référence restent
/// [GuestAuthState], [SDErrorState] et [SDLoadingInline].
enum SDContentState {
  loading,
  empty,
  error,
  offline,
  disabled,
  success,
  authRequired,
}

/// Distingue hors connexion, erreur et timeout. Un timeout n'est pas offline.
class SDContentStatePolicy {
  SDContentStatePolicy._();

  static SDContentState classify({
    required bool offline,
    required bool timedOut,
    required bool failed,
  }) {
    if (offline) return SDContentState.offline;
    if (timedOut || failed) return SDContentState.error;
    return SDContentState.empty;
  }
}

/// Confiance. Ne jamais présenter la vérification comme une garantie de qualité.
class SDClientTrust {
  SDClientTrust._();

  static const identityVerified = 'Identité vérifiée';

  /// Uniquement si le serveur a `verifier == true`. Sinon null : pas de badge.
  static String? identityVerifiedLabel({required bool verified}) =>
      verified ? identityVerified : null;
}

/// Ville affichée tant que le GPS n'est pas accordé. Permission au moment utile.
class SDClientLocationPolicy {
  SDClientLocationPolicy._();

  static const fallbackCity = 'Abidjan';

  /// Centre d’Abidjan, utilisé seulement si aucune position n’est encore choisie.
  static const fallbackLatitude = 5.35995;
  static const fallbackLongitude = -4.00826;
}

/// Navigation client validée. Constante seulement : la barre n'est pas modifiée.
class SDClientNav {
  SDClientNav._();

  static const destinations = <String>[
    'Accueil',
    'Explorer',
    'Messagerie',
    'Profil',
  ];

  static const becomeProfessional = 'Devenir professionnel';
}

/// Thème client non branché. Réutilise la palette existante, n'en crée pas une autre.
@immutable
class SDClientTheme extends ThemeExtension<SDClientTheme> {
  const SDClientTheme({
    required this.screenTitle,
    required this.sectionTitle,
    required this.cardTitle,
    required this.body,
    required this.caption,
    required this.price,
  });

  factory SDClientTheme.standard() => const SDClientTheme(
        screenTitle: SDTypography.screenTitle,
        sectionTitle: SDTypography.sectionTitle,
        cardTitle: SDTypography.cardTitle,
        body: SDTypography.body,
        caption: SDTypography.caption,
        price: SDTypography.price,
      );

  final TextStyle screenTitle;
  final TextStyle sectionTitle;
  final TextStyle cardTitle;
  final TextStyle body;
  final TextStyle caption;
  final TextStyle price;

  @override
  SDClientTheme copyWith({
    TextStyle? screenTitle,
    TextStyle? sectionTitle,
    TextStyle? cardTitle,
    TextStyle? body,
    TextStyle? caption,
    TextStyle? price,
  }) {
    return SDClientTheme(
      screenTitle: screenTitle ?? this.screenTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      cardTitle: cardTitle ?? this.cardTitle,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      price: price ?? this.price,
    );
  }

  @override
  SDClientTheme lerp(ThemeExtension<SDClientTheme>? other, double t) {
    if (other is! SDClientTheme) return this;
    return SDClientTheme(
      screenTitle: TextStyle.lerp(screenTitle, other.screenTitle, t)!,
      sectionTitle: TextStyle.lerp(sectionTitle, other.sectionTitle, t)!,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      price: TextStyle.lerp(price, other.price, t)!,
    );
  }
}
