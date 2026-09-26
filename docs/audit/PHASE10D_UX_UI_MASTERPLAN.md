# PHASE 10D-0 — Plan directeur UX/UI 2026

**Date :** 2026-09-16  
**Application :** `sdealsmobile` / `com.sdealsmobile.app` / `1.2.3+9`  
**Branche / commit :** `jordan` @ `1c4bf71`  
**Périmètre :** invité et client uniquement. Prestataire et terrain hors périmètre. É-marché masqué. Palette verte validée, non remise en cause.  
**Mode :** plan seulement. Aucun code Flutter, aucun écran, aucun composant, aucune navigation, aucun backend, aucun build, aucun commit.

**Sources lues :** `PHASE10C_CLIENT_SCREEN_INVENTORY.md`, `PHASE10C2_CORE_BLOCKER_DIAGNOSIS.md`, `PHASE10C3_TARGETED_FIXES.md`, `PHASE10C4_RELEASE_DEVICE_SMOKE.md`, `PHASE10C5_AUTH_RESUME_FIX.md`, `PHASE10B_FINAL_REPORT.md`, `PHASE10B_FILE_MATRIX.md`, `PHASE10D_PRODUCT_UX_DESIGN_AUDIT.md`, design system (`colors`, `typography`, `spacing`, `animations`, widgets SD*), shell `home.dart`, accueil, explorer, listes Métiers, fiche, freelance, recherche.

**Décisions produit validées par Sidney (10D-1) — plus ouvertes :**

1. Navigation client : Accueil, Explorer, Messagerie, Profil.
2. Publier quitte la barre et sera déplacé dans Profil sous « Devenir professionnel ».
3. Commandes quitte l’AppBar et sera déplacé dans Profil.
4. Appeler est le CTA principal.
5. Demander un service est le CTA secondaire.
6. Texte autorisé : « Identité vérifiée » uniquement si `verifier == true`.
7. Ne jamais présenter la vérification comme une garantie de qualité.
8. Localisation : ville actuelle ou Abidjan tant que la permission GPS n’est pas accordée ; demander la permission au moment utile.
9. Wallet reste masqué tant qu’aucun paiement réel n’existe.
10. Welcome Freelance sera retiré du parcours client ; son explication sera intégrée à l’accueil et à la liste Freelance.
11. É-marché reste masqué.
12. Aucun CTA connexion sur l’accueil.

Ces décisions ne sont pas exécutées sur les écrans en 10D-1. Les tokens correspondants (`SDClientNav`, `SDClientTrust`, `SDClientLocationPolicy`) sont prêts pour 10D-2 et suivantes.

**Contraintes produit déjà validées en 10C — à conserver dans toute phase suivante :**

- pas de CTA « Se connecter » sur l’accueil invité ;
- après logout, accueil invité existant, sans CTA auth ajouté ;
- murs invités Profil et Messagerie conservés ;
- Appeler / Demander / Messagerie / Favoris / Publier protégés, puis reprise de l’action ;
- recherche et son état conservés ;
- É-marché piloté par le flag existant, pas par une suppression d’écrans ;
- aucun badge « vérifié » inventé si le statut serveur (`verifier`) n’est pas vrai.

Les observations device de la 10C-1 (échec d’appel, bannière réseau) sont historiques. Elles ne décrivent pas l’état produit après 10C-3 / 10C-5 / 10C-6.

---

## 0. Preuve d’observation

| Couche | Statut |
| --- | --- |
| Code actif invité/client | Examiné |
| 50 interfaces actives 10C | Examinées via inventaire + code des parcours critiques |
| 19 orphelins, legacy, démos, espace prestataire | Non utilisés comme base |
| Téléphone `AUHIAYBAMZNZKZKR` / `flutter run` | Processus au premier plan (`MainActivity`). Dump d’accessibilité : **6 nœuds, aucun libellé**. L’écran affiché n’a pas pu être identifié sans exposer de PII. Aucune capture supplémentaire. |
| Verdict visuel | **Pas de note esthétique.** Aucun écran n’est déclaré « moderne » ou « professionnel » au regard. |

Observation retenue pour ce rapport : **`STATIC_ONLY`** (analyse code + audits), avec un contrôle premier plan non identifiable.

---

## 1. Promesse centrale

> Trouver rapidement un professionnel fiable à proximité, comprendre son offre et le contacter ou lui envoyer une demande.

**Réponse :** le produit sait faire cette promesse dans Métiers (liste, carte, fiche, Appeler, Demander). Il ne la rend pas immédiate. L’accueil demande d’abord de choisir un univers, sous un titre « Explorer les univers », avant la proximité.

| Élément actif | Aide la promesse ? |
| --- | --- |
| Cartes Métiers + proximité | Oui, mais trop tard et trop conceptuel |
| Freelance | Oui, autre offre. La différence n’est pas dite en une phrase |
| Recherche | Oui. Entrée secondaire, pas l’action d’accueil |
| Fiche + Appeler + Demander | Oui. Cœur du produit |
| Explorer | Partiel. Utile pour filtres / carte, redondant avec l’accueil |
| Messagerie | Après l’échange seulement. Pas une raison d’ouvrir l’app |
| Publier (bouton central) | Non pour un client. C’est une frontière prestataire |
| Notifications / Commandes dans l’AppBar | Non au premier regard. Commandes a peu de sens tant qu’É-marché est masqué |
| É-marché | Hors expérience visible. Correct |

Principes retenus des références, sans copie visuelle :

- Wave : un objectif, peu de choix, langage simple.
- Yango : l’action principale avant le secondaire ; information progressive ; carte et sheet hiérarchisés.
- LinkedIn : identité, preuve, structure. Pas de fil.
- Facebook Marketplace : cartes locales, essentiel avant le détail, contact rapide.
- Mon Artisan / Artisan CI : besoin nommé, proximité, confiance métier.
- AliExpress : catalogue réservé à un futur É-marché réel. Interdit dans Métiers et Freelance.

---

## 2. Décisions d’expérience (avant le design system)

### Accueil

On comprend mal, au premier écran, que Soutrali Deals sert à trouver un pro près de soi. On comprend qu’il existe des « univers ».

| Question | Décision |
| --- | --- |
| Promesse immédiate | Non aujourd’hui. Cible : une phrase + une recherche + Métiers près de vous, avant les univers |
| Métiers / Freelance explicites | Non. Une phrase chacun, pas seulement une illustration |
| Recherche principale dès l’accueil | Oui, champ qui ouvre la recherche existante. Pas un deuxième moteur |
| « Explorer les univers » | Retirer comme titre. N’aide pas l’action |
| Icônes | Non cohérentes : PNG `assets/banner/metier.png`, `freelances.png`, `marketplace.png` + Material (`handyman`, `laptop_mac`, `shopping_bag`) |
| Proximité assez tôt | Non. La section « Métiers près de vous » existe (code) mais après le choix d’univers |
| Notifications / Commandes dans l’AppBar | Validé : Notifications en icône. Commandes quitte l’AppBar et va dans Profil |
| Densité | Trop dispersé en haut, trop conceptuel, pas trop vide de widgets |
| Envie de l’action principale | Faible tant que le premier geste n’est pas « trouver » |
| CTA connexion | Ne pas en ajouter. Déjà correct |

### Explorer

Garder comme lieu de découverte (recherche, catégories, liste/carte, filtres). Ne pas fusionner avec l’accueil : la carte et les filtres n’ont pas leur place sur la première page. Retirer tout onglet dont la seule raison était É-marché. Le retour après recherche doit rester celui déjà réparé en 10C.

### Liste Métiers

Le double CTA Contacter + Demander sert la promesse. Le problème est la carte : identité, zone, prix, distance, note et vérification se répètent avant qu’on sache qui appeler. Vérification uniquement si `verifier == true`. Note uniquement si le serveur en fournit une. Pas de note inventée, pas d’étoile vide décorative.

### Fiche professionnelle

Avant l’appel, seulement : nom, métier, zone, distance, prix s’il existe, disponibilité si elle existe, une description courte, spécialités si elles changent le choix, « Identité vérifiée » seulement si `verifier == true`. Ce libellé n’est pas une garantie de qualité. Avis après. Appeler est le CTA principal. Demander un service est le CTA secondaire. Partage et signalement restent secondaires. Ne pas créer un badge vérifié local.

### Freelance

Conserver l’univers, ne pas le fusionner avec Métiers. L’objet n’est pas le même (offre, compétences, portfolio, tarifs vs artisan de proximité). Harmoniser chrome, cartes, fiche et états avec Métiers. Welcome Freelance sera retiré du parcours client. Dire la différence en une phrase sur l’accueil et dans la liste : « un métier près de chez vous » vs « une compétence à distance ou au projet ». Non exécuté en 10D-1.

### Recherche

Conserver. Le manque n’est pas un nouvel algorithme : entrée trop tardive, état vide à rendre explicite, filtres à limiter à ce qui change vraiment la liste (zone, catégorie, vérifié si le flag existe).

### Messagerie

Mur invité : conserver. État vide : assumer qu’il n’y a rien tant qu’aucun échange n’existe. Pas de fausse conversation. La création de conversation ne doit pas précéder un contact ou une demande.

### Profil

Mur invité : conserver. Menu trop long. Les actions rares (langue, sécurité, 2FA, suppression de compte, à propos, préférences) restent dans le hub Paramètres déjà existant. Déconnexion visible, pas noyée. Suppression de compte jamais à côté de Déconnexion.

### Publier

| Option | Effet |
| --- | --- |
| 1. Conserver le bouton central | Acquisition prestataire visible. Contredit la promesse client. Charge cognitive permanente |
| 2. Réduire son importance | Compromis visuel. Le geste reste au centre, donc encore prioritaire |
| 3. Entrée « Devenir professionnel » dans Profil | Aligne la barre sur le client. L’acquisition reste possible, hors du premier regard |

**Validé : option 3.** Libellé : « Devenir professionnel ». Pas une suppression fonctionnelle : les écrans d’accueil prestataire restent, l’entrée change de place. Non exécuté en 10D-1.

---

## 3. Principes visuels 2026

Aucun jugement « beau / moderne ». Constats de code uniquement.

### Typographie

Famille actuelle : Inter. Les alias `headline = display` et les tailles 32 / 28 / 24 créent une échelle trop large pour un mobile 320–393 dp. Majuscules et tailles locales existent en dehors des tokens.

Échelle unique proposée (ne pas en ajouter) :

| Rôle | Taille | Graisse | Usage |
| --- | --- | --- | --- |
| Titre d’écran | 22 | 600 | Un seul par écran |
| Section | 18 | 600 | H2 |
| Carte / nom | 16 | 600 | Identité |
| Corps | 15 | 400 | Description, interligne 1.4 |
| Légende | 13 | 400 | Distance, meta |
| Prix | 16 | 600 | Toujours le token prix, jamais une taille locale |

Pas de 32 dp sur l’accueil. Pas de capitales pour les titres de section.

### Espacement

Grille 8 dp (le 4 dp du fichier `spacing.dart` reste l’unité interne). Marge horizontale 16. Entre sections 24. Entre cartes 12. Aligner les CTA de carte sur la même ligne de base. Éviter les blocs illustration hauts qui repoussent la proximité sous la ligne de flottaison.

### Formes

Cible, déjà en partie dans `SDSpacing` : bouton et champ 12, carte 16, sheet 24, chip 8. Interdire les rayons 10 et les rayons locaux « + 2 ». Ombres : une seule, légère, sur la barre basse. Pas d’ombre par carte si la bordure suffit.

### Icônes

Règle unique : Material Icons, outlined au repos, filled à l’état actif, 24 dp dans le contenu, une seule couleur `neutral700` / `neutral900`. Pas de PNG d’univers sur l’accueil. Les photos réelles (avatar, chantier) restent des photos, pas des icônes. Objectif : ne pas lire comme un assemblage d’illustrations générées séparément.

### Images et avatars

Fallback initiales si pas de photo publique. Même cadrage carte et fiche (1:1, visage ou atelier). Pas de fond transparent visible. Ne pas exiger une photo pour afficher un métier : le code accueil le permet déjà pour Métiers ; le conserver.

### Animations utiles seulement

| Mouvement | Durée | Courbe |
| --- | --- | --- |
| Feedback de toucher | 100 ms | `easeOut` |
| Changement d’onglet | 150 ms | `easeOutCubic` |
| Sheet | 200 ms | `easeOutCubic` |
| Skeleton → contenu | fondu 150 ms | `easeOut` |
| Favori | 120 ms | `easeOut` |

`Reduce Motion` : pas d’animation, état final immédiat. Retirer l’usage client de `bounce` / `elasticOut` (`SDAnimations`). Pas de rebond, pas de transition différente par écran.

### États obligatoires

Chargement, contenu, vide, erreur, hors connexion, action désactivée, succès, retour après authentification. Les murs invités existants comptent comme état, pas comme erreur. Ne pas réafficher une fausse bannière réseau.

---

## 4. Analyse des écrans critiques

Chaque ligne est une décision de code, pas un compliment.

| Critère | Accueil | Explorer | Liste Métiers | Fiche | Freelance | Recherche | Messagerie | Profil |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Compréhension | Faible | Moyenne | Moyenne | Meilleure | Faible | Bonne | Bonne si mur clair | Moyenne |
| Hiérarchie | Univers avant proximité | Recherche noyée si onglets restants | Deux CTA utiles, meta répétée | CTA bas correct si visibles | Parallèle incomplet de Métiers | Correcte | Secondaire | Menu trop plat |
| Cohérence | PNG + Material | Dépend du flag É-marché | Cartes dupliquées (liste et popup) | Badge vérifié à conditionner | Chrome différent | OK | OK | OK |
| Densité | Haute en concept, basse en utilité | Variable | Trop d’infos répétées | Longue | Variable, vide fréquent | OK | Vide avant échange | Trop longue |
| Confiance | Non prouvée à l’accueil | Partielle | Seulement si `verifier` | Seulement si statut serveur | Portfolio si données réelles | N/A | N/A | Compte réel rassure |
| Simplicité | Non | Partielle | Non | Non | Non | Oui | Oui | Non |
| Qualité perçue | Non jugée sans capture | Non jugée | Non jugée | Non jugée | Non jugée | Non jugée | Non jugée | Non jugée |
| Accessibilité | Arbre device non identifiable | À tester | 320 dp non prouvé | 7 px d’overflow sheet corrigé en code, non re-observé | À tester | Clavier à retester | À tester | Cibles menu à mesurer |
| Texte | « Explorer les univers » inutile | Onglets hérités | Libellés CTA doubles | Trop de blocs avant l’appel | « Freelance » comme meta | OK | OK | Libellés techniques possibles |
| Espacement | Sections trop séparées du geste | À aligner sur 16/24 | Cartes serrées ou trop hautes selon variante | Sheet à 60 dp déjà limite | À aligner | OK | OK | Liste longue |
| Icônes | Mélange PNG / Material | Material nav + contenu | `verified` parfois décoratif | Idem | Idem | OK | OK | OK |
| CTA | Pas d’action « trouver » | Pas de doublon avec Publier | Contacter + Demander à hiérarchiser | Appeler principal | Contact secondaire | Soumettre clair | Pas de fausse création | Déconnexion à isoler |
| États manquants | Offline accueil à confirmer | Vide catégories | Note absente non dessinée | Avis vide | Vide offres | Déjà en partie là | Vide réel | N/A |

---

## 5. Navigation principale

Fréquences : estimation produit, pas de mesure analytics.

| Destination | Fréquence client | Valeur | Auth | Chevauchement | Charge | Maintenance |
| --- | --- | --- | --- | --- | --- | --- |
| Accueil | Haute | Promesse | Non | Explorer | Élevée aujourd’hui | Élevée |
| Explorer | Haute | Trouver | Non | Accueil | Élevée | Élevée |
| Publier | Basse | Prestataire | Oui | Profil | Élevée (centre visuel) | Élevée |
| Messagerie | Basse jusqu’à un échange | Après contact | Oui | Demande | Moyenne | Moyenne |
| Profil | Moyenne | Compte, réglages | Mur si invité | Commandes, Publier | Élevée | Élevée |

### Architecture A — recommandée

Accueil, Explorer, Messagerie, Profil. Publier sort de la barre. Entrée « Devenir prestataire / freelance » dans Profil.

- Avantages : la barre sert la promesse. Cinq choix deviennent quatre. Pas de nouvel onglet.
- Inconvénients : l’acquisition prestataire est moins visible.
- Parcours existants : l’action protégée Publier reste, déclenchée depuis Profil.
- Migration : déplacer l’entrée, conserver les welcome screens, ne pas supprimer les routes.
- Risque : acquisition prestataire moins visible. Accepté.

### Architecture B — repli

Garder les cinq destinations. Le bouton central n’est plus un cercle vert plein : même poids visuel que les autres onglets, libellé inchangé.

- Avantages : aucun parcours déplacé.
- Inconvénients : le centre reste lu comme l’action principale. Dette conservée.
- Risque : plus faible, gain utilisateur plus faible.

**Ne pas ajouter d’onglet.** Ne pas fusionner Accueil et Explorer.

**Décision validée : architecture A.** Accueil, Explorer, Messagerie, Profil. Publier n’est pas un onglet. Le déplacement se fait en 10D-2, pas en 10D-1.

---

## 6. Matrice des 50 interfaces actives

Fréquence : estimation produit (Haute / Moyenne / Basse), pas une statistique. Priorité : P1 immédiate, P2 avec le phasage, P3 quand les données existent.

| Interface | Rôle actuel | Fréquence | Problème | Décision | Écran/composant cible | Gain | Risque | Priorité |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SHELL-001 Home | Barre 5 destinations + Publier | Haute | Publier au centre, hors promesse | SIMPLIFIER | Barre validée : Accueil, Explorer, Messagerie, Profil | Charge cognitive | Acquisition prestataire | P1 |
| FILE-HORS-001 OnboardingScreen | Hors graphe actif | Basse | Pas le parcours quotidien | HORS_PÉRIMÈTRE | Aucun | Évite une fausse dette | Ne pas le réactiver par erreur | P3 |
| UI-ACT-003 AlertDetailScreenM | Détail notification | Basse | Secondaire | CONSERVER | Inchangé | — | — | P3 |
| UI-ACT-004 AlertPageScreenM | Liste notifications | Moyenne | Entrée AppBar trop visible | SIMPLIFIER | Icône AppBar, pas un titre d’accueil | Promesse d’abord | Moins de découvrabilité | P2 |
| UI-ACT-005 AlertSettingsScreenM | Réglages alertes | Basse | Doublon de réglage | HARMONISER | Hub Paramètres | Menu plus court | Régression d’entrée | P3 |
| UI-ACT-006 AvisDetailScreenM | Détail avis | Basse | Preuve utile seulement si avis réel | CONSERVER | Sous la fiche | Confiance réelle | Avis vide | P3 |
| UI-ACT-007 AvisPageScreenM | Liste avis | Basse | Page longue hors besoin d’appel | SIMPLIFIER | Bloc fiche, page si > 3 avis | Moins de détour | Perte de page dédiée | P2 |
| UI-ACT-008 ChatPageScreenM | Messagerie | Moyenne après échange | Vide avant tout contact | SIMPLIFIER | Mur invité + vide honnête | Moins de fausse attente | Utilisateurs qui cherchent un chat général | P2 |
| UI-ACT-009 ExplorerPageScreen | Découverte | Haute | Doublon accueil, onglets É-marché | SIMPLIFIER | Recherche, catégories, liste/carte | Un rôle clair | Ne pas fusionner avec l’accueil | P1 |
| UI-ACT-010 FavoriteDetailScreenM | Détail favori | Basse | Redondant avec la fiche | HARMONISER | Fiche existante | Un modèle de fiche | Perte d’un écran favori distinct | P3 |
| UI-ACT-011 FavoritePageScreenM | Liste favoris | Moyenne | Entrée peu visible, acceptable | CONSERVER | Profil | Retour vers un pro déjà choisi | — | P3 |
| UI-ACT-012 FreelanceWelcomeScreen | Intro freelance | Basse | Écran d’explication en plus du contenu | RETIRER_DU_PARCOURS | Validé : phrase sur l’accueil + liste Freelance | Un geste de moins | Perte d’un écran pédagogique | P2 |
| UI-ACT-013 FreelancePageScreen | Liste freelance | Moyenne | Différence Métiers peu dite | HARMONISER | Même chrome que liste Métiers | Comparaison possible | Fusion data interdite | P2 |
| UI-ACT-014 FreelanceDetailsScreen | Fiche freelance | Moyenne | Fiche non alignée | HARMONISER | Ordre d’info de la fiche métier | Confiance | Ne pas copier la zone artisan | P2 |
| UI-ACT-015 FreelanceServiceOfferDetailScreen | Offre | Moyenne | Deux objets (personne / offre) | CONSERVER | Fiche offre | Différence métier réelle | Confusion si le libellé reste « Freelance » | P2 |
| UI-ACT-016 HistoryDetailScreenM | Détail historique | Basse | Peu lié à « trouver » | CONSERVER | Profil | Preuve d’usage | — | P3 |
| UI-ACT-017 HistoryPageScreenM | Historique | Basse | Menu long | SIMPLIFIER | Groupe Profil « Activité » | Lisibilité | Entrée plus profonde | P3 |
| UI-ACT-018 HomePageScreenM | Accueil | Haute | Univers avant proximité | SIMPLIFIER | Promesse, recherche, proximité | Compréhension | Ne pas ajouter de CTA login | P1 |
| UI-ACT-019 CategoriesListScreen | Catégories | Haute | Utile si libellés métier clairs | CONSERVER | Explorer | Choix du besoin | Catégories trop fines | P2 |
| UI-ACT-020 DetailPage | Ancienne fiche / détail | Moyenne | Chevauche la fiche prestataire | HARMONISER | UI-ACT-023 si même objet | Un modèle | Fusion seulement si le métier est identique | P2 |
| UI-ACT-021 FullMapScreenM | Carte | Moyenne | Utile, lourde | CONSERVER | Depuis Explorer / liste | Proximité | Perf non mesurée | P2 |
| UI-ACT-022 JobPageScreenM | Liste Métiers | Haute | Cartes denses, CTA répétés | SIMPLIFIER | Carte courte + 2 CTA | Lecture 320 dp | Perte d’info secondaire | P1 |
| UI-ACT-023 ProviderProfileScreen | Fiche pro | Haute | Trop avant l’appel | SIMPLIFIER | Identité → preuve → CTA | Décision plus rapide | Info utile reléguée | P1 |
| UI-ACT-024 LocationPageScreenM | Zone | Moyenne | Nécessaire à la proximité | CONSERVER | Accueil / Explorer | Promesse locale | Permission GPS | P2 |
| UI-ACT-025 LoginPageScreenM | Login direct ou protégé | Haute si action | Ne pas le remettre sur l’accueil | CONSERVER | Flux protégé existant | Reprise d’action | Ne pas retoucher le marqueur 10C-6 | P3 |
| UI-ACT-026 ServiceRequestSummaryScreen | Récap demande | Haute après CTA | Dépend de la fiche | CONSERVER | Sheet puis récap | Confiance de l’envoi | Overflow sheet déjà corrigé en code, non re-vu | P2 |
| UI-ACT-027 ServiceRequestsListScreen | Mes demandes | Moyenne | Confondu avec Commandes | SIMPLIFIER | Profil « Demandes » | Moins de doublon | Commandes AppBar | P2 |
| UI-ACT-028 PreferencesPageScreenM | Préférences | Basse | Trop haut dans le profil | HARMONISER | Hub Paramètres | Menu court | Régression | P3 |
| UI-ACT-029 AboutScreen | À propos | Basse | OK en réglages | CONSERVER | Paramètres | — | — | P3 |
| UI-ACT-030 DeleteAccountScreen | Suppression | Basse | Danger si proche de logout | CONSERVER | Paramètres, séparé | Sécurité | Mauvais placement actuel | P2 |
| UI-ACT-031 EditProfileScreen | Édition profil | Basse | OK | CONSERVER | Profil connecté | — | — | P3 |
| UI-ACT-032 HelpSupportScreen | Aide | Basse | OK | CONSERVER | Paramètres | — | — | P3 |
| UI-ACT-033 LanguageSettingsScreen | Langue | Basse | Pas dans la barre | HARMONISER | Paramètres | Bruit en moins | — | P3 |
| UI-ACT-034 ProfilPageScreenM | Compte | Haute | Menu trop long | SIMPLIFIER | Compte, activité, réglages, devenir pro | Lecture | Décision Publier | P1 |
| UI-ACT-035 ProfileSettingsHubScreen | Hub réglages | Moyenne | Déjà le bon contenant | CONSERVER | Cible des entrées rares | Réutilisation | — | P2 |
| UI-ACT-036 RegisterPageScreenM | Inscription protégée ou directe | Moyenne | Ne pas l’exposer sur l’accueil | CONSERVER | Flux existant | — | Ne pas casser OTP / extra | P3 |
| UI-ACT-037 SearchPageScreenM | Recherche | Haute | Entrée trop tardive | SIMPLIFIER | Champ d’accueil vers cet écran | Moins de détour | Ne pas perdre l’état | P1 |
| UI-ACT-038 SecurityPageScreenM | Sécurité | Basse | Homonyme possible avec 039 | HARMONISER | Un hub, pas une fusion aveugle | Clarté | Fusion interdite sans diff métier | P3 |
| UI-ACT-039 SecuritySettingsScreenM | Réglages sécurité | Basse | Voir 038 | HARMONISER | Hub | Clarté | Idem | P3 |
| UI-ACT-040 TwoFactorSetupScreenM | 2FA | Basse | OK en profondeur | CONSERVER | Sécurité | — | — | P3 |
| UI-ACT-041 EmarketWelcomeScreen | Frontière vendeur | Nulle visible | É-marché masqué | MASQUER_TEMPORAIREMENT | Flag existant | Pas de faux catalogue | Réouverture future | P3 |
| UI-ACT-042 ServiceProviderWelcomeScreenM | Frontière prestataire | Basse | Hors périmètre visuel client | HORS_PÉRIMÈTRE | Entrée Profil « Devenir professionnel » | Promesse client | Ne pas supprimer la route | P2 |
| UI-ACT-043 ConfirmationCommandeScreen | Checkout | Nulle visible | Sans catalogue | MASQUER_TEMPORAIREMENT | É-marché futur | Pas de parcours mort | — | P3 |
| UI-ACT-044 DeliveryAddressScreen | Livraison | Nulle visible | Sans catalogue | MASQUER_TEMPORAIREMENT | É-marché futur | Idem | — | P3 |
| UI-ACT-045 PanierProductScreenM | Panier | Nulle visible | Sans catalogue | MASQUER_TEMPORAIREMENT | É-marché futur | Idem | — | P3 |
| UI-ACT-046 ProductDetails | Fiche produit | Nulle visible | AliExpress réservé au futur | MASQUER_TEMPORAIREMENT | Catalogue réel plus tard | Pas de densité importée | — | P3 |
| UI-ACT-047 ShoppingPageScreenM | Boutique | Nulle visible | Masqué | MASQUER_TEMPORAIREMENT | Flag | Cohérence | — | P3 |
| UI-ACT-048 VendorDetailsScreenM | Vendeur | Nulle visible | Masqué | MASQUER_TEMPORAIREMENT | Flag | — | — | P3 |
| UI-ACT-049 SplashScreenM | Démarrage | Haute une fois | Doit être court | CONSERVER | Inchangé | Perception de vitesse | Splash décoratif | P3 |
| UI-ACT-050 WalletPageScreenM | Portefeuille | Basse | Peu de valeur sans paiement réel | MASQUER_TEMPORAIREMENT | Validé : masqué tant qu’aucun paiement réel n’existe | Pas de faux argent | Réouverture prématurée | P3 |

Aucune fusion Métiers / Freelance. Aucune fusion Sécurité 038 / 039 dans ce plan : les fichiers ne sont pas prouvés identiques.

---

## 7. Design system cible

Tokens lus : Inter ; primary500 `#1CBF3F`, primary600 `#1AA12A`, secondary orange `#F97316`, neutral900 `#171717` ; grille 4 ; bouton 56 / compact 48 ; rayons 8 / 12 / 16 / 24 ; animations jusqu’à 500 ms dont bounce.

| Token/composant | Actuel | Problème | Cible proposée | Migration |
| --- | --- | --- | --- | --- |
| Couleur primaire | Vert validé | Aucun | Inchangée | Ne pas y toucher |
| Secondary orange | Présent | Deuxième accent si utilisé comme CTA principal | Réservé aux alertes / prix promo, pas au CTA principal | Audit d’usage en 10D-1 |
| Typo | Inter + display 32 | Trop d’échelons | 22 / 18 / 16 / 15 / 13 | Remplacer les tailles locales |
| Espacement | sm 16, md 24, lg 32 | Locaux hors grille | 8 / 12 / 16 / 24 seulement à l’écran | 10D-1 |
| Rayon | 8, 10, 12, 16, 24 | 10 hors token | 8 chip, 12 contrôle, 16 carte, 24 sheet | Étendre `SDCard` / `SDEntityCard` |
| Bordure | Mêlée ombre / bordure | Cartes trop « collage » | Bordure `neutral` 1 dp, ombre seulement sur la barre | 10D-3 |
| Élévation | Ombre barre blur 20 | Lourde | Une ombre, blur ≤ 12 | `home.dart` en 10D-2 |
| Bouton | `SDButton` 56, compact 48 | Sheets locales (`ElevatedButton` 60) | 48 compact en sheet, 56 en CTA de fiche | Remplacer les boutons locaux |
| Champ | `SDInput` 12 | OK | Conserver | — |
| Chip | Rayon local 8 | OK si unique | Token chip | 10D-3 |
| AppBar | `SDWhiteAppBar`, `SDAppBar` | Deux barres | Blanche pour le client, une hauteur | Ne pas en créer une troisième |
| Carte | `SDEntityCard` + cartes locales | Réimplémentations | Une carte métier, une carte freelance, mêmes marges | 10D-3 |
| Bottom sheet | Locaux | Overflow 7 px déjà vu sur la demande | Handle, padding, CTA 48 | 10D-4, sans refaire le flux auth |
| Navigation | Barre custom 78 + safe area | Bonne couverture EMUI | Garder la mesure `systemBottomInset` | Ne pas la recoder |
| États | `GuestAuthState`, `SDErrorState`, `SDLoadingInline` | Non partout | Ces trois, plus vide dédié | 10D-5 / 10D-6 |
| Icônes | Material + PNG univers | Mélange | Material seul pour l’UI ; photos pour les gens | 10D-2 |
| Motion | bounce / elastic | Décoratif | 100–200 ms, `easeOutCubic`, Reduce Motion | 10D-1 |
| Google | `SDGoogleSignInButton` | Aligné 56 / 12 | Conserver | Ne pas le redessiner |

À améliorer plus tard, sans les créer maintenant : `SDButton` (variant sheet), `SDEntityCard` (densité courte), `SDErrorState` (vide vs erreur vs hors ligne déjà distingués en 10C).  
À étendre : AppBar icône (`SDAppBarIconThemed`) pour Notifications.  
À remplacer plus tard : cartes et CTA réécrits dans `jobPageScreenM`, popup prestataire, illustrations d’accueil.  
Ne pas créer de composant en 10D-0.

---

## 8. Accessibilité

| Sujet | Constat | Cible |
| --- | --- | --- |
| Contraste | Vert sur blanc à vérifier, pas mesuré ici | WCAG AA texte et icône |
| Cibles | Barre haute, items en `Expanded` ; sheet déjà limite | 48 dp minimum |
| Text scale 1.0 / 1.3 / 1.5 | Non prouvé | Pas de troncature du nom, du prix, des CTA |
| 320 / 360 / 393 dp | Device 720×1640 @ 320 dpi ≈ 360 dp logiques | Cartes lisibles sans scroll horizontal |
| TalkBack | Dump premier plan : 6 nœuds, 0 libellé. Écran non identifié. `Semantics(` absent en recherche simple sur `lib` | Chaque CTA a un label. L’info n’est jamais seulement une couleur |
| Focus / clavier | Login déjà sensible (retour clavier vs pop) | Clavier ne doit pas dépiler la fiche |
| SafeArea / barres | `systemBottomInset` déjà là | Le conserver |
| Reduce Motion | Non branché | Voir section motion |

Tests à créer à l’implémentation, pas maintenant : contrastes tokens ; cibles 48 dp sur barre, fiches, sheets ; golden ou robot à textScale 1.3 sur accueil et carte métier en 320 dp ; labels TalkBack des CTA Appeler et Demander ; Reduce Motion coupe le bounce.

---

## 9. Performance perçue

Aucune note. Pas de profile, pas de release mesuré dans cette phase.

| Constat | Classe |
| --- | --- |
| Accueil lance `fetchFreelances` et `fetchHomeFreelanceServices` avant même que l’utilisateur choisisse Freelance | Risque statique |
| Carte plein écran + listes images | Risque statique |
| Cartes métier reconstruites en plusieurs variantes dans le même fichier | Risque statique de rebuild |
| Splash et images banner PNG non auditées en poids | Mesure appareil nécessaire |
| Fluidité, mémoire, temps jusqu’au premier pro visible | Mesure appareil nécessaire |
| Fausse lenteur network déjà distinguée en 10C | Problème traité, ne pas le rouvrir sans nouveau constat |

Budgets futurs, non mesurés :

- premier contenu utile (un pro ou un état vide honnête) < 1,5 s sur réseau 4G local après cache chaud ;
- latence au toucher d’un CTA < 100 ms avant feedback ;
- animation ≤ 200 ms ;
- images de carte ≤ 200 Ko affichées ;
- requêtes d’accueil : métiers à proximité d’abord, freelance seulement si l’onglet ou la section est visible ;
- mémoire : pas de cible chiffrée avant profile.

---

## 10. Simplification produit

- Retirer sans perte de valeur client : le titre « Explorer les univers » ; les PNG d’univers ; le bounce ; les onglets É-marché déjà masqués ; l’entrée Commandes de l’AppBar tant qu’il n’y a pas de commandes réelles.
- Masquer jusqu’aux données : É-marché (déjà fait), panier, checkout, wallet, notes et badges sans champ serveur.
- Écrans trop longs : Profil, fiche prestataire, accueil conceptuel.
- Actions répétées : Contacter sur carte, popup et fiche — acceptable si la carte reste le raccourci et la fiche le détail. Ne pas ajouter un troisième parcours.
- Hésitation : choix Métiers / Freelance / Publier avant de savoir quoi faire.
- Connexion trop tôt : non sur l’accueil, correct. Ne pas la réintroduire. Les murs Messagerie et Profil sont le bon moment.
- Différence Métiers / Freelance : non évidente. La garder, l’expliquer, ne pas fusionner.
- Notifications, Commandes, Messagerie, Publier dans la navigation principale : non, pas tous. Navigation validée : Accueil, Explorer, Messagerie, Profil. Notifications en icône. Commandes et Publier dans Profil. Non exécuté en 10D-1.

Aucune nouvelle fonction majeure avant cette simplification.

---

## 11. Innovations sobres (deux maximum)

### 1. Reprise de la dernière recherche

- Problème : retrouver un pro déjà cherché demande de recommencer.
- Utilisateur : invité ou client qui revient.
- Fonctionnement : une ligne « Reprendre : plombier · Cocody » ouvre la recherche existante avec la requête déjà conservée.
- Données : état de recherche déjà en mémoire / stockage local. Pas de nouveau backend.
- Effort : S.
- Risque : exposer une requête sensible. N’afficher que le texte de recherche déjà saisi par l’utilisateur sur l’appareil, jamais un historique serveur d’autrui.
- Succès : retour à la même liste en un geste, sans ressaisie.

### 2. Confiance en une ligne, seulement si le serveur le dit

- Problème : « vérifié » ou une étoile vide ne rassure pas, ou ment.
- Utilisateur : client avant l’appel.
- Fonctionnement : si `verifier == true`, une ligne « Identité vérifiée » + une phrase fixe expliquant ce que cela couvre. Sinon, rien. La note s’affiche seulement si elle existe.
- Données : champs déjà lus (`verifier`, `note`).
- Effort : S.
- Risque : le libellé validé est « Identité vérifiée ». Ne pas promettre une qualité de travail.
- Succès : moins de badges décoratifs ; le badge restant est compris sans ouvrir une page d’aide.

Non retenus : demande guidée supplémentaire (le sheet existe déjà), personnalisation, IA, paiement.

---

## 12. Livrable décisionnel

### A. Diagnostic honnête

**Forces**

1. La promesse existe réellement : liste, carte, fiche, appel, demande.
2. L’auth protégée et le retour invité sont en place. Ne pas les redessiner.
3. Un design system existe (Inter, vert, `SDButton`, `SDInput`, états).
4. É-marché est sorti de l’expérience visible. Bon réflexe.
5. La barre gère déjà les insets système difficiles (EMUI).

**Faiblesses prioritaires**

1. L’accueil ne dit pas le travail à faire.
2. Métiers et Freelance ne sont pas distingués en langage.
3. Publier occupe le centre d’une app de recherche.
4. Icônes PNG et Material coexistent.
5. Cartes trop répétitives, vérification pas toujours conditionnelle.
6. Fiche trop longue avant l’appel.
7. Profil trop long, hors Paramètres.
8. Explorer chevauche l’accueil.
9. Accueil charge le freelance avant le besoin.
10. Accessibilité non prouvée ; l’écran au premier plan n’exposait aucun libellé.

**Dettes**

- Visuelle : rayons locaux, ombres, PNG d’univers, tailles hors échelle, orange secondaire non cadré.
- UX : cinq destinations, univers avant tâche, Commandes trop tôt, welcome freelance en plus.
- Performance : requêtes d’accueil, carte, images, variantes de cartes. Non mesurée.
- Accessibilité : labels, text scale, 48 dp, Reduce Motion. Non mesurée, un indice device négatif non généralisable.

### B. Cinq changements pour la première implémentation

Ils ne dépendent pas de la suppression du bouton Publier.

| Changement | Écrans | Avant | Après attendu | Effort | Risque | Critère d’acceptation |
| --- | --- | --- | --- | --- | --- | --- |
| 1. Accueil au service de la promesse | HomePageScreenM | Titre d’univers, PNG, proximité plus bas | Phrase de promesse, différence Métiers/Freelance, recherche vers l’écran existant, proximité plus haut, pas de CTA login | M | Copier un ancien CTA auth | Invité comprend l’action sans inscription ; aucun bouton Se connecter |
| 2. Une seule règle d’icônes | Accueil, Explorer, barre | PNG + Material | Material 24 dp pour l’UI ; photos seulement pour les personnes | S | Régression visuelle des bannières | Plus aucun PNG d’univers sur l’accueil |
| 3. Carte métier courte | JobPageScreenM, popup | Meta répétée, vérifié ambigu | Nom, métier, zone, distance, prix si présent, vérifié seulement si `verifier` | M | Perte d’info utile | 320 dp : CTA lisibles, pas de note inventée |
| 4. Fiche avant l’appel | ProviderProfileScreen | Longueur, CTA noyés | Bloc identité + preuve conditionnelle + Appeler principal + Demander secondaire | M | Casser la reprise auth | Appeler et Demander fonctionnent encore après login |
| 5. États honnêtes réutilisés | Messagerie, Freelance, Recherche, Explorer | Vides inégaux | `GuestAuthState` / `SDErrorState` / `SDLoadingInline`, vide distinct de l’erreur et du hors-ligne | S | Réintroduire une fausse bannière | Hors-ligne ≠ erreur serveur, comme en 10C |

### C. Phasage (ne pas exécuter)

| Phase | Fichiers probables | Dépendances | Tests | Risques | Preuve appareil |
| --- | --- | --- | --- | --- | --- |
| 10D-1 Fondations | `design_system/*` tokens seulement, pas de nouvel widget | Palette verte figée | Tests tokens si existants | Casser `SDButton` | Non |
| 10D-2 Accueil et navigation | `homePageScreenM.dart`, barre : retirer Publier | Décisions Sidney déjà validées | Widget accueil sans CTA login | Régression logout / index shell | Capture PII masquée, 360 dp |
| 10D-3 Explorer, listes, recherche | Explorer, `jobPageScreenM.dart`, `search` | 10D-1 | État de recherche conservé | Perte de filtre | Liste + retour recherche |
| 10D-4 Fiche et demande | `provider_profile_screen.dart`, sheet demande | Reprise auth 10C-6 intouchée | Appeler / Demander protégés | Pop de fiche, overflow | Sheet + dialer |
| 10D-5 Freelance, Messagerie, Profil | Écrans freelance, chat, profil, hub | Architecture A validée | Murs invités | Fusion data | Vide freelance, mur invité |
| 10D-6 A11y et perf | Labels, Reduce Motion, ordre des fetchs | Phases UI figées | Text scale, TalkBack, profile | Optimiser avant de mesurer | Profile release, pas de note avant |
| 10D-7 QA visuelle | Aucun nouvel écran | 10D-2 à 10D-6 | 320 / 360 / 393, scale 1.0 et 1.3 | Signer sans capture | Captures masquées |

### D. Décisions Sidney

Validées en 10D-1. Aucune ne reste ouverte. Voir la liste en tête de document. Non exécutées sur les écrans dans cette phase.

---

## Verdict

`UX_BLUEPRINT_READY_FOR_APPROVAL`

Le plan est décidable. Il n’est pas une validation visuelle : les captures d’écrans critiques restent un prérequis de 10D-2, pas un trou de ce document. Aucune implémentation n’est commencée.
