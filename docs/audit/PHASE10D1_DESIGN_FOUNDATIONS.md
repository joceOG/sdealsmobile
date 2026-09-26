# PHASE 10D-1 — Fondations du design system client

**Date :** 2026-09-16  
**Application :** `sdealsmobile` / `com.sdealsmobile.app`  
**Branche :** `jordan` (pas de commit)  
**Périmètre :** tokens, constantes, thème non branché, helpers sans interface, tests, documentation. Aucun écran métier.

## Décisions Sidney intégrées

Écrites en tête de `docs/audit/PHASE10D_UX_UI_MASTERPLAN.md`. Elles ne sont plus des questions ouvertes.

1. Navigation : Accueil, Explorer, Messagerie, Profil.
2. Publier quitte la barre, entrée Profil « Devenir professionnel ».
3. Commandes quitte l’AppBar, va dans Profil.
4. Appeler = CTA principal.
5. Demander un service = CTA secondaire.
6. « Identité vérifiée » seulement si `verifier == true`.
7. Ce libellé n’est pas une garantie de qualité.
8. Ville actuelle, sinon Abidjan ; permission GPS au moment utile.
9. Wallet masqué tant qu’aucun paiement réel n’existe.
10. Welcome Freelance retiré du parcours plus tard ; explication à l’accueil et dans la liste.
11. É-marché reste masqué.
12. Aucun CTA connexion sur l’accueil.

Aucune de ces décisions n’est appliquée à un écran dans cette phase. `SDClientNav`, `SDClientTrust` et `SDClientLocationPolicy` les figent pour 10D-2.

## Matrice des tokens existants

| Token | Valeur actuelle | Client | Prestataire | Orphelins | Modification | Doublon |
| --- | --- | --- | --- | --- | --- | --- |
| `primary500` / `primary600` | `#1CBF3F` / `#1AA12A` | Thème global + écrans | Dashboard, inscriptions | Non | Interdit | Non |
| `titleLarge` | 20 / w600 | Accueil, explorer, fiche, auth | Inscriptions, dashboard | Non | Interdit | Proche du nouveau titre 22 |
| `pageTitle` | 28, alias `displayMedium` | `auth_form_widgets` | Indirect | Quasi | Interdit | `screenTitle` est la cible client |
| `displayLarge` | 32 | Onboarding, `GuestAuthState` via displayMedium | Non ciblé | Non | Interdit | Titre 32 à ne pas remettre sur l’accueil |
| `sectionTitle` | 18 / w600, alias `titleMedium` | Alias non consommé | Non | Oui | Déjà conforme | `titleMedium` |
| `cardTitle` | 16 / w600, alias `titleSmall` | Alias non consommé | Non | Oui | Déjà conforme | `titleSmall` |
| `bodyLarge` / `bodyMedium` / `bodySmall` | 16 / 14 / 12 | Large | Large | Non | Interdit | Nouveau `body` 15 et `caption` 13 |
| `priceDisplay` / `priceMedium` | 24 / 18 | Aucun appel hors définition | Aucun appel | Oui | Conservés, non réécrits | Nouveau `price` 16 |
| `SDSpacing.xxxs`…`lg` | 4, 8, 12, 16, 24, 32 | Large | Large (`provider_dashboard`) | Non | Alias seulement | `spaceMinimal`…`spaceLarge` |
| Rayons 8 / 12 / 16 / 24 | Déjà la cible | Widgets SD + `main.dart` | Mêmes widgets | Non | Alias seulement | `radiusChip`…`radiusSheet` |
| `buttonHeight` / compact / `inputHeight` | 56 / 48 / 56 | `SDButton`, thème `main.dart` | Mêmes widgets | Non | Non agrandis | Hauteur 40 locale de `SDButtonSize.small` |
| `minTouchTarget` | 48 | Partagé | Partagé | Non | Déjà conforme | — |
| `SDAnimations.short` | 200 ms | `SDCard` | `SDCard`, rond | Non | Interdit | `sheetOpen` nomme le même 200 ms côté client |
| `bounce` / `scaleBounce` | `elasticOut` | Aucun appel écran | Aucun appel écran | Définition | Non supprimés | Interdits au client, documentés |

## Tokens conservés

Palette verte, échelle 4 dp, `titleLarge` 20, `pageTitle` 28, `bodyLarge` 16, `priceDisplay` 24, `buttonHeight` 56, rayons historiques, `SDAnimations.short` 200 ms, `bounce`. Aucune deuxième palette. `SDClientTheme` n’est pas installé dans `MaterialApp`.

## Tokens ajoutés ou normalisés

| Rôle | Token | Valeur |
| --- | --- | --- |
| Titre écran | `SDTypography.screenTitle` | 22 / w600 / 1.3 |
| Titre section | `sectionTitle` existant | 18 / w600 |
| Titre carte | `cardTitle` existant | 16 / w600 |
| Corps | `SDTypography.body` | 15 / w400 / 1.4 |
| Légende | `SDTypography.caption` | 13 / w400 / 1.4 |
| Prix | `SDTypography.price` | 16 / w600 / 1.3 |
| Espaces | `spaceMinimal` … `spaceLarge`, `clientHorizontalMargin`, `cardInterval`, `sectionInterval` | 4, 8, 12, 16, 24, 32, 16, 12, 24 |
| Rayons | `radiusChip`, `radiusButton`, `radiusField`, `radiusCard`, `radiusSheet` | 8, 12, 12, 16, 24 |
| Cibles | `iconStandard`, `iconInformative` | 24, 20 ; tactile 48 déjà là |
| Mouvement | `SDClientMotion` | 100 easeOut, 150 easeOutCubic, 200 easeOutCubic, 150 easeOut, 120 easeOut |
| Reduce Motion | `SDClientMotion.resolve` | durée 0, courbe linéaire |
| Élévation | `SDClientElevation` | carte 0 + bordure `neutral200` ; barre blur 12 ; focus / pressed / disabled |
| États | `SDContentState` + `SDContentStatePolicy` | timeout → erreur, jamais offline |
| Thème | `SDClientTheme.standard()` | non branché |

## Compatibilité client / prestataire

Les tokens lus par le dashboard prestataire et par `main.dart` n’ont pas changé de signification. Les rôles client sont des ajouts. `bounce` reste disponible. Aucun widget visuel (`SDButton`, `SDEntityCard`, AppBars) n’a été modifié.

Rayons locaux à retirer en 10D-2–10D-5, pas maintenant : `BorderRadius.circular(10)` dans `sd_entity_card` et plusieurs écrans ; `fontSize: 21` et titre 28 dans `GuestAuthState` ; icône 22 dans `SDWhiteAppBar` ; hauteur 40 de `SDButtonSize.small` ; ombre blur 20 de la barre. Assets PNG d’univers non supprimés.

## Fichiers

Créés :

- `lib/design_system/client_foundations.dart`
- `test/phase10d1_design_foundations_test.dart`
- `docs/audit/PHASE10D1_DESIGN_FOUNDATIONS.md`

Modifiés :

- `lib/design_system/typography.dart`
- `lib/design_system/spacing.dart`
- `lib/design_system/animations.dart`
- `lib/design_system/design_system.dart`
- `docs/audit/PHASE10D_UX_UI_MASTERPLAN.md`

## Tests

- Ajoutés : `test/phase10d1_design_foundations_test.dart` (9 tests).
- Ciblés : `flutter test test/phase10d1_design_foundations_test.dart` → 9/9.
- Suite : `flutter test` → **322/322**.
- Analyse des fichiers modifiés : aucun problème.
- Format : uniquement ces fichiers Dart.

## Hors périmètre confirmé

- Aucune interface métier modifiée.
- Aucune navigation modifiée.
- Backend : NON
- APK/AAB : NON
- `flutter run` : NON
- Commit/push : NON
- Déploiement : NON

## Verdict

`DESIGN_FOUNDATIONS_READY`
