# PHASE 10D-2C — Direction artistique Accueil et Profil

Observation téléphone : en attente. La session `flutter run` était déjà ouverte. Aucune seconde session n’a été lancée. Sidney peut appuyer sur `R` pour le hot restart.

Les tests verts ne suffisent pas à déclarer le design fidèle. La comparaison ci-dessous est faite par rapport à la maquette, pas sur une capture téléphone.

## Fichiers et composants

Créé :

- `lib/mobile/view/common/widgets/client_universe_pictograms.dart`

Modifiés :

- `lib/mobile/view/homepagem/screens/homePageScreenM.dart`
- `lib/mobile/view/homepagem/widgets/home_nearby_card.dart`
- `lib/mobile/view/home.dart` (barre uniquement)
- `lib/mobile/view/profilpagem/screens/profilPageScreenM.dart`
- `lib/mobile/view/profilpagem/screens/profile_menu_item.dart` (paramètres optionnels, défauts inchangés)
- tests `phase10d2`, `phase10d2b`, `phase10c4`

Non touchés : prestataires, GoRouter, auth, PhoneDialer, FCM, backend, palette de marque, `pubspec.yaml`.

## Pictogrammes

`flutter_svg` n’est pas une dépendance. Deux `CustomPainter` partagés, sans nouvelle dépendance et sans découpe de la maquette.

- Métiers : clé et tournevis croisés, contour `primary800`, remplissages `primary500` / `primary100`.
- Freelance : ordinateur de face, écran `primary50`, base `primary500`, même contour.
- 46 dp sur l’accueil, 30 dp dans « Devenir professionnel ».
- `ExcludeSemantics` : le titre n’est pas lu deux fois.

## Changements visuels

Accueil :

- surface `primary50`, coins bas arrondis, salutation, notifications, promesse et recherche regroupées ;
- recherche blanche, sans bordure grise ;
- univers verts pâles, chevron, pictogrammes ;
- ville compacte, sans carte encadrée ;
- carte proche : photo circulaire ou initiale, prix avec séparateurs, lieu et badge vérifié avec icône.

Profil :

- identité compacte sur `primary50`, initiale ou photo réelle, « Modifier le profil » ;
- Activité et Compte dans des groupes blancs ;
- entrée professionnelle en carte verte, même pictogramme Métiers ;
- déconnexion rouge, hors du groupe, sans bandeau plein.

Barre :

- fond blanc, séparation haute légère, capsule `primary50` derrière l’icône active ;
- quatre onglets inchangés, pas de bouton Publier.

## Comportements préservés

Destinations Métiers, Freelance, recherche, localisation, commandes, favoris, avis, historique, notifications, paramètres, aide, à propos, sheet professionnelle, logout et reset vers Accueil.

Profil invité : « Se connecter » et « Créer un compte » restent. É-marché et Wallet restent absents. Pas de CTA connexion sur l’accueil.

## Limites connues

- Le prix d’accueil est `12 500 FCFA`, sans `/h`. `prixprestataire` est un tarif journalier à l’inscription, pas une unité horaire garantie. Le `/h` de la maquette n’a pas été recopié.
- Badge « Identité vérifiée » seulement si `verifier == true`. Point rouge de notification seulement si le compteur réel est positif.
- Pas d’avatars illustrés. Photo absente : initiale de la marque.
- L’état favori n’est pas relu depuis un cache local. Aucun stockage parallèle n’a été ajouté. Le cœur reste « Ajouter aux favoris » tant que la synchro n’existe pas.
- L’e-mail n’est plus dans l’en-tête. Il reste accessible dans l’édition du profil.
- Une entrée « Espace Métiers » reste visible si le rôle prestataire existe. Elle n’est pas dans la maquette et n’a pas été retirée.
- Les icônes de la barre restent Material. Seuls Métiers et Freelance ont un dessin dédié.
- Les pictogrammes sont une reconstruction vectorielle, pas une copie pixel de l’image générée.
- Overflow horizontal préexistant d’environ 17 px dans la liste Métiers, hors de cette phase.

## Tests et analyse

- Ciblés 10D-1, 10D-2, 10D-2B et accueil invité 10C-4 : passés après adaptation du test qui exigeait un `AppBar` (la salutation et Notifications sont maintenant dans la surface verte).
- `flutter test` : **341/341**.
- Analyse des fichiers touchés : aucune erreur nouvelle.
- Warnings préexistants non traités : `home.dart` comparaison nulle, méthodes SoutraPay inutilisées du Profil, `use_build_context_synchronously` au logout, infos `prefer_const` de la bannière d’erreur.
- Import `characters` ajouté puis retiré de la carte proche pour ne pas créer un avertissement de dépendance.

## Observation téléphone

Non effectuée par l’agent. Validation en attente d’un hot restart `R` et des captures de Sidney.

## Clôture

- APK/AAB : NON
- commit / push : NON
- backend : NON
- déploiement : NON

Explorer et la liste Métiers ne sont pas commencés.
