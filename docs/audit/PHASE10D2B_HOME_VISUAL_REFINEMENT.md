# PHASE 10D-2B — Finition visuelle Accueil

Verdict : `HOME_NAV_DEVICE_VALIDATION_PENDING`

Ce n’est pas un défaut du code. La session `flutter run` est restée active et recevait encore des événements tactiles, mais l’agent ne peut pas envoyer `R` dans ce terminal. Aucune nouvelle session n’a été lancée, aucune désinstallation, aucun effacement de données.

Phase 10D-3 non commencée.

## État initial observé

La Phase 10D-2 était déjà chargée sur téléphone. Verdict visuel de départ : `HOME_NAV_REFINEMENT_REQUIRED`.

Points fonctionnels déjà validés, non remis en cause : recherche, pas d’É-marché, pas de CTA de connexion, une icône Notifications, deux univers, quatre onglets, « Devenir professionnel » dans Profil, « Mes commandes » une seule fois.

Défauts visuels traités dans le code : ville après les professionnels, cartes trop larges avec un fragment de troisième carte, placeholder et cœur trop dominants, coordonnées GPS brutes, vocabulaire « artisans », introduction haute, feuille encore formulée comme « Publier » avec halo et bleu local.

## Inspection

- Carte partagée `SDListingPreviewCard` : trop haute (photo carrée) et utilisée ailleurs. Non restylée.
- Données réelles utilisées : nom (`personNameFromMap`), métier (`service` / spécialité), prix (`prixprestataire` seulement si > 0), lieu humain, `verifier == true`, photo si URL chargeable.
- `SDListingPreviewCard` ne couvrait pas une carte compacte. Nouvelle carte locale uniquement pour cet accueil.
- Correction locale : accueil, feuille existante `showPublishOptions`, helper de lieu. Pas de nouvel écran, pas de nouveau moteur de recherche, pas de changement de palette.

## Composants réutilisés

- Tokens 10D-1 : `SDTypography` (`screenTitle`, `sectionTitle`, `cardTitle`, `body`, `caption`, `price`), `SDSpacing` (`spaceMinimal`, `spaceRelated`, `screenMargin`, `radiusCard`, `radiusSheet`, `minTouchTarget`, `iconStandard`, `iconInformative`), `SDColors.primary600`, `SDClientLocationPolicy.fallbackCity`, `SDClientTrust.identityVerifiedLabel`.
- `showPublishOptions` et les destinations `openProviderPublishFlow` / `openFreelancePublishFlow` / `openSellerPublishFlow` inchangées.
- Écran de localisation existant `LocationPageScreenM`.
- Recherche existante `SearchPageScreenM`.
- Listes existantes `JobPageScreenM` et `FreelancePageScreen`.

## Fichiers créés

- `lib/mobile/view/homepagem/home_place_label.dart` — détection de coordonnées et largeur de carrousel.
- `lib/mobile/view/homepagem/widgets/home_nearby_card.dart` — carte compacte.
- `test/phase10d2b_home_visual_test.dart`
- ce rapport.

## Fichiers modifiés

- `lib/mobile/view/homepagem/screens/homePageScreenM.dart`
- `lib/mobile/view/common/publish_options.dart`
- `test/phase10d2_home_nav_test.dart` (titre de feuille attendu)

## Helpers supprimés

Uniquement des membres privés de `homePageScreenM.dart`, après vérification qu’ils n’étaient plus appelés :

- `_buildFreelanceServiceOfferItems`, `_buildFreelanceItems`, `_buildProductItems`, `_buildPromoItems`, `_isArticleRealPromo`
- `_openFreelanceServiceOffer`, `_openFreelanceById`, `_openMarketplace`, `_openProductFromHome`
- `_buildUniverseIllustration`, `_buildUniverseCard`, `_buildMiniSection`, `_buildPreviewCard`, `_homeUniverseCard`
- `_formatPrice`, `_ratingWithReviews`, `_prestataireLocationLabel`, `_distanceLabel`, `_extractArticleData`, `_hasDisplayableImage`, `_onlyItemsWithImages`, `_toInt`
- listes `_freelanceServiceItems`, `_freelanceItems`, `_productItems`, `_promoItems`
- imports devenus inutiles (fiches freelance, boutique, `ApiException`)

Aucun écran, modèle, BLoC partagé ni route supprimé.

## Requêtes

- Conservée au chargement de l’accueil : `fetchPrestataires` (page 1, limit 20).
- Retirées du chargement : `fetchFreelances`, `fetchHomeFreelanceServices`, `fetchArticle`.
- Aucune permission GPS au premier rendu. `Geolocator` n’est pas appelé par l’accueil. L’écran de localisation existant reste l’action explicite « Modifier ».

## Comportement avant / après

| Avant | Après |
| --- | --- |
| Ville après les professionnels, libellé « Choisir la ville » | Ville juste avant « Professionnels près de vous », action « Modifier », cible 48 dp |
| Cartes larges, fragment de troisième carte | Une carte + aperçu de 40 dp. Largeur = écran − marges − aperçu − intervalle |
| GPS brut affiché | Ligne masquée si la chaîne ressemble à des coordonnées |
| `Voir tous les artisans` | `Voir tous les professionnels` |
| Promesse haute | Mêmes textes, interlignes et marges resserrés via tokens 10D-1. Titre resté à 22 |
| Feuille « Que souhaitez-vous publier ? », halo, bleu Freelance | « Comment souhaitez-vous proposer vos services ? », vert unique, rayon 16, feuille 24 |

La ville affichée est Abidjan (`SDClientLocationPolicy.fallbackCity`) tant qu’aucune ville persistée n’existe. Aucune coordonnée n’est utilisée comme nom de ville.

Le favori a une cible 48 dp et une icône 20. L’accueil n’invente pas un état « déjà favori » : le libellé par défaut est « Ajouter aux favoris ». Le widget accepte `favoriteSelected` pour « Retirer des favoris ».

## Tests ciblés

`flutter test test/phase10d1_design_foundations_test.dart test/phase10d2_home_nav_test.dart test/phase10d2b_home_visual_test.dart` → **28/28**.

Couverture 10D-2B : ville avant les professionnels, fallback Abidjan, Modifier ouvre `LocationPageScreenM`, aucun appel du canal Geolocator au premier rendu, « Voir tous les professionnels » visible, « Voir tous les artisans » absent, coordonnées non affichées, lieu humain affiché, ligne absente si inexploitable, « Identité vérifiée » seulement si `verifier`, pas de prix ni d’avis inventés, pas d’overflow à 320/360/393 et text scale 1.3, aperçu régulier 32–48 dp, feuille sans Boutique et sans `info600`, destinations Métiers/Freelance conservées, quatre onglets, pas de CTA connexion, logout vers Accueil, pas de requête Freelance/Article au chargement.

## Suite complète

`flutter test` → **341/341**.

## Analyse

Fichiers touchés : aucune erreur, aucun warning nouveau.

Infos préexistantes, non introduites par cette phase, dans la bannière d’erreur de l’accueil : `prefer_const_constructors` lignes 787 et 796.

## Contrôle responsive

Testé en widget test, pas sur l’appareil :

- 320, 360 et 393 dp
- text scale 1.0 et 1.3
- nom, métier, lieu, prix : 1 ligne, ellipsis
- dernière carte atteignable sans overflow
- fragment visible = 40 dp (entre 32 et 48)

## Contrôle accessibilité

Vérifié dans le widget tree, pas sur l’appareil :

- cibles ville, recherche, univers, feuille et favori ≥ 48 dp
- Notifications : tooltip existant « Notifications »
- recherche : sémantique « Quel service recherchez-vous ? »
- ville : sémantique « Ville Abidjan. Modifier »
- favori : « Ajouter aux favoris »
- univers : titre et description dans le label
- feuille lisible dans l’ordre titre, sous-titre, Métiers, Freelance, Fermer
- texte important non porté seulement par la couleur : libellés présents
- `neutral600` `#525252` et `neutral700` sur blanc restent au-dessus du seuil de texte courant
- aucune nouvelle animation. Reduce Motion non instrumenté sur appareil. La feuille n’ajoute pas de rebond.

TalkBack sur appareil : **non exécuté**.

## Résultat appareil

Session `flutter run` toujours active. Hot restart `R` non injectable depuis cet agent. Appareil non observé après ces modifications.

`DEVICE_VALIDATION_PENDING` est une limite d’observation, pas un blocage de code.

## Anomalies restantes

- Validation visuelle téléphone encore à faire après hot restart.
- Overflow horizontal préexistant de 17 px dans `jobPageScreenM.dart` (liste Métiers), hors périmètre 10D-2B, non corrigé.
- L’état « déjà en favoris » n’est pas relu depuis le serveur sur l’accueil.

## Clôture

- code backend modifié : NON
- APK/AAB : NON
- commit/push : NON
- déploiement : NON
