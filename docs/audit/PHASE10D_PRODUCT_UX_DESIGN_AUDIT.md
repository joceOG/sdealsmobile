# Phase 10D — Audit expert produit, UX, design et fluidité

**Date :** 2026-09-15  
**App :** `sdealsmobile` / `com.sdealsmobile.app`  
**Mode d’observation :** **STATIC_ONLY** (aucun téléphone / ADB utilisable dans cette session)  
**Couleur de marque :** VALIDÉE — aucune nouvelle palette proposée  
**Périmètre :** client uniquement ; aucun code modifié ; pas de deploy / upload Play  

---

## LOT 0 — État exact de la version auditée

| Élément | Valeur |
|---|---|
| Dossier | `C:\Users\DELL\CascadeProjects\soutralideals\sdealsmobile` |
| Package | `com.sdealsmobile.app` |
| Version code/nom (repo) | **1.2.3+9** (`pubspec.yaml`) |
| Branche / commit audités | `jordan` @ **`1c4bf71`** |
| Distant | `origin/jordan` à jour |
| Git non suivi (préservé) | `.cursor/`, `docs/audit/_analyze_10b*.txt` |
| AAB local | `build/app/outputs/bundle/release/app-release.aab` (~85 Mo, 14/09/2026) |
| Device / ADB | **Non disponible** → pas d’observation visuelle live |

### Distinctions obligatoires

| Couche | Statut |
|---|---|
| Version en **test fermé** Play | Déclarée par le produit (Phase 10C) — **non vérifiée Console** dans cet audit |
| Candidate locale **1.2.3+9** | Code + AAB présents @ `1c4bf71` |
| Écrans observés sur téléphone | **Aucun** |
| Conclusions code-only | Tout ce document sauf mentions device |

**Aucune note de qualité visuelle** n’est attribuée à un écran non observé.

---

## QUESTION CENTRALE (réponse)

**Oui, techniquement** un invité peut trouver un professionnel (Métiers / Explorer) et l’appeler via `tel:` **sans compte**.  
**Non, immédiatement** : l’accueil impose d’abord de choisir entre **Métiers / Freelance / É-marché**, avec **Publier** et **Messagerie** dans la barre principale — vocabulaire et structure « plateforme 2023 » avant le geste « trouver un pro près de moi ».

Verdict global : **CORE_JOURNEY_NEEDS_SIMPLIFICATION**  
(Impossible `DESIGN_AND_UX_READY` en `STATIC_ONLY`.)

---

## LOT 1 — Premières secondes (parcours code + 3 profils)

### Chaîne d’entrée (code)

1. Splash → onboarding (4 pages) si `onboarding_completed == false` → `/homepage`
2. Accueil : « Bonjour, Invité » + « Explorer les univers » (3 cartes)
3. Bottom nav : Accueil | Explorer | **Publier** | Messagerie | Profil

### Onboarding — promesse vs réalité (code)

| Slide | Promesse | Risque |
|---|---|---|
| Cartographie temps réel | Carte métiers existe | « Intelligente / temps réel » non prouvé device |
| 300+ métiers | Catalogue pro | Chiffre marketing ; non validé ici |
| Achat + livraison Abidjan | É-marché consultable | Livraison / paiement in-app **non** (FAQ 10B honnête) |
| Un compte, tous les rôles | Vrai modèle multi-rôle | Charge cognitive **avant** le besoin client |

### Trois profils « trouver & contacter » (estimation gestes, STATIC)

| Profil | Parcours probable | Gestes min. jusqu’à `tel:` | Impasses code |
|---|---|---|---|
| A — Plombier Abidjan | Accueil → Métiers → (filtre/liste ou carte) → fiche → Contacter | **4–7** | Sans GPS : liste large ; sans tel : snackbar ; Render lent : skeleton long |
| B — Designer / logo | Accueil → Freelance **ou** Métiers (ambigu) → fiche → Contacter | **5–8** | Confusion Métiers vs Freelance ; empty « bientôt » possible |
| C — Acheter téléphone | Accueil → É-marché → fiche produit → Contacter vendeur | **4–6** | Chip **SoutraPay** encore visible → `/wallet` placeholder ; contact vendeur dépend du numéro |

**Invité sans compte :** vue + appel OK ; favoris / messagerie / publier / devis / commander → auth.

---

## LOT 2 — Revue visuelle (limites STATIC_ONLY)

### Ce qui peut être affirmé depuis le code (pas une note esthétique)

| Sujet | Observation code | À conserver / risque |
|---|---|---|
| Typographie | Inter 400/600/700 + legacy `rif`/`raf` | Inter = base pro ; dualité legacy = dette |
| Couleurs | Primary vert `#1CBF3F` / `#1AA12A`, secondary orange | **Marque validée — ne pas changer** |
| DS | `SDButton`, `SDAppBar`, `SDEmptyState` | Partis pris à conserver |
| Accueil | Fond `neutral50`, app bar blanche, emoji 👋 | Emoji = touche « template » (jugement designer, pas MD3) |
| Nav bas | 5 destinations + FAB Publier, hauteur 78 + SafeArea | Aligné effort insets Huawei (STAB-13) |
| SoutraPay chip | Gradient warning + shadow dans É-marché | Effet décoratif + promesse morte |
| Empty Explorer | sections → `SizedBox.shrink()` | Silence = impasse |

### Convention Android officielle (source)

[Edge-to-edge Android Developers](https://developer.android.com/develop/ui/views/layout/edge-to-edge) (maj. 2026-09-08) : sur API 35+, edge-to-edge forcé ; **gérer les insets** pour barres système / gestes.  
→ L’app a déjà du travail SafeArea/nav (preuve code `home.dart`) : **à vérifier sur device**, pas à « moderniser » par décoration.

### Direction de finition (sans nouvelle palette)

1. **Typographie** : une seule famille d’UI (Inter) ; hiérarchie Accueil = 1 question + 1 CTA primaire.  
2. **Espacements** : rythme `SDSpacing` déjà présent — éviter densifier Accueil (previews métiers + freelance + produits).  
3. **Iconographie** : Material Icons cohérents ; retirer chips « premium » (SoutraPay).  
4. **Images** : exiger image réelle sur cards métiers (déjà `requireImage: true` sur une section) — étendre la règle.  
5. **Motion** : onboarding 340 ms easeOutCubic OK ; pas d’animations gratuites.  
6. **Confiance** : badge vérifié seulement si statut serveur vrai (idée post-lancement).

---

## LOT 3 — Matrice fonctionnalités client

| Fonction | Catégorie | Preuve / note |
|---|---|---|
| Découverte Métiers + appel `tel:` | **CONSERVER** | Cœur produit ; invité OK |
| Explorer (recherche + chips + carte) | **SIMPLIFIER** | Doublon partiel avec Accueil Métiers |
| Carte métiers | **CONSERVER** | Différenciant local ; mesurer perf device |
| Favoris | **CONSERVER** | Auth OK ; vérifier ouverture fiche réelle |
| Connexion / inscription | **CONSERVER** | Nécessaire pour le reste |
| Suppression de compte | **CONSERVER** | Conformité Play (10B) |
| Aide / FAQ | **CONSERVER** | Paiements honnêtes post-10B |
| Profil / paramètres | **SIMPLIFIER** | Menu long ; prioriser compte + aide |
| Freelance (consultation) | **TESTER PLUS TARD** / **SIMPLIFIER** entrée | Valeur réelle inconnue sans analytics ; label peu clair CI |
| É-marché (consultation) | **TESTER PLUS TARD** / **SIMPLIFIER** | Même ; contact vendeur OK si tel |
| Publier (FAB centre) | **MASQUER** ou **SIMPLIFIER** pour client | Distrait le client ; utile partenaires |
| Messagerie | **MASQUER** pour invité déjà ; **TESTER PLUS TARD** poids nav | Auth wall ; appel suffit souvent V1 |
| Chip / route SoutraPay–Wallet | **MASQUER** | Placeholder encore joignable É-marché |
| Prestataires similaires « Bientôt » | **MASQUER** | Fonction fictive sur fiche |
| Page Plus / Soutra News | **RETIRER APRÈS LANCEMENT** | Hors nav live |
| Onboarding 4 slides multi-rôles | **SIMPLIFIER** | Trop de plateforme avant usage |

---

## LOT 4 — Performance

**NOT_MEASURED**

Aucun appareil profile/release dans cette session.  
Ne pas conclure « bonne/mauvaise perf » depuis la taille AAB (85 Mo) seule.

**Hypothèses code à vérifier ensuite (pas des verdicts) :**  
pagination métiers (10B) ; cold start Render ; images réseau ; Google Maps ; `isMinifyEnabled` (post-launch).

---

## LOT 5 — Retours testeurs

**TESTER_FEEDBACK_NOT_AVAILABLE**  
(Play Console / tickets absents du dépôt — checklist 10A `MANUAL_REQUIRED`.)

### 5 tâches testeurs (réponses utilisables)

1. Chronométrer : ouverture → premier appel réussi (geste + temps).  
2. Chercher « plombier » sans compte : où bloquent-ils ?  
3. Noter si « Métiers / Freelance / É-marché / Publier » sont compris (mots propres).  
4. Couper le réseau à la recherche : message compris ?  
5. Ouvrir É-marché : voient-ils un paiement / SoutraPay ? Attendu ?

---

## LOT 6 — Occasions d’amélioration

### Avant production (≤3) — fort impact

| # | Changement | Preuve | Impact | Effort | Risque | Mesure |
|---|---|---|---|---|---|---|
| 1 | CTA Accueil « Trouver un pro près de moi » au-dessus des 3 univers | Accueil 3 univers avant geste (`homePageScreenM`) | Moins d’hésitation | S | Faible | % ouverture fiche depuis Accueil |
| 2 | Masquer chip SoutraPay É-marché (+ ne pas pousser `/wallet`) | `shoppingPageScreenM` ~1487 | Promesse = réalité | S | Nul | 0 tap wallet |
| 3 | Renommer / sous-titrer les univers (ex. « Artisans & services » / « Talents digitaux » / « Boutiques ») | Labels « É-marché », « Freelance » | Clarté CI | S | Copy | Taux tap Métiers vs autres |

### Après lancement (≤3)

| # | Changement | Effort | Mesure |
|---|---|---|---|
| 1 | WhatsApp `wa.me` si numéro valide | S | Part contacts WA |
| 2 | Empty recherche → 3 suggestions proches | M | Second tap |
| 3 | Minify/shrink release | M | Taille AAB |

### Différenciant à tester plus tard (≤2)

1. Badge « vérifié » uniquement si statut serveur vrai.  
2. Accueil mono-intention « près de moi » mesuré A/B vs 3 univers.

---

## LOT 7 — Livrables

### 1. Carte parcours ouverture → contact

```
Splash → [Onboarding×4?] → Accueil
  ├─ (hésitation) 3 univers + previews + icônes commandes/notifs
  ├─ Métiers / Explorer → liste|carte → fiche → Contacter(tel)
  │     impasses: pas de tel / pas de résultat / réseau / GPS
  ├─ Freelance / É-marché (détours possibles)
  └─ Publier / Messagerie / Profil → auth wall (invité)
```

### 2. Revue écran par écran

| Écran | Preuve | Observation | Reco | Gravité | Avant/Après |
|---|---|---|---|---|---|
| Splash/Onboarding | code | 4 slides plateforme | Réduire à 2 centrés « trouver un pro » | Friction | Avant |
| Accueil | code | 3 univers avant CTA unique | CTA primaire « près de moi » | **Bloque clarté** | Avant |
| Explorer | code | Doublon Métiers | Clarifier ou fusionner entrée | Friction | Après |
| Fiche pro | code | `tel:` OK ; « similaires bientôt » | Masquer bloc fictif | Finition | Avant |
| Carte | code | Existe | Mesurer device | — | Après mesure |
| Auth | code | Gates claires | Conserver | — | — |
| Favoris | code | Auth | Vérifier deep-link fiche | Friction | Après |
| Profil | code | Wallet retiré | Conserver | — | — |
| É-marché | code | Chip SoutraPay | Masquer | **Promesse fausse** | Avant |

### 3. Direction visuelle

Voir Lot 2 — **garder le vert** ; finir cohérence Inter + retirer décoratif paiement ; vérifier contraste plein soleil **sur device**.

### 4. Perf

**NOT_MEASURED**

### 5. Matrice

Voir Lot 3.

### 6. Captures / vidéos pour Sidney → Codex

Sans PII (flouter numéros / noms / avatars si besoin) :

1. Onboarding pages 1–4 (vidéo 15 s)  
2. Accueil invité scroll complet  
3. Accueil → Métiers → liste  
4. Carte métiers  
5. Fiche pro + bouton Contacter (numéro flouté)  
6. Contacter sans numéro (si cas)  
7. Recherche 0 résultat  
8. Mode avion sur recherche  
9. Explorer chips  
10. É-marché + chip SoutraPay  
11. Publier (sheet invité)  
12. Messagerie invité  
13. Profil invité  
14. FAQ paiements  
15. Petit écran + texte agrandi (si possible)  
16. Vidéo complète « 1er appel » ≤ 60 s

### 7. Backlog dernière MAJ (ordonné)

1. CTA Accueil « Trouver un pro »  
2. Masquer SoutraPay É-marché  
3. Sous-titres / renommage univers  
4. Masquer « Prestataires similaires bientôt »  
5. Onboarding raccourci (optionnel même build)

---

## Verdict

**CORE_JOURNEY_NEEDS_SIMPLIFICATION**

Le contact sans compte est **déjà possible** (force produit).  
Le frein principal n’est pas l’absence de features : c’est la **structure multi-univers + Publier** qui force à apprendre Soutrali avant d’appeler.

---

## Cinq changements max (effet le plus fort)

1. **CTA unique Accueil** « Trouver un pro près de moi » (au-dessus des univers).  
2. **Masquer SoutraPay / wallet** partout côté client (dont chip É-marché).  
3. **Clarifier les 3 univers** (libellés + une ligne d’aide).  
4. **Masquer les blocs « bientôt »** sur fiche (similaires).  
5. **Simplifier onboarding** à 2 écrans centrés découverte/contact (sans multi-rôles).

**Arrêt.** Aucun code touché. Sidney confronte aux captures ; Codex contre-revue.
