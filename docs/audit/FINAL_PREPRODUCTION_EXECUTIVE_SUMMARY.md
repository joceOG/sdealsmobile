# Résumé exécutif — audit pré-production Soutrali Deals

**Date :** 13 septembre 2026  
**Phase :** 10A — audit uniquement. Aucune correction métier, aucun déploiement, aucune donnée créée.  
**Observation UI device :** STATIC_ONLY (pas de passage visuel sur un téléphone client).

---

## Application principale confirmée

| Champ | Valeur | Preuve |
|---|---|---|
| Dossier | `sdealsmobile/` | `pubspec.yaml` `name: sdealsmobile` |
| Nom affiché | Soutrali Deals | `AndroidManifest.xml` L37 |
| Package | `com.sdealsmobile.app` | `android/app/build.gradle.kts` L46, L62 |
| versionName / versionCode | 1.2.2 / 8 | `pubspec.yaml` L19 `1.2.2+8` |
| Branche / commit | `jordan` / `dc5e68d` | `git rev-parse` |
| Hors périmètre | `SDEALSIDENTIFICATION` ; `sdealsapp` (`com.example.sdealsapp`, 1.0.0+1) | manifests distincts |
| Flutter / Dart | 3.41.4 / 3.11.1 | `flutter --version` |
| compileSdk / targetSdk / minSdk | 36 / 36 / 24 | Gradle L47, L64 ; `FlutterExtension.kt` `minSdkVersion = 24` |
| Signature release | `android/key.properties` présent (contenu non lu) | fichier présent, gitignoré |
| API configurée | hôte Render HTTPS (`soutralideals-backend.onrender.com`) | `.env` local gitignoré, actif |
| Sondes réseau | `GET /api` → 404 en 2713 ms ; `GET /api/prestataire` → 200 en 1488 ms | corps non journalisé |
| Page `/confidentialite` | timeout 40 s | non concluant |
| Track Play | **MANUAL_REQUIRED** | Console non ouverte |

Fiche store référencée in-app : `https://play.google.com/store/apps/details?id=com.sdealsmobile.app` (`about_screen.dart` L27). Statut réel de la fiche : non vérifié.

---

## Notes / 10

| Domaine | Note | Base |
|---|---|---|
| Globale | **6,0** | Cœur « trouver / appeler » viable ; conformité Play et logs secrets bloquent une promo prod du build actuel |
| Produit | 6,0 | Parcours client réel, mais CTA morts et paiement annoncé trop tôt |
| Design | 6,5 | Design system + tests widget 320 dp / textScale ; **pas** de revue visuelle device |
| Performance | **non notée** | Aucune mesure profil/release sur téléphone client |
| Sécurité | 5,5 | JWT en secure storage ; mot de passe loggé ; `.env` asset |
| Stabilité | 7,0 | 260 tests OK, 1 smoke template, analyze 0 error |
| Play | 5,0 | targetSdk 36 OK pour une mise à jour après le 31 août 2026 ; suppression de compte client absente |

---

## Cinq forces

1. Package et version store identifiables (`com.sdealsmobile.app`, 1.2.2+8), label « Soutrali Deals ».
2. Parcours client principal existant : accueil → métiers / carte → fiche → appel `tel:`.
3. Auth : email ou téléphone, Google, OTP conditionnel, refresh token single-flight en secure storage.
4. targetSdk 36, aligné sur l’exigence Play des soumissions à partir du 31 août 2026.
5. Filet de tests (260) et Crashlytics branché ; Photo Picker (permissions galerie retirées du manifeste).

## Cinq problèmes

1. Inscription client sans chemin in-app pour demander la suppression du compte.
2. Le seul « supprimer » (espace prestataire) appelle `POST /utilisateur/deactivate` (gel `isActive=false`), ce que Play ne considère pas comme une suppression.
3. Inscription prestataire : `print` du formulaire entier, mot de passe inclus, y compris en release.
4. Profil promet un portefeuille (`pushNamed('/wallet')` sur `MaterialApp.router`) et l’aide décrit SoutraPay / Mobile Money comme en service.
5. Catalogue prestataires chargé sans `page`/`limit` (`fetchPrestataires`), avec `print` de l’URL et du cache.

---

## P0

| ID | Sujet |
|---|---|
| P0-1 | Pas de suppression de compte sur le profil client |
| P0-2 | L’endpoint existant est un gel, pas une suppression de données |
| P0-3 | `print` du mot de passe sur le parcours d’inscription prestataire |
| P0-4 | `.env` déclaré comme asset Flutter (risque d’embarquer des clés au prochain bundle) |

## P1 retenus (5)

| ID | Sujet |
|---|---|
| P1-1 | Masquer Portefeuille / corriger la FAQ paiement |
| P1-2 | Remplacer les boutons « Contacter » morts (carte, fiche vendeur) par `tel:` ou les retirer |
| P1-3 | Corriger `Navigator.pushNamed` (`/wallet`, `/login`, `/register`) |
| P1-4 | `allowBackup` + profil (email, téléphone) en SharedPreferences clair |
| P1-5 | `GET /prestataire` sans pagination côté client |

---

## Verdict

**GO_AFTER_SMALL_FIXES**

Ne pas demander la production sur le build **1.2.2+8** tel quel. Play exige un chemin de suppression de compte **in-app et web** dès qu’une app permet de créer un compte, et le gel n’est pas accepté ([User Data](https://support.google.com/googleplay/android-developer/answer/10144311), [account deletion](https://support.google.com/googleplay/android-developer/answer/13327111)).

**Estimation :** 3 à 7 jours calendaires (1 développeur) pour les 4 P0 et les 5 P1, sans refonte.

**Recommandation :** petite mise à jour (versionCode 9) en test fermé, puis production. Pas de refonte accueil dans ce créneau.

**Prochaine tâche unique (après validation) :** chemin client « Supprimer mon compte » + URL web Data safety, avec suppression réelle des données associées — pas `isActive=false` seul.

---

## Clôture

* Application principale confirmée : **sdealsmobile / Soutrali Deals**
* Package : **com.sdealsmobile.app**
* Version : **1.2.2 (8)**
* Track Play : **MANUAL_REQUIRED** (test fermé déclaré ; Console non ouverte)
* Écrans inventoriés : **87 fichiers `*Screen*`** ; **15 routes GoRouter** + shell 4 onglets
* Parcours critiques : **15** (voir inventaire)
* Tests : **260 passés / 1 échoué** (`widget_test.dart` template compteur) ; **0 test d’intégration**
* Build AAB : **produit** — `build/app/outputs/bundle/release/app-release.aab`, **96,7 Mo** (`flutter build appbundle --release`, exit 0, Gradle ~17,5 min). Taille élevée (minify off). Pas uploadé sur Play.
* Note produit : **6,0**
* Note design : **6,5** (STATIC_ONLY + tests widget)
* Note performance : **non mesurée**
* Note sécurité : **5,5**
* Note stabilité : **7,0**
* Conformité Play : **5,0 — target API OK ; suppression de compte NO-GO**
* P0 : **4**
* P1 : **5**
* Fonctionnalités à masquer : SoutraPay, assistant IA mort, wallet mock, CTA « à venir »
* Simplifications recommandées : un CTA accueil « Trouver un pro » ; contact = appel
* Améliorations rapides : suppression de compte, arrêter les logs de secrets, FAQ honnête
* Innovations reportées : WhatsApp, chat IA, paiement in-app
* Durée estimée avant production : **3–7 jours après validation**
* Verdict : **GO_AFTER_SMALL_FIXES**
* Prochaine tâche unique : **suppression de compte client + URL web Play**
