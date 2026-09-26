# PHASE 10D-3 — Explorer, Métiers, Recherche, Filtres et Carte

**Date :** 2026-03-20  
**App :** `sdealsmobile` / `com.sdealsmobile.app` / `1.2.3+9`  
**Branche :** `jordan`  
**Verdict :** `EXPLORER_SEARCH_DEVICE_VALIDATION_PENDING`

---

## 1. Fichiers actifs identifiés (inspection)

| Zone | Fichiers principaux |
|------|---------------------|
| Onglet Explorer | `lib/mobile/view/explorer/screens/explorer_page_screen.dart` |
| Carte Explorer | `lib/mobile/view/explorer/widgets/explorer_metiers_map_panel.dart` |
| Métiers Liste/Carte | `lib/mobile/view/jobpagem/screens/jobPageScreenM.dart` |
| BLoC Métiers | `jobPageBlocM.dart`, `jobPageStateM.dart`, `jobPageEventM.dart` |
| Recherche | `searchPageScreenM.dart`, `searchPageBlocM.dart` |
| Flags client | `lib/data/config/client_feature_flags.dart` |
| Historique | `lib/data/services/local_storage_service.dart` |
| Design partagé | `client_universe_pictograms.dart`, `client_foundations.dart` |

---

## 2. Causes racines des défauts

| Symptôme | Cause identifiée | Action |
|----------|------------------|--------|
| Rayon « vide » (coche seule) | `ListTile` sans style explicite sur fond blanc / contraste faible ; sheet minimaliste | Options `2/5/10/20 km` avec texte `neutral900`, icônes check visibles |
| Historique vide / doublons | Entrées vides possiblement stockées ; affichage sans re-filtrage UI | `trim()` à la lecture + déduplication ; `addToHistory` ignorait déjà le vide |
| Onglets coupés | Libellés longs + onglets fixes | `TabBar` `isScrollable: true` (existant) ; onglet `Professionnels` au lieu de `Presta.` |
| Services = image + prix | `ListTile` subtitle = prix seul | Nom + catégorie + prix formaté + hint prestataire |
| `0,0 km` / « À proximité » non fiable | Distance affichée même à 0 ; libellé « à proximité » sans règle claire | Masquer si absent ; `< 100 m` ou mètres si &lt; 1 km |
| Note `0.0` / étoile vide | `_ratingLabel` renvoyait `—` | `null` → zone note masquée |
| Sheet carte surchargée | Draggable 72 %, prix en gros bouton, `Disponible` inventé, `Contacter` | Sheet compacte : Appeler (primaire), Demander, vérité données |
| Explorer shopping | `ShoppingPageBloc` créé même si flag off ; chip `Plus` | Provider shopping conditionnel ; `explorerWhenHidden` sans `Plus` |
| Recherche 1 caractère | Suggestions API dès 1 lettre | Suggestions + recherche globale ≥ 2 caractères ; debounce 350 ms ; tokens requête |

---

## 3. Fichiers créés

- `lib/mobile/view/common/widgets/client_provider_list_card.dart`
- `test/phase10d3_explorer_search_test.dart`
- `docs/audit/PHASE10D3_EXPLORER_SEARCH_MAP.md`

---

## 4. Fichiers modifiés (principaux)

- `client_feature_flags.dart` — `Plus` retiré ; onglets `Professionnels`
- `explorer_page_screen.dart` — hero vert pâle, univers pictogrammes, localisation, catégories, Liste/Carte, copy É-marché off
- `explorer_metiers_map_panel.dart` — pas de `requestPermission` au chargement
- `jobPageScreenM.dart` — cartes communes, Appeler/Demander, filtres, rayon, sheet carte, GPS
- `jobPageEventM.dart` / `jobPageBlocM.dart` — `searchRadius` dans `UpdateExplorerFiltersM`
- `searchPageBlocM.dart` — historique, debounce logique, requêtes obsolètes
- `searchPageScreenM.dart` — copy, onglets, services, erreur réseau, historique UI
- `local_storage_service.dart` — historique nettoyé à la lecture
- `display_text.dart` — prix groupés (`12 000 FCFA`)
- `test/stab12b_null_display_test.dart` — attente prix groupé (effet 10D-3)

---

## 5. Composants réutilisés

- `ClientUniversePictogram` (Accueil 10D-2C)
- `SDClientLocationPolicy.fallbackCity` + parcours `LocationPageScreenM`
- `ensureAuthenticatedForAction` / `DialerSession` / `showServiceRequestSheet` (10C)
- `SearchPageScreenM` (unique moteur de recherche)
- `formatOptionalPrice`, `joinPersonName`, `displayTitleCase`, `formatExperienceLabel`

---

## 6. É-marché préservé

- `ClientFeatureFlags.emarketEnabled = false` inchangé
- Aucune route / BLoC / écran shopping supprimé
- `ShoppingPageBloc` fourni seulement si flag activé
- Copy client : « Services et freelances », « Rechercher un service ou une compétence »
- Réactivation future : flags séparés (produits / boutiques / publish) à étudier lors de la vraie réactivation — non implémentés en 10D-3

---

## 7. Écarts maquette / produit

- Explorer liste : feed horizontal prestataires/freelance conservé sous le hero (pas refonte feed complet type maquette pleine page Métiers)
- Favoris sur cartes liste : non branchés (pas d’état fiable global documenté — pas de stockage parallèle)
- Filtre prix complet : non retravaillé dans cette passe (feuille recherche existante ; filtre prix Métiers non exposé en chip)
- `JobPageScreenM` et Explorer restent deux entrées vers Métiers (navigation existante)

---

## 8. Données masquées faute de preuve

- Note si ≤ 0 ou absente
- Distance si pas dans `providerDistances` ou calcul invalide
- Prix si ≤ 0 (`formatOptionalPrice` → ligne masquée)
- « Disponible » retiré de la sheet carte
- Filtre « 4+ » retiré (notes non fiables)
- `/h` seulement si tarif horaire connu et prix prestataire absent

---

## 9. Performance (code)

- Pas de second `ShoppingPageBloc` au boot Explorer si É-marché off
- Tokens `_searchRequestId` / `_suggestionRequestId` pour ignorer réponses obsolètes
- Debounce recherche 350 ms ; pas de recherche globale &lt; 2 caractères
- Pas de double `requestPermission` GPS à l’ouverture Explorer (check seulement)

---

## 10. Tests

| Suite | Résultat |
|-------|----------|
| `test/phase10d3_explorer_search_test.dart` | OK |
| `flutter test` (complète) | **346/346 OK** |
| `flutter analyze` (fichiers touchés) | 0 error ; warnings mineurs (`_ProviderCompareCard` mort, import retiré) |

---

## 11. Observation téléphone

- Session `flutter run` supposée active — **non validée par l’agent** (pas d’injection hot restart `R`).
- **Sidney :** hot restart `R`, puis parcours brief §19 (Explorer Liste/Carte, Métiers, filtres, rayon, recherche, sheet marqueur).

---

## 12. Anomalies restantes

- `_ProviderCompareCard` legacy non supprimé (warning analyze)
- Compteur carte « dans cette zone » sans garantie géo si GPS refusé (liste matching non géo)
- `provider_popup.dart` : « Disponible maintenant » encore présent (popup legacy, hors sheet 10D-3)
- Overflow 17 px `jobPageScreenM` : corrigé partiellement via `Expanded` sur titre catégories — **à revalider device 320 dp**
- Favoris carte : non implémentés sur nouvelle carte client

---

## 13. Conformité phase

| Item | Valeur |
|------|--------|
| Code backend modifié | **NON** |
| APK / AAB | **NON** |
| Commit / push | **NON** |
| Déploiement | **NON** |

---

## 14. Verdict final

`EXPLORER_SEARCH_DEVICE_VALIDATION_PENDING` — implémentation et tests automatisés OK ; validation visuelle et tactile sur appareil requise avant `EXPLORER_SEARCH_VISUALLY_APPROVED`.

**Fin de phase 10D-3 — Phase 10D-4 non entamée.**
