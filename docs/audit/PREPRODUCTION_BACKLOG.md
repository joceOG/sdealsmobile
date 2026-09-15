# Backlog pré-production

**Règle :** P0 complets + 5 P1 max. Pas de refonte XL. Aucune de ces lignes n’est commencée.

## P0 — bloque la demande de production

| ID | Quoi | Pourquoi | Preuve | Taille |
|---|---|---|---|---|
| P0-1 | Bouton « Supprimer mon compte » dans le profil **client**, visible sans passer par l’espace pro | Play exige un chemin in-app dès qu’on peut créer un compte | `profilpagem/` sans `DeleteAccount` ; [policy](https://support.google.com/googleplay/android-developer/answer/13327111) | S |
| P0-2 | Page web (lien Data safety) pour demander la même suppression sans réinstaller l’app | Deuxième obligation Play | URL absente du code ; page légale non vérifiée (timeout) | S |
| P0-3 | Remplacer le gel par une vraie suppression des données de compte (ou un process documenté + exécuté). `isActive=false` ne suffit pas | Policy : freezing is not deletion | `provider_profile_bloc.dart` L360 ; `utilisateurController.js` L972–987 | M |
| P0-4 | Retirer les `print` qui dumpent `formData` / `userData` / réponses d’inscription (mot de passe, token) | Logcat release | `serviceProviderRegistrationPageBlocM.dart` L25, L40, L55 | S |
| P0-5 | Ne plus déclarer `.env` comme asset. Injecter `API_URL` / clé Maps via `--dart-define` et Gradle secrets seulement | Un bundle bâti sur ce poste embarque le fichier | `pubspec.yaml` L117–118 | S |

P0-1 et P0-2 sont le même sujet produit ; P0-3 est le contrat serveur. Les traiter ensemble.

## P1 — les 5 à faire dans la même mise à jour si le temps tient

| ID | Quoi | Preuve |
|---|---|---|
| P1-1 | Retirer Portefeuille et tarifs du menu Profil. Corriger l’aide qui présente Mobile Money / SoutraPay comme disponibles | `profilPageScreenM.dart` L192–199 ; `help_support_screen.dart` L40 ; wallet L7–49 |
| P1-2 | Popup carte « Contacter » et fiche vendeur : lancer `tel:` si un numéro existe, sinon retirer le bouton | `provider_popup.dart` L197–200 ; `vendorDetailsScreenM.dart` ~L647 |
| P1-3 | Remplacer `Navigator.pushNamed('/wallet'|'/login'|'/register')` par `context.push` / `context.go` | `profilPageScreenM.dart` L194 ; `productDetailsScreenM.dart` L570–580 |
| P1-4 | `android:allowBackup="false"` (ou règles d’exclusion) et ne plus écrire email/téléphone/password dans SharedPreferences | manifeste sans `allowBackup` ; `authCubit.dart` persistance profil |
| P1-5 | Passer `page` et `limit` sur `GET /prestataire` et paginer la liste | `api_client.dart` `fetchPrestataires` L1432–1456 |

## Hors de cette mise à jour

WhatsApp, refonte accueil, minify, pinning, assistant IA, paiement SoutraPay : P2/P3. Voir `POST_LAUNCH_IDEAS.md`.

## Cinq scénarios à refaire en test fermé après correctifs

1. Créer un compte client → trouver le bouton supprimer → confirmer → ne plus pouvoir se reconnecter.
2. Ouvrir l’URL web de suppression sans l’app installée (parcours Data safety).
3. S’inscrire comme prestataire et vérifier qu’aucun mot de passe n’apparaît dans logcat.
4. Ouvrir Profil : plus de portefeuille promis ; Aide ne parle plus d’un paiement actif.
5. Ouvrir une fiche sur la carte et une fiche vendeur : Appeler marche, ou le bouton n’est pas là.

## Estimation

3 à 7 jours calendaires, 1 développeur, après validation de cette liste. Pas de publication Play dans ce lot.
