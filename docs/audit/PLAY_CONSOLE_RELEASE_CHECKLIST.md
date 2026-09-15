# Checklist Google Play — avant production

**Console : non ouverte.** Tout ce qui n’a pas de preuve dans le dépôt ou une doc officielle est **MANUAL_REQUIRED**. Rien n’est inventé.

Sources officielles consultées le 13 septembre 2026 :

- [Target API level](https://support.google.com/googleplay/android-developer/answer/11926878) — à partir du 31 août 2026, une **mise à jour** doit cibler API 36. Le projet est en `targetSdk = 36`.
- [User Data / account deletion](https://support.google.com/googleplay/android-developer/answer/10144311)
- [Account deletion help](https://support.google.com/googleplay/android-developer/answer/13327111)

## Identité (prouvé dans le code)

| Contrôle | Statut | Preuve |
|---|---|---|
| Package | OK code | `com.sdealsmobile.app` |
| versionName / versionCode | OK code | 1.2.2 / 8 |
| targetSdk 36 | OK code | conforme pour une soumission après le 31 août 2026 |
| minSdk 24 | OK code | défaut Flutter 3.41 |
| Label | OK | Soutrali Deals |
| Keystore release local | PRÉSENT | `key.properties` gitignoré, contenu non lu |
| Play App Signing / SHA | MANUAL_REQUIRED | Console |
| AAB produit pour ce versionCode | **LOCAL OK, non uploadé** | `build/app/outputs/bundle/release/app-release.aab`, 96,7 Mo, `flutter build appbundle --release` exit 0 |
| Signature debug en fallback | Risque si `key.properties` absent | `build.gradle.kts` L84–88. Aujourd’hui le fichier est présent |

## Politique données

| Contrôle | Statut | Preuve |
|---|---|---|
| Création de compte in-app | OUI | `/register` |
| Suppression in-app **client**, visible | **NON** | rien sous `profilpagem/` |
| Suppression web (URL Data safety) | **NON PROUVÉE** | pas de route `delete-account` trouvée dans le dépôt web ; page confidentialité timeout |
| Gel ≠ suppression | **ÉCHEC** | `POST /utilisateur/deactivate` + `isActive=false` |
| Politique de confidentialité URL | PARTIEL | `LegalUrls.confidentialite` → site Render `/confidentialite` ; page non chargée (timeout) |
| Formulaire Sécurité des données | MANUAL_REQUIRED | |
| Permissions déclarées = usage | OK manifeste | loc, notif, micro. Galerie large retirée |
| Compte / données de testeurs | MANUAL_REQUIRED | |

## Fiche et qualité

| Contrôle | Statut |
|---|---|
| Track actuel (test fermé, 20 testeurs, 17 jours) | MANUAL_REQUIRED — déclaré par le produit, non lu en Console |
| Éligibilité production | MANUAL_REQUIRED |
| Captures, classification, coordonnées support | MANUAL_REQUIRED |
| Publicités / IAP | Aucun billing Play vu dans `pubspec` (pas de `in_app_purchase`). SoutraPay non branché. À confirmer en Console |
| Rapport pré-lancement, Vitals, ANR, crashs | MANUAL_REQUIRED |
| Retours testeurs Play | MANUAL_REQUIRED — aucun ticket dans le dépôt |
| Validation développeur / nom package réel vs Console | MANUAL_REQUIRED |

## Avant de cliquer « production »

1. versionCode **> 8** sur un **App Bundle** signé (pas debug, pas profile).
2. Chemin client de suppression **et** URL web saisie dans Data safety.
3. Vérifier que la politique décrit la rétention (ce qui est gardé après demande, et pourquoi).
4. Relire la FAQ in-app pour qu’elle ne promette pas un paiement absent.
5. Ouvrir Play Console : track, Vitals, pre-launch, formulaire données — cocher ici les lignes MANUAL_REQUIRED.
