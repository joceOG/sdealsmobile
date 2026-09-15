# Audit technique, sécurité, performance — sdealsmobile

**Périmètre :** `sdealsmobile` uniquement. Backend cité seulement là où l’app l’appelle. Aucun secret recopié.

## Lot 0 — état

- Architecture : Flutter + `flutter_bloc` + `go_router` 7 + `ApiClient` HTTP + `TokenStore` (secure storage) + Hive cache + FCM + Crashlytics + Google Maps + `url_launcher`.
- Stockage : JWT dans `FlutterSecureStorage` (`encryptedSharedPreferences`). Profil `auth_user` en SharedPreferences (`authCubit.dart`).
- Permissions : localisation fine/coarse, Internet, notifications, vibreur, micro. Galerie large **retirée** (`AndroidManifest.xml` L17–34).
- `isMinifyEnabled = false`, `isShrinkResources = false` (`build.gradle.kts` L90–91).
- HTTP cleartext de prod : aucun URL actif. Fallbacks `http://localhost:3000/api` si `API_URL` absent (`websocket_service.dart`, `prestataire_finalization_bloc.dart`). targetSdk 36 sans `usesCleartextTraffic` : cleartext bloqué par défaut.
- Working tree git au moment de l’audit : branche `jordan`, commit `dc5e68d`. Non suivis : `.cursor/`, `docs/` (ce rapport).

## Lot 3 — performance

**Runtime NON MESURÉ** (pas de cold start, jank ni mémoire sur téléphone client).

**Taille artefact mesurée :** `app-release.aab` = **96,7 Mo** (101 367 629 octets), `flutter build appbundle --release` exit 0, tâche Gradle `bundleRelease` ~1055 s. C’est lourd pour un AAB Flutter ; cohérent avec `isMinifyEnabled = false`.

Indices code seulement (pas une note) :

- `fetchPrestataires` (`api_client.dart` L1432) GET sans `page`/`limit`, cache Hive, timeout 25 s.
- 115 appels `print(` dans `api_client.dart` seul (comptage ripgrep).
- Minify off : binaire plus gros, strings plus faciles à extraire. Taille non mesurée.
- Rebuilds / fuites : non instrumentés.

## Lot 4 — qualité

| Contrôle | Résultat |
|---|---|
| `flutter analyze` | exit 1, **2807 issues found** (110 s). Lignes parsées : **2683 info, 0 warning, 0 error**. Écart 124 non reclassé. |
| `flutter test` | **260 passés, 1 échoué** (~28 s de tests après pub get) |
| Test échoué | `test/widget_test.dart` « Counter increments smoke test » — template Flutter, attend un compteur `0` ; `LateInitializationError: appAuthCubit` |
| Tests d’intégration | 0 (`integration_test` absent du pubspec) |
| `dart format --set-exit-if-changed` | non exécuté (analyze + tests déjà faits séquentiellement) |
| AAB | **OK local** — `build/app/outputs/bundle/release/app-release.aab`, 96,7 Mo, non uploadé |
| Dépendances | 136 packages avec versions plus récentes incompatibles avec les contraintes (`flutter pub get`) |

## Lot 5 — sécurité

### Prouvé

1. **Mot de passe dans les logs release** — `serviceProviderRegistrationPageBlocM.dart` L25 `print(formData)` et L40 `print(userData)`. Le formulaire met `password` dans `formData` (`provider_personal_info_step.dart` L164). Route réelle `/serviceProviderRegistration`. `print` n’est pas retiré du release.
2. **Jeton FCM dans les logs** — `notification_service.dart` L21 (préfixe) et L46 (payload avec `fcmToken`), hors `kDebugMode`.
3. **Profil en clair** — SharedPreferences `auth_user` via `toJson` (email, téléphone, champ password). Combiné à l’absence de `android:allowBackup="false"` (défaut Android = sauvegarde activée).
4. **`.env` asset** — `pubspec.yaml` L117–118. Le fichier est gitignoré (prouvé `git check-ignore`) mais **embarqué dans le binaire** s’il est présent au build. Clé Maps aussi injectée dans le manifeste via Gradle (placeholder, pas en dur dans le XML).
5. **Suppression = gel** — app `POST /utilisateur/deactivate` ; backend `utilisateurController.js` L972–987 : `isActive=false`, tokens vidés, **pas** de suppression du document ni des données liées. Message API : « Compte désactivé ».

### Risque probable

- Deep link FCM : `data['route']` passé à `GoRouter.go` sans allowlist (`fcm_service` / `main.dart` L292–296). Les routes sensibles exigent un login.
- URL d’alerte ouverte en externe sans allowlist de domaine (`alertDetailScreenM.dart`).
- Cache Hive non chiffré des listes prestataires.
- Fallback mot de passe `freelance123` dans un événement freelance sans appelant UI trouvé — non déclenché, code compilé.
- Pas de certificate pinning (amélioration, pas un défaut isolé).

### Faux positif / absent

- Pas de WebView.
- Pas de `QUERY_ALL_PACKAGES`, SMS, contacts, caméra, stockage large.
- Pas de JWT en dur dans `lib/`.
- Composant exporté : launcher uniquement (normal).

### Auth (point fort)

`TokenStore` : bundle unique, secure storage, refresh rotatif single-flight. Couvert par `auth_refresh_test.dart` (tests passés).

## Lot 6 — backend (lecture, aucune écriture)

- `GET https://soutralideals-backend.onrender.com/api` → **404 en 2713 ms** (processus répond, pas de handler racine).
- `GET …/api/prestataire` → **200 en 1488 ms** (instance chaude au moment de la sonde). Corps non lu.
- `GET` page confidentialité web → **timeout 40 s** (cold start ou indisponibilité ; non concluant).
- Health check nommé `/health` : **non appelé** dans cet audit.
- Index Mongo, backups, rate limit, cold start p95 : **NON MESURÉS** (pas d’accès Atlas, pas de modification).
- L’app ne hardcode pas l’API de prod dans `lib/` : elle lit `API_URL`. Le `.env` local pointe vers Render HTTPS. Un build sans `API_URL` peut retomber sur localhost (risque de release mal configurée, pas le cas du `.env` actuel).

## Classification

| Finding | Classe |
|---|---|
| Logs mot de passe inscription prestataire | Vulnérabilité prouvée — P0 |
| Pas de delete client + gel seulement | Non-conformité Play prouvée — P0 |
| `.env` en assets | Risque prouvé au prochain build — P0 |
| PII SharedPreferences + allowBackup défaut | Risque probable — P1 |
| Liste prestataires non paginée | Risque perf probable — P1 |
| Pinning, minify | Amélioration — P2 |
