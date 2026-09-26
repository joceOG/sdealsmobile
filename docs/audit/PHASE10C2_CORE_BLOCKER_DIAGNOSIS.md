# PHASE 10C-2 — Diagnostic des bloquants du parcours client

Application : `com.sdealsmobile.app` / dossier `sdealsmobile` / branche `jordan` / commit de référence `1c4bf7158a03d78f3b71619fbe189caf1c91a15c` / version projet `1.2.3+9`.

Source : `docs/audit/PHASE10C_CLIENT_SCREEN_INVENTORY.md`, section `PHASE 10C-1 — Device validation`.

Aucun code Flutter modifié. Aucun secret, numéro, email ou jeton recopié.

Le smoke 10C-1 a été fait avec `flutter run` debug. `lib/main.dart` et `pubspec.yaml` sont modifiés localement et non commités. Ce debug n’est pas l’AAB.

## Diagnostic A — Bouton Appeler

Fiche observée : `ProviderProfileScreen`, boutons « Appeler » et « Demander un service ».

| Étape | Preuve |
| --- | --- |
| Widget | `ElevatedButton.icon`, `onPressed: _onContactProvider`, `provider_profile_screen.dart` ligne 1139 |
| Callback | `_onContactProvider`, lignes 1322-1340 |
| Source du numéro | `_provider?.utilisateur.telephone` |
| Modèle | `Utilisateur.telephone`, `utilisateur.dart` lignes 10 et 59 (`cleanDisplayPart`) ; fiche via `Prestataire.fromJson`, `prestataire.dart` lignes 90-104 |
| Normalisation avant `tel:` | aucune dans ce callback. Concaténation directe |
| URI | `tel:` + valeur du champ, ligne 1331. Valeur non affichée ici |
| `canLaunchUrl` / `launchUrl` | lignes 1332-1333. `LaunchMode` non passé : mode plateforme par défaut |
| Exception | non attrapée. Si `canLaunchUrl` est faux, snackbar, pas de `launchUrl` |
| Condition du message observé | uniquement le `else` de `canLaunchUrl` faux, ligne 1337 |

Le message « Numéro de téléphone non disponible » (lignes 1324-1328) n’a pas été vu. Le champ n’était donc pas `null` ni vide au moment du toucher. Le CTA n’est pas masqué quand le numéro est vide : il affiche un autre texte.

Cause racine prouvée : le composeur n’est pas ouvert parce que `canLaunchUrl` retourne faux, alors que le numéro est présent.

Cause plateforme prouvée : `android/app/src/main/AndroidManifest.xml` lignes 82-87 ne déclare que `ACTION_PROCESS_TEXT`. Aucune requête `ACTION_DIAL`, `ACTION_VIEW` ni schéma `tel`. Sur Android 11+ (appareil observé : Android 16), sans cette visibilité, `canLaunchUrl` pour `tel:` retourne faux même si un composeur est installé. Le manifeste debug et release est le même fichier. Ce n’est pas un écart debug/release.

Cause secondaire non exclue, non observée caractère par caractère : la chaîne n’est pas normalisée (espaces, indicatif). Une URI invalide produirait le même snackbar. La correction minimale doit couvrir les deux.

Autres appels, même verrou `canLaunchUrl` :

| Site | Lignes | Message si échec |
| --- | --- | --- |
| `detailPageScreenM.dart` `_contactProvider` | 805-813 | pas ce snackbar : bascule vers une autre navigation si `id` présent |
| `provider_popup.dart` `_contact` | 117-136 | « Impossible d’ouvrir l’appel. » |
| `freelance_details_screen.dart` `_makePhoneCall` | 801-808 | silence si `canLaunchUrl` faux |
| `vendorDetailsScreenM.dart` | 657-658 | à traiter dans le même helper |
| `mini_map_widget.dart` | 272-273 | mode externe déjà passé |

Correction minimale : un helper unique qui normalise le numéro sans l’afficher, construit `Uri(scheme: 'tel', path: ...)`, appelle `launchUrl` en `LaunchMode.externalApplication`, et n’utilise plus `canLaunchUrl` comme barrière unique. Ajouter dans le manifeste les intents `tel` / `ACTION_DIAL` / `ACTION_VIEW`. Si le champ est vide, masquer le CTA ou garder le message « non disponible », pas le message « impossible ».

Tests : test unitaire du normaliseur avec des numéros fictifs (`0700000000`, `+2250700000000`, espaces). Test widget : champ vide → autre message ; champ non vide → tentative de lancement. Smoke Android : invité, fiche, Appeler, composeur prérempli, aucun appel, Retour vers la même fiche.

## Diagnostic B — Bannière « Pas de connexion »

La bannière n’est pas branchée sur le Wi-Fi Android ni sur le compteur de notifications.

| Maillon | Preuve |
| --- | --- |
| Affichage | `homePageScreenM.dart` lignes 734, 808, 1190-1219. Si `state.error` contient « connexion », « réseau » ou « network », le texte devient « Pas de connexion. Vérifiez votre réseau. » et l’icône est `wifi_off` |
| Source de l’erreur | `HomePageBlocM._onLoadCategorieDataM`, `homePageBlocM.dart` lignes 15-36, uniquement `apiClient.fetchCategorie('Métiers')` |
| Mapping | `network_user_message.dart` lignes 2-13 : `timeout`, `timed out`, `socket`, `connection`, `failed host` deviennent tous « Pas de connexion… » |
| Appel | `GET $apiUrl/categorie`, timeout 15 s, `api_client.dart` lignes 481-483 |
| Cache | `CacheService`, clé `categories_<groupe>`, lignes 441-474. Si le cache est vide ou rejeté, l’échec API devient l’erreur visible |
| Réessayer | relance seulement `LoadCategorieDataM`, `homePageScreenM.dart` ligne 1219. Succès remet `error: ''` |
| Compteur notifications | `getUserUnreadNotificationCount`, timeout 5 s, `api_client.dart` lignes 2834-2844 et log ligne 2875. Appelé par le bloc notifications et le dashboard prestataire, pas par `HomePageBlocM` |

Un timeout de `/categorie` ou un cold start Render est donc affiché comme une absence de réseau. Le timeout du compteur non lu ne met pas l’accueil hors ligne. Les deux échecs peuvent coexister au démarrage connecté, mais ils ne sont pas liés.

4xx/5xx de `/categorie` ne passent pas par le message « pas de connexion », sauf si le texte d’exception contient les mots ci-dessus. 502/503/504 ont un message serveur distinct, puis la bannière d’accueil ne le raccourcit pas, sauf s’il contient aussi « connexion ».

Correction minimale : ne mapper `timeout` / `socket` vers « pas de connexion » que si une sonde réseau locale est fausse. Sinon : « Service momentanément indisponible ». Ne jamais faire dépendre cette bannière du compteur de notifications. Conserver les catégories déjà en cache et ne pas les effacer sur timeout.

## Diagnostic C — Demande de service et login

| Maillon | Preuve |
| --- | --- |
| CTA | `ElevatedButton` « Demander un service », `provider_profile_screen.dart` lignes 1166-1172 |
| Garde | `_onRequestService`, lignes 1343-1349. Invité : snackbar « Veuillez vous connecter pour demander un devis. » puis `context.push('/login')` |
| Formulaire avant login | non. `showServiceRequestSheet` n’est appelé qu’après `AuthAuthenticated`, lignes 1353-1368 |
| Pile avant login | `push`, pas `go`. Le Retour Android ramène à la fiche. Conforme à l’observation |
| Après succès | `_finishLogin`, `loginPageScreenM.dart` lignes 123-142 : `pop` si possible, puis `router.go('/homepage')` |
| Redirect | `main.dart` lignes 154-156 : si déjà authentifié sur `/login` ou `/register`, retour `/homepage` |
| `returnTo` / action en attente / `extra` | absents sur ce `push('/login')` |
| Brouillon | aucun. Le sheet n’est pas ouvert, donc rien à conserver |

Le retour après login réussi n’a pas été joué sur appareil. Le code le décide déjà : la pile est remplacée par l’accueil. La fiche et la demande ne sont pas rouvertes.

### Solution 1 — login puis retour, recommandée pour le correctif minimal

Bénéfice : la fiche et le sheet existant `service_request_sheet.dart` sont réutilisés, sans nouvel écran. L’invité comprend qu’il doit se connecter.  
Complexité : faible. Passer l’identifiant de fiche en `extra` ou mémoriser une action `openServiceRequest` consommée une fois après `Authenticated`.  
Risque : si `go('/homepage')` reste inconditionnel, le correctif est annulé. Il faut supprimer ou conditionner la ligne 142.  
Données : `prestataireId`, `serviceId`, noms déjà lus par `_openRequestQuoteSheet`. Pas de brouillon.  
Tests : invité, demande, login, sheet de la même fiche ; Retour avant login reste sur la fiche ; pas de double écran.

### Solution 2 — brouillon puis login à l’envoi

Bénéfice : l’invité commence la demande tout de suite.  
Complexité : plus haute. Le sheet existe, mais il exige déjà `token` et `utilisateurId`. Il faudrait un mode invité, un brouillon hors session, puis l’envoi après login.  
Risque : fuite du brouillon si la session change ; perte du brouillon si `go('/homepage')` n’est pas corrigé.  
Données : champs du sheet, identité de la fiche, à tenir hors `SharedPreferences` profil.  
Tests : saisie, rotation, login, envoi, brouillon d’un autre prestataire non mélangé.

Le correctif suivant doit faire la solution 1. La solution 2 est un choix produit ultérieur, pas un nouvel écran.

## Diagnostic D — Déconnexion

| Maillon | Preuve |
| --- | --- |
| Bouton | `MenuItem` « Se déconnecter », `profilPageScreenM.dart` ligne 243, `_showLogoutDialog` |
| Dialogue | lignes 397-429. Textes identiques à l’observation |
| Session | `AuthCubit.logout`, `authCubit.dart` lignes 266-284 : unregister FCM, `POST /logout`, clear `auth_token`, `auth_user`, `auth_roles`, `auth_active_role`, `TokenStore`, puis `AuthInitial` |
| Navigation | `context.go('/login')`, `profilPageScreenM.dart` ligne 419 |
| Redirect | n’envoie vers `/homepage` que si l’état est encore `AuthAuthenticated`. Après logout, l’état est `AuthInitial`, donc le login reste racine |
| Splash | non impliqué. Le splash n’est rejoué qu’au prochain lancement à froid. Relance observée : accueil invité, onboarding déjà fait |

`go` remplace la pile. Le Retour Android depuis `/login` n’a plus d’accueil dessous, donc il ferme l’application. L’accueil invité existe (`/homepage`, libellé « Invité »).

Correction minimale : après logout réussi, `context.go('/homepage')`, jamais `go('/login')` comme racine. Ne pas laisser de jeton ni de profil en mémoire : le clear actuel doit rester avant la navigation. Vérifier qu’aucune frame précédente n’affiche encore le nom. Le bouton de connexion existe déjà sur le mur invité du profil et du chat.

## Diagnostic E — É-marché

Deux faits distincts.

Liste vide, cause données, pas une panne mal étiquetée :

- `fetchArticle()` vide ou sans liste exploitable aboutit à `error: 'Aucun produit disponible'`, `shoppingPageBlocM.dart` lignes 171-190.
- L’erreur réseau est un autre texte : « Impossible de charger le catalogue », lignes 174-181.
- La section aperçu affiche « Aucun produit pour le moment. » si la liste convertie est vide, `shoppingPageScreenM.dart` lignes 555-559.
- Les erreurs de mapping d’un article sont avalées une par une, lignes 158-160, sans vider seules tout le catalogue si d’autres articles passent.
- Pas de cache produits dans ce chemin, contrairement aux catégories accueil.
- Le libellé observé correspond à la branche catalogue vide, pas à la branche timeout.

Navigation catégorie, volontaire dans le code, incorrecte pour le geste observé :

- Tuile : `SearchProductsEvent(cat.nomcategorie)` puis `_openSearchShop`, `shoppingPageScreenM.dart` lignes 475-479.
- `_openSearchShop` pousse `SearchPageScreenM(initialIndex: 4)` sans `initialQuery`, lignes 199-204.
- L’index 4 est l’onglet Shop, `searchPageScreenM.dart` lignes 182-186 et 449-454.
- L’événement ne filtre que le `ShoppingPageBlocM` laissé derrière. Le nouvel écran a son propre `SearchPageBlocM` et n’a pas reçu le nom de catégorie.
- Résultat : recherche globale, requêtes récentes visibles, filtre catégorie perdu. Conforme au toucher Mode observé. Ce n’est pas un mauvais tap isolé.

Décision production : option 2. Tant qu’aucun article publié n’est renvoyé, la tuile Accueil et l’entrée Publier doivent dire « Bientôt disponible » et ne pas promettre un contact vendeur. L’écran É-marché peut rester joignable pour contrôle, avec l’état vide explicite, pas un catalogue inventé. L’option 1 laisse un trou sans explication. L’option 3 masquerait aussi une offre réelle dès qu’un article existera. Dans tous les cas, le correctif catégorie est séparé : passer `initialQuery` égal au nom de catégorie, ou ouvrir une liste filtrée de `ShoppingPageScreenM` sans basculer vers la recherche globale vide.

## Diagnostic F — Notification

Aucune notification générée.

| Point | Code |
| --- | --- |
| Foreground | `onMessage` affiche une notification locale, `fcm_service.dart` lignes 99 et 149-170 |
| Ouverture | `onMessageOpenedApp` → `_handleMessageNavigation`, lignes 100 et 173-179 |
| Terminated | `getInitialMessage`, lignes 102-105, puis `SplashscreenBlocM` consomme `consumePendingLaunchRoute`, `splashscreenBlocM.dart` lignes 33-36 |
| Background isolate | `firebaseMessagingBackgroundHandler` ne fait qu’initialiser Firebase et loguer en debug, lignes 13-19. Pas de destination stockée |
| Payload | `route` explicite, sinon `conversationId` → `/chat/:id`, `missionId` → `/mission-details/:id`, type contenant `MESSAGE` ou autre → `/homepage`, lignes 232-247 |
| Allowlist | absente. Toute chaîne `route` est passée à `mobileRouter.go`, `main.dart` lignes 333-336 |
| Session expirée | le redirect ne protège que `/wallet`, `/providermain`, `/prestataire-finalization`, `/mission-details`, `/chat`. Une route chat non authentifiée va vers `/login`, puis le login réussi fait `go('/homepage')` et perd la destination |
| Route inconnue | pas de `errorBuilder` dans `main.dart` |
| Sans destination | retombe sur `/homepage` |
| Onboarding | le deep link est prioritaire sur l’onboarding si non vide et différent de `/`, `splashscreenBlocM.dart` lignes 59-72 |

Conclusion : `STATIC_BLOCKER_FOUND`. Un smoke FCM reste obligatoire plus tard. Bloquants statiques : route explicite non filtrée, destination perdue après login, handler background sans navigation.

## Diagnostic G — Build

| Élément | Constat |
| --- | --- |
| Commit | `jordan` à `1c4bf7158a03d78f3b71619fbe189caf1c91a15c` |
| Local non commité | `lib/main.dart`, `pubspec.yaml` |
| Version | `pubspec.yaml` ligne 19 : `1.2.3+9` |
| Debug | `kReleaseMode` faux : `dotenv.testLoad`, puis URL publique Render si `API_URL` absent ou placeholder, `main.dart` lignes 95-104. Pas de `.env` secret en asset |
| Release | `API_URL` obligatoire en `--dart-define` HTTPS, sinon `StateError`, lignes 86-93 |
| Debug testé | oui, c’est ce `flutter run`, donc il inclut les deux fichiers locaux. Non identique au commit de référence |
| AAB | non reconstruit ici. Un AAB produit avant le correctif dotenv local ne contient pas ce `main.dart`. Après les correctifs 10C, un nouvel AAB sera obligatoire |
| Vérification future | `flutter build appbundle --release --dart-define=API_URL=https://<hôte>/api` ; contrôler package `com.sdealsmobile.app`, `versionCode` 9, URL HTTPS, signature. Ne pas imprimer de clé |

## Classification

| ID | Cause racine | Preuve fichier:ligne | Gravité | Correction minimale | Tests requis | Décision |
| --- | --- | --- | --- | --- | --- | --- |
| A | `canLaunchUrl` faux ; manifeste sans visibilité `tel` | `provider_profile_screen.dart:1332-1337` ; `AndroidManifest.xml:82-87` | `P0_RELEASE_BLOCKER` | helper d’appel + queries `tel` | unitaire normaliseur, widget CTA, smoke composeur | corriger ensuite |
| B | timeout `/categorie` mappé comme hors ligne | `network_user_message.dart:2-13` ; `homePageScreenM.dart:1192-1196` ; `homePageBlocM.dart:31-34` | `P1_BEFORE_PRODUCTION` | message « service indisponible » si le réseau local est là ; garder le cache | test du mapping timeout versus hors ligne | corriger ensuite |
| C | login succès `go('/homepage')` sans action en attente | `loginPageScreenM.dart:139-142` ; `provider_profile_screen.dart:1345-1349` | `P0_RELEASE_BLOCKER` | solution 1 : extra ou action, rouvrir le sheet existant | login depuis fiche, Retour, pas de double pile | corriger ensuite |
| D | `go('/login')` remplace la pile | `profilPageScreenM.dart:417-419` | `P1_BEFORE_PRODUCTION` | `go('/homepage')` après clear session | logout, accueil invité, Retour quitte l’app, pas de nom résiduel | corriger ensuite |
| E1 | catalogue articles vide | `shoppingPageBlocM.dart:185-190` | `BLOCKED_BY_DATA` | tuile « Bientôt disponible » tant que la liste est vide | fixture liste vide et liste d’un article | décision produit retenue |
| E2 | catégorie pousse la recherche sans `initialQuery` | `shoppingPageScreenM.dart:475-479` et `199-204` | `P1_BEFORE_PRODUCTION` | passer le nom de catégorie, ou rester dans la liste boutique | tap Mode ne montre pas les recherches récentes seules | corriger ensuite |
| F | route FCM non filtrée ; login écrase la destination | `fcm_service.dart:232-247` ; `main.dart:333-336` | `P1_BEFORE_PRODUCTION` | allowlist ; conserver la route jusqu’après auth | smoke FCM plus tard, pas dans cette phase | `STATIC_BLOCKER_FOUND` |
| G | debug local ≠ commit ≠ AAB | `main.dart` et `pubspec.yaml` non commités | `P1_BEFORE_PRODUCTION` | reconstruire l’AAB après correctifs, avec dart-define HTTPS | contrôle package, versionCode, signature | ne pas reconstruire maintenant |

## Verdict

`READY_FOR_TARGETED_FIXES`

Fichiers à toucher ensuite, pas maintenant : `android/app/src/main/AndroidManifest.xml`, un helper d’appel partagé, `provider_profile_screen.dart`, les autres sites `tel:`, `network_user_message.dart`, `homePageScreenM.dart`, `loginPageScreenM.dart`, `profilPageScreenM.dart`, `shoppingPageScreenM.dart`, `fcm_service.dart`. Sheet existant à réutiliser : `service_request_sheet.dart`.

- aucun secret exposé
- code modifié : NON
- backend modifié : NON
- build effectué : NON
- déploiement effectué : NON

## Arrêt

Diagnostic seulement. Aucune correction, aucune refonte, aucun déploiement.
