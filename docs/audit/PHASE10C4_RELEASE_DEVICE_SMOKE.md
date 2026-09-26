# PHASE 10C-4 — Build release et smoke client

Aucune installation. Le téléphone restait sur `flutter run`. La comparaison de certificats interdit aussi la mise à jour.

Aucun code modifié dans cette phase. Aucun commit, push, déploiement Render ou upload Play. Aucun secret recopié.

## 1. Préalable

| Élément | Constat |
| --- | --- |
| Branche | `jordan` |
| Commit de référence | `1c4bf71` |
| Flutter | 3.41.4 stable |
| Dart | 3.11.1 |
| Appareil | connecté, `flutter run` toujours actif |
| Package | `com.sdealsmobile.app` installé |
| Version installée | `1.2.3` / versionCode `9` |
| Type installé | `DEBUGGABLE` |

Les fichiers Phase 10C-3 sont présents, y compris `phone_dialer.dart`, `auth_completion.dart`, `fcm_route_policy.dart`, `client_feature_flags.dart` et les tests `phase10c3_*`.

`git status --short` : modifications locales 10C-3 non commitées, plus `pubspec.yaml` et `lib/main.dart` (dotenv déjà présent). Aucun fichier de code touché pendant 10C-4.

## 2. Tests et analyse

- `flutter pub get` : OK
- `flutter test` : 288 passés, exit 0
- Analyse des fichiers 10C-3 : aucune ligne `error`. Exit 2 à cause de warnings.
- Nouveaux warnings 10C-3 : imports inutilisés ou dupliqués (chat, freelance, popup, vendeur, splash). Non corrigés : interdiction de changer le code.
- Warnings préexistants dans ces fichiers : déclarations non référencées déjà présentes (chat, SoutraPay profil, conditions null toujours vraies). Les infos de style ne bloquent pas.

## 3. Artefacts neufs

Les APK et AAB précédents ont été supprimés avant reconstruction. Ils n’ont pas été réutilisés.

```powershell
flutter build apk --release --dart-define=API_URL=https://soutralideals-backend.onrender.com/api
flutter build appbundle --release --dart-define=API_URL=https://soutralideals-backend.onrender.com/api
```

| Artefact | Taille | SHA-256 |
| --- | --- | --- |
| `build/app/outputs/flutter-apk/app-release.apk` | 122 727 918 octets (117,0 Mo) | `E9A96E8F866865DB5A3D2A2DBA988AB3CBEBF622DA44548275146DB9ED45E3D2` |
| `build/app/outputs/bundle/release/app-release.aab` | 101 361 333 octets (96,7 Mo) | `E7A574A00E7569266CF88D1D1FA352E7624C4837CB7DF6E197DBF9FA405E1C01` |

Manifeste fusionné release :

- package `com.sdealsmobile.app`
- versionName `1.2.3`
- versionCode `9`
- schémas `tel:` pour `ACTION_DIAL` et `ACTION_VIEW`
- `CALL_PHONE` absent
- `.env` absent des assets de l’APK
- aucune `NotInitializedError` dans le journal de build
- API passée en `--dart-define` HTTPS, pas en valeur de `.env`

Le certificat du nouvel APK n’est pas celui de l’application debug installée. Le détail du certificat n’est pas recopié.

## 4. Signature et installation

Résultat : `SIGNATURE_MISMATCH`

L’application installée est le build debug en cours de `flutter run`. Le nouvel APK release a un autre certificat.

Installation : non effectuée. Aucune désinstallation. Aucun `adb install`. Aucun effacement de données. Les données de l’application debug sont inchangées.

Pour installer cette release plus tard, il faut une décision explicite : désinstaller le debug, utiliser un package QA, ou signer avec la même clé que l’application déjà installée.

## 5. Smoke

Tous les scénarios release sont `NOT_RUN`. Le téléphone n’exécute pas cet APK.

| ID | Résultat |
| --- | --- |
| A Accueil invité | `NOT_RUN` |
| B Appel invité annulé | `NOT_RUN` |
| C Appel après connexion | `NOT_RUN` |
| D Appel déjà connecté | `NOT_RUN` |
| E Demande de service | `NOT_RUN` |
| F Déconnexion | `NOT_RUN` |
| G Réseau | `NOT_RUN` |
| H É-marché | `NOT_RUN` |
| I Recherche | `NOT_RUN` |
| J FCM | `MANUAL_REQUIRED` |

Aucune anomalie appareil, parce qu’aucun parcours release n’a été joué. Le smoke FCM réel n’est pas un PASS.

## Verdict

`INSTALL_BLOCKED_BY_SIGNATURE`

- code modifié : NON
- backend modifié : NON
- déploiement : NON
- upload Play : NON
- installation : NON
