# PHASE 10D-2 — Accueil et navigation client

**Date :** 2026-09-16  
**Application :** `sdealsmobile`  
**Tokens 10D-1 :** utilisés pour la promesse, les cartes, la recherche, la barre et les marges.

## Structure

Avant : « Bonjour, Invité 👋 », Notifications + Commandes, « Explorer les univers », PNG Métiers/Freelance, carrousels freelance et métiers, barre à 5 zones avec `+` Publier.

Après :

1. `Bonjour` (invité) ou `Bonjour, Prénom` si un prénom humain existe.
2. Une icône Notifications, 24 dp, cible 48 dp, label TalkBack.
3. Promesse : « Trouvez un professionnel près de vous » / « Comparez les services et contactez le bon profil. »
4. Recherche : « Quel service recherchez-vous ? » ouvre `SearchPageScreenM`. Aucun second moteur.
5. Deux cartes verticales, rayon 16, sans PNG : Métiers « Artisans et services près de vous » ; Freelance « Compétences à distance ou au projet ».
6. « Professionnels près de vous » : source `fetchPrestataires` existante. Photo ou fallback. Vérification seulement si `verifier == true`, libellé « Identité vérifiée ». Pas de prix ni de note inventés. Vide : « Aucun professionnel à afficher » + « Ouvrir Explorer », pas une erreur réseau.
7. Ville : Abidjan affiché. Aucune demande GPS au démarrage. « Choisir la ville » ouvre l’écran localisation existant, seul moment où la permission peut partir.

Disposition retenue : cartes verticales. À 320 dp et text scale 1.3, deux colonnes coupent les sous-titres. Les tests 320, 360 et 393, scale 1.0 et 1.3, n’ont pas d’overflow.

Éléments AppBar retirés : Commandes, emoji, CTA connexion. Aucun espace réservé.

## Navigation

Avant : Accueil, Explorer, Publier (sans index), Messagerie 2, Profil 3. La liste de pages était déjà à 4.

Après : Accueil 0, Explorer 1, Messagerie 2, Profil 3. Plus de bouton central, plus de libellé Publier, plus d’ombre propre au `+`. Vert seulement sur l’onglet actif. Insets `systemBottomInset` conservés. Logout : `ClientShellSelection.showHome()` remet l’index 0. Test : après Messagerie, retour accueil, puis Profil affiche le mur invité.

## Publier

`_showPublishOptions` extrait dans `showPublishOptions` (`lib/mobile/view/common/publish_options.dart`). Profil appelle cette fonction. Une seule sheet. Boutique seulement si `ClientFeatureFlags.emarketEnabled` (false). Welcome screens et auth protégée inchangés. `originRoute` reste `home`.

Profil connecté : une entrée « Devenir professionnel », section Professionnel, pas dans Activité, pas à côté de la déconnexion. Suppression de compte absente de cet écran (elle reste dans les paramètres). Mur invité inchangé : pas cette entrée.

## Commandes

« Mes commandes » existait déjà dans Profil et ouvre `ServiceRequestsListScreen` (demandes de service, pas un catalogue É-marché). Conservée une seule fois. Icône d’accueil retirée. Aucune seconde entrée. Wallet non exposé dans ce menu.

## Performance

Plus d’appel `fetchFreelances`, `fetchHomeFreelanceServices` ni `fetchArticle` au chargement de l’accueil : ces listes ne sont plus affichées. `fetchPrestataires` (limite 20) reste. Pas de nouvelle requête. Des builders freelance et PNG restent dans le fichier, non appelés. GPS non appelé dans `build()`.

## Fichiers

Créés :

- `lib/mobile/view/common/publish_options.dart`
- `test/phase10d2_home_nav_test.dart`
- `docs/audit/PHASE10D2_HOME_NAVIGATION.md`

Modifiés :

- `lib/mobile/view/homepagem/screens/homePageScreenM.dart`
- `lib/mobile/view/home.dart`
- `lib/mobile/view/profilpagem/screens/profilPageScreenM.dart`
- `lib/mobile/view/profilpagem/screens/profile_menu_item.dart`
- `test/phase10c4_guest_home_cta_test.dart`
- `test/stab10_entrypoints_honesty_test.dart` (la phrase « arrive bientôt » a suivi l’extraction)

## Tests

- Responsive : 320, 360, 393 dp ; text scale 1.0 et 1.3 ; pas d’exception d’overflow. Métiers et Freelance entiers. Aucun `Image` PNG d’univers au premier rendu.
- Ciblés : `phase10d2` + `phase10c4` passés, puis suite complète.
- Suite : `flutter test` → **329/329**.
- Analyse : warnings sur des helpers d’accueil non appelés (freelance, PNG, listes). Infos préexistantes (nom de fichier, `withOpacity`). Pas d’erreur de compilation.
- Régressions 10C couvertes par la suite : pas de CTA auth accueil, logout vers accueil, sheet protégée, recherche existante. PhoneDialer, GoRouter et fiche non modifiés.

## Téléphone

Session `flutter run` toujours active. Les derniers logs montrent encore `Récupération des freelances`. Hot restart non injectable depuis cet agent. Nouvelle interface non observée sur l’appareil. Aucune capture ajoutée au dépôt.

## Hors périmètre

- Backend : NON
- APK/AAB : NON
- Commit/push : NON
- Déploiement : NON
- Explorer, liste Métiers, fiche : NON, sauf l’index de barre et l’ouverture de la recherche existante.

## Verdict

`HOME_NAV_HAS_BLOCKERS`

Le code et les tests sont en place. Le blocage est l’absence de contrôle téléphone après hot restart : l’appareil affiche encore l’accueil précédent. Pas de défaut fonctionnel démontré par les tests.
