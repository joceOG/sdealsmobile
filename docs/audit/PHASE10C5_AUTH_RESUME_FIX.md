# PHASE 10C-5 — Reprise après authentification et reset du shell

Verdict : `AUTH_RESUME_HAS_BLOCKERS`

## Causes racines

1. **Intention perdue après une fiche impérative.** La fiche est ouverte par `Navigator.push`, pas par une route GoRouter. Dans go_router 7.1.1, `router.location` reste alors sur `/homepage` même si `/login` ou `/register` est au-dessus. `goAfterSuccess` ne reconnaissait pas la page d’auth, **effaçait l’intention**, puis appelait `go('/homepage')`. Cela détruisait la fiche et le `push` ne rendait jamais `true`. Login, inscription et redirect regardaient la même condition.

2. **Index du shell non réinitialisé.** Logout vidait bien la session et appelait `context.go('/homepage')` alors que le shell était déjà sur `/homepage`. `Home._currentIndex` restait sur Profil. Le mur invité du Profil s’affichait à la place de l’accueil.

3. **Blocage appareil restant.** Après correction 1, le smoke B ouvre bien le sélecteur Android une fois. Au retour, l’app est sur l’accueil connecté, pas sur la fiche. Le redirect `loggedIn && /login → /homepage` s’exécute encore après consommation de l’intention (`refreshRoles` / refresh GoRouter). Il remplace la pile pendant que le composeur est ouvert. Cette course n’a pas été élargie après l’échec du smoke, conformément à la consigne.

## Fichiers modifiés

- `lib/mobile/view/common/auth_completion.dart`
- `lib/main.dart`
- `lib/mobile/view/home.dart`
- `lib/mobile/view/profilpagem/screens/profilPageScreenM.dart`
- `lib/mobile/view/registerpagem/screens/registerPageScreenM.dart`
- `test/phase10c5_auth_resume_test.dart`
- `docs/audit/PHASE10C5_AUTH_RESUME_FIX.md`

Non modifiés : helper téléphone, masquage É-marché, recherche, backend.

## Méthode de reprise retenue

Décision unique `decideAuthExit` :

- intention en attente → `Navigator.pop(true)` vers l’appelant, sans consommer, sans `go('/homepage')` ;
- pas d’intention → onglet Accueil puis `/homepage` ;
- destination FCM allowlistée seulement s’il n’y a pas d’intention.

L’appelant consomme l’intention une seule fois, puis exécute l’action (composeur ou sheet existante). Annulation : pop sans `true`, intention effacée, aucune action.

Inscription : même règle. `PopScope` autorise le pop seulement au succès, pour que le retour à l’appelant ne soit pas bloqué.

## Login / inscription

- Direct, sans intention : accueil, onglet Accueil, aucune action.
- Protégé : pas de `go('/homepage')` dans `goAfterSuccess` ; retour à l’appelant ; action une fois.
- Annulé : aucune action, intention effacée.

## Intentions

Non consommée avant le succès. Consommée une fois après `pop(true)`. Deuxième `consume()` vide. Effacée à l’annulation et au logout (`SessionExit.clearPending`).

## Index du shell

`ClientShellSelection` branché sur le `Home` existant. Logout : session et jetons vidés, intention effacée, index 0, pile privée ramenée à la route racine si elle est au-dessus, `go('/homepage')` seulement si la location n’est pas déjà l’accueil. Pas de timestamp, délai, double navigation ni nouveau shell.

## Tests

- Ciblés `test/phase10c5_auth_resume_test.dart` : 12/12.
- `flutter test` complet : 304/304.
- Format des fichiers modifiés : fait.
- Inscription protégée : uniquement par tests. Aucun nouveau compte réel.

## Appareil

Session debug relancée (`flutter run`, hot restart VM impossible). Compte de test existant réutilisé. Aucun nouveau compte.

| Parcours | Résultat |
| --- | --- |
| A. Déconnexion | Passé. Accueil invité tout de suite, « Bonjour, Invité », Métiers et Freelance, aucun CTA connexion, aucune donnée personnelle. |
| B. Appel puis connexion | Bloqué. Feuille puis login du compte existant. Sélecteur Android ouvert une fois. Retour Android : accueil connecté, pas la fiche. |
| C. Demande puis connexion | Non exécuté après l’échec B. |
| D. Inscription | Validée par tests uniquement. Aucun compte réel créé. |

## Interdits respectés

- APK : NON
- AAB : NON
- commit : NON
- push : NON
- backend : NON
- déploiement : NON

## PHASE 10C-6 — GoRouter race fix

Verdict : `AUTH_RESUME_DEVICE_BLOCKED`

### Cause

Après le pop de succès, l’appelant consomme `ProtectedActionStore`. Le refresh AuthCubit / `refreshRoles` relance le redirect. Login et register restent dans la pile, mais `router.location` est `/homepage` tant que la fiche a été ouverte par `Navigator.push`. Sans autre marqueur, `loggedIn + /login|/register` renvoyait `/homepage` et remplaçait la fiche pendant l’ouverture du sélecteur.

### Marqueur retenu

`AuthEntryMode.protectedAction`, en mémoire, passé dans `GoRouterState.extra` uniquement. Aucun téléphone, email, jeton, mot de passe, contenu de formulaire ni objet métier. Le login direct (Profil, onboarding) n’envoie pas ce marqueur. Il disparaît quand la route `/login` ou `/register` quitte la pile. Pas de timer, délai, microtask, timestamp ni drapeau global.

### Propagation Login / Register

- feuille d’auth → `/login` et `/register` avec `extra: AuthEntryMode.protectedAction` ;
- Login → Inscription : le même extra est conservé ; si l’inscription réussit, un `Navigator.pop(true)` post-frame rend le succès à l’appelant ;
- Inscription → Login, si ce passage existe : `_goLoginKeepingEntry` recopie l’extra ;
- OTP : étape interne de `/register`, pas une autre route ; l’extra reste.

### Modification du redirect

`shouldRedirectAuthedAuthRouteToHome` reçoit `state.extra`. Si l’extra est `protectedAction`, le redirect retourne `null`, même si le store est déjà vide, même pendant un refresh AuthCubit ou `refreshRoles`. Login/register directs, sans ce marqueur, redirigent toujours vers `/homepage` si l’utilisateur est déjà connecté.

Au succès protégé : pas de `go('/homepage')`. `Navigator.pop(true)`. L’appelant consomme une fois, puis lance Appeler ou Demander. Annulation : pas de succès, intention effacée, fiche conservée.

### Fichiers modifiés

- `lib/mobile/view/common/auth_completion.dart`
- `lib/main.dart`
- `lib/mobile/view/loginpagem/screens/loginPageScreenM.dart`
- `lib/mobile/view/registerpagem/screens/registerPageScreenM.dart`
- `test/phase10c5_auth_resume_test.dart`
- `test/phase10c6_gorouter_race_test.dart`
- `docs/audit/PHASE10C5_AUTH_RESUME_FIX.md`

Non modifiés : PhoneDialer, É-marché, logout validé, recherche, backend.

### Tests

- Ciblés `phase10c6_gorouter_race_test.dart` + `phase10c5_auth_resume_test.dart` : 20/20.
- Redirect : login direct → accueil ; login et register protégés → aucun redirect ; intention déjà consommée → aucun redirect ; refresh AuthCubit et `refreshRoles` → aucun redirect ; route retirée → login direct redevient l’accueil.
- Propagation : feuille → Login, feuille → Inscription, Login → Inscription ; auth directe sans marqueur ; annulation sans action.
- `flutter test` complet : 312/312.
- Format des fichiers modifiés : fait.
- Inscription : tests seulement. Aucun nouveau compte réel.

### Appareil

Hot restart impossible : l’extension `ext.flutter.hotRestart` n’est pas enregistrée sur cette session. `flutter attach` non utilisé. Session debug relancée avec `flutter run`. Compte de test existant. Aucun nouveau compte.

| Parcours | Résultat |
| --- | --- |
| B. Appel | Non conclu. Déconnexion OK (accueil invité). Fiche invité OK. Appeler ouvre la feuille, puis login. Le formulaire est rempli. Le bouton « Se connecter » (`SDButton`, `GestureDetector` parent) ne réagit pas aux taps injectés. Le sélecteur n’a pas été observé. Aucune navigation vers l’accueil observée, parce que le login n’a pas abouti. |
| C. Demande | Non exécuté. |

### Interdits

- aucune PII dans le marqueur
- APK : NON
- AAB : NON
- commit : NON
- push : NON
- backend : NON
- déploiement : NON
