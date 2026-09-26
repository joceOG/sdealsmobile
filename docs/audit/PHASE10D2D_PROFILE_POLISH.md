# PHASE 10D-2D — Finition visuelle Profil client

Verdict : `PROFILE_MINOR_POLISH_DEVICE_PENDING`

Aucun terminal `flutter run` actif dans la session Cursor observée. Demander à Sidney d’appuyer sur `R` si une session tourne déjà, sans ouvrir une seconde session concurrente.

Accueil, Explorer, Messagerie et Phase 10D-3 non touchés.

## Sections détectées

Profil connecté :

| Section | Contenu | Surface |
| --- | --- | --- |
| Titre page | Profil | texte seul |
| Identité | photo/initiale, nom, Modifier le profil | vert pâle (`primary50`) |
| Activité | Mes commandes, Favoris, Avis et évaluations, Historique, Notifications | groupe gris (`neutral100`) |
| Mes espaces | Espace Métiers (si rôle PRESTATAIRE) | groupe gris |
| Professionnel | Devenir professionnel | vert pâle |
| Compte | Paramètres, Localisation, Aide et support, À propos | groupe gris |
| Déconnexion | Se déconnecter + dialogue | action indépendante rouge |

Profil invité : mur `GuestAuthState` (Se connecter / Créer un compte), inchangé.

Paramètres (écran séparé) conserve la suppression de compte. Non modifié dans cette phase.

## Composant commun

`_profileGroup` dans `profilPageScreenM.dart` : surface unique `SDColors.neutral100` (`#F5F5F5`, proche de `#F6F6F6`), rayon 16 (`radiusCard`), séparateurs `neutral200`, clip anti-alias. Utilisé pour Activité, Compte et Mes espaces, pas seulement pour deux noms hardcodés.

Exceptions sans gris : identité, Devenir professionnel, titres de section, barre inférieure (hors écran), dialogues / sheets, déconnexion, mur invité.

## Fichiers modifiés

- `lib/mobile/view/profilpagem/screens/profilPageScreenM.dart`
- `lib/mobile/view/profilpagem/screens/profile_menu_item.dart` (`titleFontWeight` optionnel, défaut `w500`)

Aucun fichier Accueil, aucune nouvelle dépendance, aucun backend.

## Ajustements « Devenir professionnel »

- titre en `FontWeight.w600` ;
- sous-titre inchangé ;
- fond `primary50` conservé ;
- pictogramme Métiers réutilisé (`ClientUniversePictogram.metiers`), taille 32 dp ;
- centre aligné avec l’ensemble titre + sous-titre (`CrossAxisAlignment.center`) ;
- carte entière toujours tactile ; sheet et destinations inchangées ;
- aucun cercle, halo ou second bouton.

## Tests réellement exécutés

- format des fichiers Profil ;
- analyse des fichiers touchés : aucune erreur nouvelle ;
  - préexistants : méthodes SoutraPay inutilisées, `use_build_context_synchronously` au logout ;
- `flutter test test/phase10d2_home_nav_test.dart test/phase10c4_guest_home_cta_test.dart` → **11/11**.

Aucun test ajouté uniquement pour une valeur de couleur.

## Contrôle téléphone

Non observé par l’agent. Validation visuelle en attente de hot restart.

## Différences visuelles restantes possibles

- Le gris `neutral100` est `#F5F5F5` et non exactement `#F6F6F6` : token design system existant, pas de couleur hardcodée.
- « Mes espaces » reste visible pour un prestataire : entrée réelle, hors maquette Accueil/Profil, non retirée.
- Les pictogrammes restent une reconstruction vectorielle, pas une copie pixel de la maquette.

## Clôture

- APK/AAB : NON
- commit / push : NON
- backend : NON
- déploiement : NON
