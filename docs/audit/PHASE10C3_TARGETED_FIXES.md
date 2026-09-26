# PHASE 10C-3 — Corrections ciblées des parcours client

Application : `com.sdealsmobile.app` / branche `jordan` / version `1.2.3+9`.

Aucun secret affiché. Backend non modifié. Aucun déploiement Render. Aucun envoi Play Console. Aucun commit. Aucun push.

Les changements dotenv déjà présents dans `lib/main.dart` et `pubspec.yaml` ont été conservés. `.env` n’est pas un asset Flutter.

## Corrections

### Composeur

Cause : `canLaunchUrl` faux, sans visibilité Android du schéma `tel:`.

Correction :

- `<queries>` `ACTION_DIAL` et `ACTION_VIEW` pour `tel:` dans `AndroidManifest.xml`.
- Aucune permission `CALL_PHONE`.
- Helper `PhoneDialer` : normalisation sans `+225` automatique, URI `tel:`, mode externe, résultat typé, exception non avalée, numéro non journalisé.
- Les CTA client Appeler / Contacter passent par l’authentification puis ce helper.
- L’invité voit « Connectez-vous pour contacter ce professionnel », puis connexion ou inscription.
- Après succès, retour sur la fiche et ouverture unique du composeur, jamais de l’appel.

### Intention après login

`ProtectedActionStore` distingue un login direct d’un login pour `callProvider`, `requestService`, `startConversation`, `addFavorite`, `contactSeller` ou `publish`.

L’URL ne contient ni numéro, ni email, ni jeton, ni formulaire. Seuls le type, un identifiant technique et une origine autorisée sont conservés.

Si une intention existe, le login ou l’inscription revient à l’appelant au lieu de `go('/homepage')`. L’intention est consommée une fois, y compris au logout. L’annulation ne lance ni appel ni sheet et n’affiche pas d’erreur technique.

La demande réutilise `service_request_sheet.dart` après authentification, sur la même fiche. Le formulaire avant login n’est pas encore ouvert.

### Déconnexion

Après confirmation, la session et les jetons sont effacés, les intentions aussi, puis navigation vers `/homepage` invité. La pile authentifiée est remplacée. L’accueil affiche « Se connecter ».

### Réseau

Un timeout n’est plus annoncé comme une absence de Wi-Fi.

| Situation | Message |
| --- | --- |
| Connectivité absente | « Vous êtes hors connexion. Vérifiez votre réseau. » |
| Timeout | « Le service met plus de temps à répondre. Réessayez. » |
| 5xx | « Service momentanément indisponible. Réessayez dans un instant. » |
| 401/403 | pas de bannière hors connexion |
| Compteur de notifications | indépendant, n’abaisse pas l’accueil |

Le bouton Réessayer reste. Les catégories déjà en cache ne sont pas effacées.

### É-marché

Flag unique : `ClientFeatureFlags.emarketEnabled = false`.

Masqué : tuile accueil, section produits, puce Explorer « Vente & Achat », option Boutique de Publier, onglets et suggestions Shop/Boutiques.

Routes, écrans, modèles, blocs et panier conservés. Réactivation : passer le flag à `true`. Aucune mention SoutraPay ajoutée.

### FCM

`FcmRoutePolicy` n’accepte plus une route arbitraire. Allowlist : `/homepage`, `/chat/{id}`, `/mission-details/{id}`. Destination protégée et invité : login puis reprise en mémoire. Route inconnue ou payload vide : accueil. Onboarding non terminé : onboarding, puis destination conservée. Effacée au logout. Aucun jeton dans SharedPreferences.

## Fichiers créés

- `lib/data/config/client_feature_flags.dart`
- `lib/data/utils/phone_dialer.dart`
- `lib/data/services/protected_action_intent.dart`
- `lib/data/services/fcm_route_policy.dart`
- `lib/mobile/view/common/auth_completion.dart`
- `test/phase10c3_phone_dialer_test.dart`
- `test/phase10c3_client_fixes_test.dart`
- `test/phase10c3_auth_sheet_test.dart`

## Fichiers modifiés

`AndroidManifest.xml`, `authCubit.dart`, `fcm_service.dart`, `network_user_message.dart`, `main.dart`, chat, explorer, freelance, `home.dart`, accueil, fiches métier et prestataire, popup, login, register, onboarding, profil, recherche, vendeur, splash.

`pubspec.yaml` et l’initialisation dotenv de `main.dart` n’ont pas été réécrites.

## Tests et analyse

- Tests ciblés 10C-3 : 17 passés.
- Suite Flutter : 288 passés.
- Analyse des fichiers touchés : aucune erreur de compilation. Le dépôt conserve des infos et warnings préexistants.
- Le helper ne journalise que le statut, jamais le numéro.

## Build et smoke

L’AAB et l’APK release ont été produits avant l’instruction de laisser les builds à l’utilisateur. Ils ne doivent pas être réutilisés comme livrable tant que l’utilisateur n’a pas reconstruit lui-même.

Manifeste fusionné vérifié sur ce passage : package `com.sdealsmobile.app`, `versionName` `1.2.3`, `versionCode` `9`, requêtes `tel`, pas de `CALL_PHONE`. `key.properties` est présent. `jarsigner -verify -strict` reconnaît le jar, puis échoue (code 4) : certificat auto-signé, chaîne PKIX absente, pas d’horodatage. C’est le comportement habituel d’un keystore local, pas une preuve Play App Signing. Aucun détail de certificat n’est recopié. La signature reste à contrôler de votre côté.

Installation appareil : non effectuée. Aucune désinstallation, aucun vidage de données. Les scénarios authentifiés restent `BLOCKED` faute d’identifiant de test. Le smoke FCM reste `MANUAL_REQUIRED`.

## Verdict

`TARGETED_FIXES_READY_FOR_DEVICE_SMOKE`

- aucun secret exposé
- backend modifié : NON
- déploiement effectué : NON
- upload Play : NON
- nouvel install ou nouvel APK demandé : NON
