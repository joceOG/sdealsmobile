# SOUTRALI DEALS — MOBILE SCREEN DESIGN INVENTORY
### Audit complet des écrans et interactions Flutter · sdealsmobile

> **Date d'audit :** 4 octobre 2026  
> **Périmètre :** `sdealsmobile/lib/` (158 fichiers Dart)  
> **Méthode :** Lecture directe des sources + recherches ciblées (rg)  
> **Statut :** LECTURE SEULE — aucun fichier applicatif modifié

---

## A. SYNTHÈSE

| Catégorie | Nombre |
|-----------|--------|
| Écrans actifs (référencés + accessibles) | **62** |
| Panneaux / Dialogues / Bottom Sheets | **18** |
| Écrans legacy / inutilisés / dupliqués | **7** |
| Modules avec callbacks vides `() {}` | **11 fichiers** (39 occurrences) |
| Modules avec TODO/FIXME | **5 fichiers** |
| Routes nommées go_router | **5** |
| Routes anonymes go_router | **14** |
| Écrans déjà couverts par maquettes Figma | **13** |
| Écrans à harmoniser / compléter / créer | **21 prioritaires** |

### Flux principaux confirmés
- **Splash → Onboarding → Login/Register → Home (4 onglets)**
- **Home → Métiers → DetailPage → ProviderProfileScreen**
- **Home → Freelance → FreelanceDetailsScreen → Offres/Portfolio**
- **Home → É-marché → Produit → Panier → Confirmation (TODO paiement)**
- **Profil → showPublishOptions → Welcome[type] → Form[type] → Finalization**
- **Auth → `/providermain` → ProviderMainScreen (5 onglets prestataire)**

---

## B. INVENTAIRE COMPLET

### Navigation principale — Go Router (`main.dart`)

| Route | Nom | Écran | Auth requise | Notes |
|-------|-----|-------|-------------|-------|
| `/` | — | `SplashScreenM` | Non | Point d'entrée unique |
| `/homepage` | — | `Home` (shell 4 onglets) | Non | Shell client |
| `/onboarding` | — | `OnboardingScreen` | Non | Vu une seule fois |
| `/register` | — | `RegisterPageScreenM` | Non | — |
| `/login` | — | `LoginPageScreenM` | Non | — |
| `/serviceProviderWelcome` | — | `ServiceProviderWelcomeScreenM` | Oui | Reçoit `List<dynamic> categories` |
| `/freelanceWelcome` | — | `FreelanceWelcomeScreen` | Oui | — |
| `/emarketWelcome` | — | `EmarketWelcomeScreen` | Oui | — |
| `/serviceProviderRegistration` | — | `ServiceProviderRegistrationScreenM` | Oui | — |
| `/providermain` | `providermain` | `ProviderMainScreen` | Oui | Shell prestataire 5 onglets |
| `/prestataire-finalization` | `prestataire-finalization` | `PrestataireFinalizationScreen` | Oui | Reçoit `String? prestataireId` |
| `/vendeurDetails` | `vendeurDetails` | `VendorDetailsScreenM` | Non | Reçoit `Vendeur` |
| `/wallet` | — | `WalletPageScreenM` | Oui | Placeholder "bientôt" |
| `/wallet/profile` | — | `WalletPageScreenM` | Oui | Même écran que `/wallet` |
| `/mission-details/:missionId` | `mission-details` | Scaffold inline | Oui | **PLACEHOLDER** → redirige `/providermain` |
| `/chat/:conversationId` | `chat` | `ChatPageScreenM` | Oui | Deep-link FCM |

---

### B.1 — Shell client : Home (4 onglets)

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| E01 | Shell | `Home` | `mobile/view/home.dart` | `/homepage` (go_router) | — | ✅ ACTIF | Redirect auto PRESTATAIRE → /providermain (CONFIRMÉ) |
| E02 | Accueil | `HomePageScreenM` | `homepagem/screens/homePageScreenM.dart` | Onglet 0 | ✅ Maquette #8 | ✅ ACTIF | Section hero + pros validée |
| E03 | Explorer | `ExplorerPageScreen` | `explorer/screens/explorer_page_screen.dart` | Onglet 1 | ✅ Maquettes #1, #2 | ✅ ACTIF | Callbacks vides à corriger |
| E04 | Messagerie | `ChatPageScreenM` | `chatpagem/screens/chatPageScreenM.dart` | Onglet 2 + `/chat/:id` | — | ⚠️ PARTIEL | 2× `onTap: () {}`, 1× `onPressed: () {}` |
| E05 | Profil | `ProfilPageScreenM` | `profilpagem/screens/profilPageScreenM.dart` | Onglet 3 | — | ✅ ACTIF | Voir détails section B.9 |

---

### B.2 — Accueil

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| E06 | Accueil | `SearchPageScreenM` | `searchpagem/screens/searchPageScreenM.dart` | Tap barre recherche accueil/explorer | — | ✅ ACTIF | Multi-univers (Métiers/Freelance/É-marché) |
| E07 | Accueil | `LocationPageScreenM` | `locationpagem/screens/locationPageScreenM.dart` | Tap "Modifier" ville | — | ✅ ACTIF | Géolocalisation GPS |
| E08 | Accueil | `AlertPageScreenM` | `alertpagem/screens/alertPageScreenM.dart` | Icône cloche + profil | — | ✅ ACTIF | Inbox réelle (filtres NON_LUE/ARCHIVÉE) |
| E09 | Accueil | `HomeNearbyCard` (widget) | `homepagem/widgets/home_nearby_card.dart` | Carrousel accueil | ✅ Maquette #8 (section pros) | ✅ ACTIF | — |
| E10 | Accueil | `HomeUniverseChoiceCard` (widget) | `homepagem/widgets/home_universe_choice_card.dart` | Hero accueil | ✅ Maquette #8 | ✅ ACTIF | É-marché derrière `ClientFeatureFlags.emarketEnabled` |

**Widgets legacy accueil (callbacks vides — non utilisés dans le shell actuel) :**
- `homepagem/widgets/category_grid.dart` L72 `onPressed: () {}`, L96 `onTap: () {}` → **LEGACY**
- `homepagem/widgets/popular_services.dart` L24 `onPressed: () {}` → **LEGACY**
- `homepagem/widgets/featured_products.dart` L24 `onPressed: () {}` → **LEGACY**
- `homepagem/widgets/promotion_carousel.dart` → **LEGACY** (non utilisé dans homePageScreenM actuel)

---

### B.3 — Explorer

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| E11 | Explorer | `ExplorerPageScreen` (liste) | `explorer/screens/explorer_page_screen.dart` | Onglet 1 | ✅ Maquettes #1, #2 | ✅ ACTIF | Filtres univers, carrousels multi-sources |
| E12 | Explorer | `ExplorerMetiersMapPanel` | `explorer/widgets/explorer_metiers_map_panel.dart` | Bascule "Carte" | ✅ Maquette #1 (carte) | ✅ ACTIF | Markers avatar+prix, mini-fiche bottom |
| E13 | Explorer | `_FreelanceCategoryPage` (inline) | `explorer/screens/explorer_page_screen.dart:2563` | Tap service Freelance raccourci | — | ✅ ACTIF | Limitation : filtre catégorie seulement (pas service exact) |

**Mini-fiche carte (bottom sheet inline) :**
- `_ExplorerMiniProviderCard` : boutons "Contacter" et "Voir profil" → les deux appellent `NavigationHelper.navigateToProviderProfile()` — **DOUBLON** (même action sur deux CTA différents)

---

### B.4 — Métiers

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| E14 | Métiers | `JobPageScreenM` | `jobpagem/screens/jobPageScreenM.dart` | HomeUniverseCard / Explorer | ✅ Maquette #1 | ✅ ACTIF | Vue liste + vue carte. Géo + markers |
| E15 | Métiers | `ProviderProfileScreen` | `jobpagem/screens/provider_profile_screen.dart` | Tap prestataire | ✅ Maquette #7 | ✅ ACTIF | 3 onglets: Présentation/Portfolio/Avis |
| E16 | Métiers | `DetailPage` | `jobpagem/screens/detailPageScreenM.dart` | Tap service raccourci | — | ✅ ACTIF | Liste prestataires filtrés par service. Map mode |
| E17 | Métiers | `CategoriesListScreen` | `jobpagem/screens/categories_list_screen.dart` | Navigation interne JobPage | — | À CONFIRMER VISUELLEMENT | — |
| E18 | Métiers | `CategoryServicesScreen` | `jobpagem/screens/category_services_screen.dart` | Navigation interne JobPage | — | À CONFIRMER VISUELLEMENT | — |
| E19 | Métiers | `ProvidersListScreen` | `jobpagem/screens/providers_list_screen.dart` | Navigation interne JobPage | — | À CONFIRMER VISUELLEMENT | — |
| E20 | Métiers | `ServicesListScreen` | `jobpagem/screens/services_list_screen.dart` | Navigation interne JobPage | — | À CONFIRMER VISUELLEMENT | — |
| E21 | Métiers | `FullMapScreenM` | `jobpagem/screens/fullMapScreenM.dart` | Bouton carte plein écran | — | À CONFIRMER VISUELLEMENT | — |
| E22 | Métiers | `ServiceRequestSheet` (BS) | `jobpagem/widgets/service_request_sheet.dart` | CTA "Demander" | — | ✅ ACTIF | showModalBottomSheet dans provider_profile + detail_page |

**Widgets legacy Métiers (callbacks vides) :**
- `jobpagem/widgets/category_grid.dart` L72 `onPressed: () {}`, L96 `onTap: () {}` → **LEGACY**
- `jobpagem/widgets/popular_services.dart` L24 `onPressed: () {}` → **LEGACY**
- `jobpagem/widgets/featured_products.dart` L24 `onPressed: () {}` → **LEGACY**
- `jobpagem/screens/jobPageScreenM_.dart` — **FICHIER LEGACY** (version avec underscore, 6 callbacks vides)

---

### B.5 — Freelance

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| E23 | Freelance | `FreelancePageScreen` | `freelancepagem/screens/freelancePageScreen.dart` | HomeUniverseCard / Explorer | ✅ Maquettes #3, #4, #5 | ⚠️ PARTIEL | 2× `onTap: () {}` (L1227, L1233) |
| E24 | Freelance | `FreelanceDetailsScreen` | `freelancepagem/screens/freelance_details_screen.dart` | Tap carte freelance | ✅ Maquette #6 | ⚠️ PARTIEL | 2× `onTap: () {}` (L743, L921) + 2× `onPressed: () {}` (L133, L138) |
| E25 | Freelance | `FreelanceServiceOfferDetailScreen` | `freelancepagem/screens/freelance_service_offer_detail_screen.dart` | Depuis fiche freelance onglet offres | ✅ Maquette #11 | ⚠️ PARTIEL | 1× `onPressed: () {}` (L533) — CTA "Contacter pour cette offre" vide |
| E26 | Freelance | `PortfolioDetailScreen` | `freelancepagem/screens/portfolio_detail_screen.dart` | Tap réalisation | ✅ Maquette #10 | ⚠️ PARTIEL | 1× `onPressed: () {}` (L195) — "Partage futur" commentaire |

---

### B.6 — É-marché (derrière `ClientFeatureFlags.emarketEnabled`)

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| E27 | É-marché | `ShoppingPageScreenM` | `shoppingpagem/screens/shoppingPageScreenM.dart` | HomeUniverseCard / Explorer | — | ✅ ACTIF | Feature flaggé |
| E28 | É-marché | `ProductDetailsScreenM` | `shoppingpagem/screens/productDetailsScreenM.dart` | Tap produit | — | ✅ ACTIF | showModalBottomSheet pour ajouter au panier |
| E29 | É-marché | `VendorDetailsScreenM` | `shoppingpagem/screens/vendorDetailsScreenM.dart` | `/vendeurDetails` (go_router) ou tap boutique | — | ✅ ACTIF | — |
| E30 | É-marché | `PanierProductScreenM` | `shoppingpagem/screens/panierProductScreenM.dart` | Icône panier | — | ✅ ACTIF | — |
| E31 | É-marché | `ConfirmationCommandeScreen` | `shoppingpagem/screens/confirmationCommandeScreenM.dart` | Depuis panier | — | ⚠️ PARTIEL | **TODO L60 : "Pour le moment, pas de paiement intégré"** |
| E32 | É-marché | `DeliveryAddressScreen` | `shoppingpagem/screens/delivery_address_screen.dart` | Depuis panier/confirmation | — | À CONFIRMER VISUELLEMENT | — |

---

### B.7 — Messagerie

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| E33 | Messagerie | `ChatPageScreenM` (inbox) | `chatpagem/screens/chatPageScreenM.dart` | Onglet 2 + `/chat/:id` | — | ⚠️ PARTIEL | Filtres Tous/Travaux/Freelance/Produits. 2× `onTap: () {}` (L1605, L1770), 1× `onPressed: () {}` (L453) |
| E34 | Messagerie | Thread de conversation (inline) | `chatpagem/screens/chatPageScreenM.dart` | Tap conversation | — | ✅ ACTIF | Envoi texte + image + voice. WebSocket |

**Widgets messagerie :**
- `chatpagem/widgets/message_bubble.dart` — bulles de messages
- `chatpagem/widgets/voice_recorder_widget.dart` — enregistrement vocal
- `chatpagem/widgets/audio_bubble_widget.dart` — lecture audio

---

### B.8 — Profil client

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| E35 | Profil | `ProfilPageScreenM` | `profilpagem/screens/profilPageScreenM.dart` | Onglet 3 | — | ✅ ACTIF | Invité → GuestAuthState. Connecté → 12 items menu |
| E36 | Profil | `EditProfileScreen` | `profilpagem/screens/edit_profile_screen.dart` | Tap photo/nom profil | — | À CONFIRMER VISUELLEMENT | — |
| E37 | Profil | `FavoritePageScreenM` | `favorispagem/screens/favorite_page_screen_m.dart` | Menu "Favoris" | — | ✅ ACTIF | Filtres Tous/Métiers/Freelance/Marketplace |
| E38 | Profil | `AvisPageScreenM` | `avispagem/screens/avisPageScreenM.dart` | Menu "Avis et évaluations" | — | ✅ ACTIF | 2 onglets : Donnés / Reçus |
| E39 | Profil | `HistoryPageScreenM` | `historypagem/screens/historyPageScreenM.dart` | Menu "Historique" | — | ✅ ACTIF | 2 onglets : Annonces / Recherches récentes (local storage) |
| E40 | Profil | `AlertPageScreenM` | `alertpagem/screens/alertPageScreenM.dart` | Menu "Notifications" + cloche accueil | — | ✅ ACTIF | — |
| E41 | Profil | `ProfileSettingsHubScreen` | `profilpagem/screens/profile_settings_hub_screen.dart` | Menu "Paramètres" | — | À CONFIRMER VISUELLEMENT | Hub vers sous-paramètres |
| E42 | Profil | `SecurityPageScreenM` | `securitypagem/screens/securityPageScreenM.dart` | Via ProfileSettingsHub | — | ⚠️ PARTIEL | 1× `onTap: null` — PIN/biométrie absents backend. Comment: "Pas de PIN / biométrie" |
| E43 | Profil | `LanguageSettingsScreen` | `profilpagem/screens/language_settings_screen.dart` | Via ProfileSettingsHub | — | À CONFIRMER VISUELLEMENT | — |
| E44 | Profil | `HelpSupportScreen` | `profilpagem/screens/help_support_screen.dart` | Menu "Aide & support" | — | À CONFIRMER VISUELLEMENT | — |
| E45 | Profil | `AboutScreen` | `profilpagem/screens/about_screen.dart` | Menu "À propos" | — | À CONFIRMER VISUELLEMENT | — |
| E46 | Profil | `DeleteAccountScreen` | `profilpagem/screens/delete_account_screen.dart` | Via ProfileSettingsHub | — | À CONFIRMER VISUELLEMENT | Destructif — confirmation nécessaire |
| E47 | Profil | `ServiceRequestsListScreen` | `orderpagem/screens/service_requests_list_screen.dart` | Menu "Mes commandes" | — | À CONFIRMER VISUELLEMENT | — |
| E48 | Profil | `LocationPageScreenM` | `locationpagem/screens/locationPageScreenM.dart` | Menu "Localisation" + accueil/explorer | — | À CONFIRMER VISUELLEMENT | — |

**Sous-écrans Alertes :**
- `alertpagem/screens/alertDetailScreenM.dart` — détail alerte (showDialog confirm suppression)
- `alertpagem/screens/alertSettingsScreenM.dart` — préférences notifications
- `alertpagem/screens/createAlertScreenM.dart` — créer une alerte

**Sous-écrans Favoris :**
- `favorispagem/screens/favoriteDetailScreenM.dart` — détail favori (showDialog)
- `favorispagem/screens/addFavoriteScreenM.dart` — ajouter un favori (TODO dans ce fichier)

**Sous-écrans Avis :**
- `avispagem/screens/avisDetailScreenM.dart` — détail avis (showDialog)
- `avispagem/screens/createAvisScreenM.dart` — créer un avis

**Sous-écrans Sécurité :**
- `securitypagem/screens/securityDetailScreenM.dart` — détail session (showDialog)
- `securitypagem/screens/securitySettingsScreenM.dart` — paramètres sécurité (showDialog)
- `securitypagem/screens/twoFactorSetupScreenM.dart` — configuration 2FA

**Sous-écrans Historique :**
- `historypagem/screens/historyDetailScreenM.dart` — détail entrée (showDialog)

**Sous-écrans Commandes :**
- `orderpagem/screens/orderPageScreenM.dart`
- `orderpagem/screens/commande_details_screen.dart` — showDialog
- `orderpagem/screens/service_request_summary_screen.dart` — TODO présent
- `orderpagem/screens/service_requests_list_screen.dart`

---

### B.9 — Wallet / SoutraPay

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| E49 | Wallet | `WalletPageScreenM` | `walletpagem/screens/walletPageScreenM.dart` | `/wallet` | — | ⚠️ PLACEHOLDER | Affiche "SoutraPay arrive bientôt". Auth requise |
| E50 | Wallet | `SoutraWalletMainScreen` | `walletpagem/screens/soutraWalletMainScreen.dart` | Non référencé dans go_router actif | — | ⚠️ MOCK/FICTIF | **Données hardcodées** (balance = 125 000 FCFA fictif, transactions mock). NE PAS EXPOSER |
| E51 | Wallet | `SoutraPayActivationScreen` | `walletpagem/screens/soutraPayActivationScreen.dart` | ? | — | À CONFIRMER | — |
| E52 | Wallet | `SoutraRechargeScreen` | `walletpagem/screens/soutraRechargeScreen.dart` | Depuis soutraWalletMainScreen | — | ⚠️ MOCK | — |
| E53 | Wallet | `SoutraRechargeConfirmationScreen` | `walletpagem/screens/soutraRechargeConfirmationScreen.dart` | Depuis recharge | — | ⚠️ MOCK | showDialog confirm |
| E54 | Wallet | `SoutraTransferScreen` | `walletpagem/screens/soutraTransferScreen.dart` | Depuis wallet | — | ⚠️ MOCK | showModalBottomSheet |

---

### B.10 — Inscription professionnelle

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| E55 | Inscription | `showPublishOptions` (BS) | `common/publish_options.dart` | Menu profil "Publier" + bouton accueil | ✅ Maquette #13 | ✅ ACTIF | Bottom sheet choix Prestataire/Freelance/Vendeur. Auth gate |
| E56 | Inscription Prestataire | `ServiceProviderWelcomeScreenM` | `serviceproviderwelcomepagem/screens/serviceProviderWelcomeScreenM.dart` | `/serviceProviderWelcome` | — | ✅ ACTIF | — |
| E57 | Inscription Prestataire | `ServiceProviderRegistrationScreenM` | `serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart` | `/serviceProviderRegistration` | — | ✅ ACTIF | Multi-étapes : personal_info, professional_info (BLoC), activity_details, pricing |
| E58 | Inscription Freelance | `FreelanceWelcomeScreen` | `freelance_registration/screens/freelance_welcome_screen.dart` | `/freelanceWelcome` | — | ✅ ACTIF | → `FreelanceFormScreen` |
| E59 | Inscription Freelance | `FreelanceFormScreen` (stepper) | `freelance_registration/screens/freelance_form_screen.dart` | FreelanceWelcomeScreen | — | ✅ ACTIF | 6 étapes : personal_info, professional_info, portfolio, pricing, availability, verification |
| E60 | Inscription Vendeur | `EmarketWelcomeScreen` | `seller_registration/screens/emarket_welcome_screen.dart` | `/emarketWelcome` | — | ✅ ACTIF | → `SellerFormScreen` |
| E61 | Inscription Vendeur | `SellerFormScreen` (stepper) | `seller_registration/screens/seller_form_screen.dart` | EmarketWelcomeScreen | — | ✅ ACTIF | showDialog confirm. 5 étapes : personal_info, shop_info, products, payment, verification |
| E62 | Finalisation | `PrestataireFinalizationScreen` | `provider_dashboard/screens/prestataire_finalization_screen.dart` | `/prestataire-finalization` | — | ✅ ACTIF | Validation dossier prestataire. Reçoit `prestataireId` |

---

### B.11 — Dashboard Prestataire (`/providermain`)

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| P01 | Provider | `ProviderMainScreen` | `provider_dashboard/screens/provider_main_screen.dart` | `/providermain` (auth + rôle PRESTATAIRE) | — | ✅ ACTIF | Shell 5 onglets prestataire |
| P02 | Provider | `ProviderHomeDashboard` (widget) | `provider_dashboard/widgets/provider_home_dashboard.dart` | Onglet 0 | — | ✅ ACTIF | Stats réelles + missions récentes + avis + SoutraPay solde |
| P03 | Provider | `ProviderMissionsScreen` | `provider_dashboard/screens/provider_missions_screen.dart` | Onglet 1 | — | ⚠️ PARTIEL | 2× `onPressed: () {}` (L987, L1019) |
| P04 | Provider | `ProviderPlanningScreen` | `provider_dashboard/screens/provider_planning_screen.dart` | Onglet 2 | — | À CONFIRMER VISUELLEMENT | showModalBottomSheet |
| P05 | Provider | `ProviderMessagesScreen` | `provider_dashboard/screens/provider_messages_screen.dart` | Onglet 3 | — | À CONFIRMER VISUELLEMENT | showModalBottomSheet |
| P06 | Provider | `ProviderProfileScreen` (prestataire) | `provider_dashboard/screens/provider_profile_screen.dart` | Onglet 4 | — | À CONFIRMER VISUELLEMENT | showDialog |
| P07 | Provider | `ProviderStatisticsScreen` | `provider_dashboard/screens/provider_statistics_screen.dart` | Via dashboard onOpenStats | — | À CONFIRMER VISUELLEMENT | showModalBottomSheet |
| P08 | Provider | `ProviderNotificationsScreen` | `provider_dashboard/screens/provider_notifications_screen.dart` | Cloche dashboard | — | À CONFIRMER VISUELLEMENT | showDialog |
| P09 | Provider | `ProviderSettingsScreen` | `provider_dashboard/screens/provider_settings_screen.dart` | Via dashboard | — | À CONFIRMER VISUELLEMENT | showDialog |
| P10 | Provider | `ProviderSoutrapayScreen` | `provider_dashboard/screens/provider_soutrapay_screen.dart` | Via dashboard onOpenPayments / onWithdraw | — | À CONFIRMER VISUELLEMENT | showDialog |
| P11 | Provider | `ProviderDashboardScreen` (legacy) | `provider_dashboard/screens/provider_dashboard_screen.dart` | Potentiellement remplacé par `ProviderHomeDashboard` | — | ⚠️ LEGACY ? | Utilise `ProviderDashboardBloc` séparé. À vérifier si encore référencé |

**Widgets dashboard :**
- `provider_dashboard/widgets/ai_insights_widget.dart` — insights IA
- `provider_dashboard/widgets/dashboard_stat_card.dart` — cartes stats
- `provider_dashboard/widgets/mission_list_item.dart` — item mission

---

### B.12 — Authentification

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| A01 | Auth | `SplashScreenM` | `splashcreenm/screens/splashScreenM.dart` | `/` | — | ✅ ACTIF | Lottie overlay. Décide dest. via SplashscreenBlocM |
| A02 | Auth | `OnboardingScreen` | `onboarding/onboarding_screen.dart` | `/onboarding` (première ouverture) | — | ✅ ACTIF | Vu une seule fois |
| A03 | Auth | `LoginPageScreenM` | `loginpagem/screens/loginPageScreenM.dart` | `/login` + profil invité | — | ✅ ACTIF | Phone/Email + Google Sign-In. Redirect post-login |
| A04 | Auth | `RegisterPageScreenM` | `registerpagem/screens/registerPageScreenM.dart` | `/register` | — | ✅ ACTIF | Multi-step + OTP phone. Google Sign-In |

---

### B.13 — Autres écrans

| ID | Module | Écran | Fichier principal | Point d'entrée | Maquette existante | État | Travail restant |
|----|--------|-------|------------------|----------------|--------------------|------|-----------------|
| X01 | Legacy | `MorePageScreenM` | `morepagem/screens/morePageScreenM.dart` | Non référencé dans Home actuel | — | ❌ LEGACY | Drawer vide. 2× `onTap: () {}`, 1× `onPressed: () {}`. Non dans le shell |
| X02 | Legacy | `RondPageScreenM` | `rondpagem/screens/rondPageScreenM.dart` | Non référencé dans go_router | — | ❌ LEGACY | Nombreux callbacks vides |
| X03 | Legacy | `RondPageScreenMVO` | `rondpagem/screens/rondPageScreenMVO.dart` | Non référencé | — | ❌ LEGACY | Version VO, callbacks vides |
| X04 | Legacy | `JobPageScreenM_` | `jobpagem/screens/jobPageScreenM_.dart` | Non référencé (doublon avec `jobPageScreenM`) | — | ❌ LEGACY | Nombreux callbacks vides (6+) |
| X05 | Legacy | `SoutraWalletMainScreen` | `walletpagem/screens/soutraWalletMainScreen.dart` | Non dans go_router actif | — | ❌ NE PAS EXPOSER | Données mock hardcodées |
| X06 | Divers | `AIAssistantChatScreen` | `common/screens/ai_assistant_chat_screen.dart` | Non référencé dans shell | — | À CONFIRMER | Services AI mock (interfaces + mocks) |
| X07 | Divers | `NotificationScreen` | `notificationpagem/screens/notification_screen.dart` | Non référencé dans go_router | — | À CONFIRMER | Différent de AlertPageScreenM |
| X08 | Divers | `PreferencesPageScreenM` | `preferencespagem/screens/preferencesPageScreenM.dart` | Non référencé clairement | — | À CONFIRMER | — |

---

## C. MATRICE DES INTERACTIONS — CALLBACKS VIDES ET PROBLÈMES

### C.1 — Callbacks vides `onTap: () {}` (BUG / MANQUE FONCTIONNEL)

| Écran source | Fichier:Ligne | Élément | Comportement actuel | Destination attendue | Criticité |
|-------------|--------------|---------|--------------------|--------------------|-----------|
| `FreelanceDetailsScreen` | `freelance_details_screen.dart:743` | Élément liste (onglet Présentation) | Aucun effet | Action non définie (filtre ? tag ?) | ⚠️ P1 |
| `FreelanceDetailsScreen` | `freelance_details_screen.dart:921` | Élément avis | Aucun effet | Action sur avis (utile ?) | ⚠️ P2 |
| `FreelancePageScreen` | `freelancePageScreen.dart:1227` | Élément de liste (catégorie?) | Aucun effet | Filtrer ou naviguer | ⚠️ P1 |
| `FreelancePageScreen` | `freelancePageScreen.dart:1233` | Élément de liste (catégorie?) | Aucun effet | Filtrer ou naviguer | ⚠️ P1 |
| `MorePageScreenM` | `morePageScreenM.dart:322` | Élément de menu | Aucun effet | Destination manquante | ❌ LEGACY |
| `MorePageScreenM` | `morePageScreenM.dart:394` | Élément de menu | Aucun effet | Destination manquante | ❌ LEGACY |
| `ChatPageScreenM` | `chatPageScreenM.dart:1605` | Action (recherche ? filtre ?) | Aucun effet | Fonctionnalité manquante | ⚠️ P1 |
| `ChatPageScreenM` | `chatPageScreenM.dart:1770` | Action (recherche ? filtre ?) | Aucun effet | Fonctionnalité manquante | ⚠️ P1 |
| `JobPageScreenM_` (legacy) | `jobPageScreenM_.dart:213,276,389,846,933,939` | Multiple | Aucun effet | N/A (fichier legacy) | ❌ LEGACY |
| `category_grid.dart` (home) | `homepagem/widgets/category_grid.dart:96` | Grille catégorie | Aucun effet | N/A (widget non utilisé) | ❌ LEGACY |
| `category_grid.dart` (job) | `jobpagem/widgets/category_grid.dart:96` | Grille catégorie | Aucun effet | N/A (widget non utilisé) | ❌ LEGACY |
| `RondPageScreenM` | `rondPageScreenM.dart:127,339` | Multiple | Aucun effet | N/A (page legacy) | ❌ LEGACY |
| `RondPageScreenMVO` | `rondPageScreenMVO.dart:44,271` | Multiple | Aucun effet | N/A (page legacy) | ❌ LEGACY |

### C.2 — Callbacks vides `onPressed: () {}` (BUG / MANQUE FONCTIONNEL)

| Écran source | Fichier:Ligne | Élément | Comportement actuel | Destination attendue | Criticité |
|-------------|--------------|---------|--------------------|--------------------|-----------|
| `FreelanceDetailsScreen` | `freelance_details_screen.dart:133` | Bouton CTA principal (onglet Présentation ?) | Aucun effet | Contact / Demande de service | 🔴 P0 |
| `FreelanceDetailsScreen` | `freelance_details_screen.dart:138` | Bouton CTA secondaire | Aucun effet | Contact / Demande de service | 🔴 P0 |
| `FreelanceServiceOfferDetailScreen` | `freelance_service_offer_detail_screen.dart:533` | CTA "Contacter pour cette offre" | Aucun effet | Ouvrir conversation → ChatPageScreenM | 🔴 P0 |
| `PortfolioDetailScreen` | `portfolio_detail_screen.dart:195` | Bouton "Partager" | Aucun effet | Partage natif (commentaire "partage futur") | ⚠️ P3 |
| `MorePageScreenM` | `morePageScreenM.dart:86` | Bouton dans drawer | Aucun effet | N/A (page legacy) | ❌ LEGACY |
| `ChatPageScreenM` | `chatPageScreenM.dart:453` | Bouton action | Aucun effet | Fonctionnalité manquante | ⚠️ P1 |
| `ProviderMissionsScreen` | `provider_missions_screen.dart:987` | Action mission | Aucun effet | Action sur mission prestataire | ⚠️ P1 |
| `ProviderMissionsScreen` | `provider_missions_screen.dart:1019` | Action mission | Aucun effet | Action sur mission prestataire | ⚠️ P1 |
| `JobPageScreenM_` (legacy) | `jobPageScreenM_.dart:182` | Bouton | Aucun effet | N/A (legacy) | ❌ LEGACY |
| `category_grid.dart` (home+job) | `*_grid.dart:72` | Bouton grille | Aucun effet | N/A (widgets non utilisés) | ❌ LEGACY |
| `popular_services.dart` (home+job) | `popular_services.dart:24` | Bouton | Aucun effet | N/A (widgets non utilisés) | ❌ LEGACY |
| `featured_products.dart` (home+job) | `featured_products.dart:24` | Bouton | Aucun effet | N/A (widgets non utilisés) | ❌ LEGACY |

### C.3 — `onTap: null` (désactivé)

| Écran source | Fichier:Ligne | Élément | Raison connue |
|-------------|--------------|---------|--------------|
| `SecurityPageScreenM` | `securityPageScreenM.dart` | Éléments PIN / Biométrie | Commentaire: "Pas de PIN / biométrie (absents backend)" |

### C.4 — TODO / FIXME critiques

| Fichier | Ligne | Contenu | Criticité |
|---------|-------|---------|-----------|
| `confirmationCommandeScreenM.dart` | 60 | `// TODO: Pour le moment, pas de paiement intégré` | 🔴 P0 — Parcours E-marché cassé en production |
| `portfolio_detail_screen.dart` | 195 | `onPressed: () {}, // partage futur` | ⚠️ P3 |
| `service_request_summary_screen.dart` | ? | TODO (fichier listé avec TODO) | ⚠️ P1 |
| `addFavoriteScreenM.dart` | ? | TODO (fichier listé) | ⚠️ P2 |
| `shoppingpagem/screens/confirmationCommandeScreenM.dart` | ? | placeholder (libellé recherche) | 🔴 P0 |

### C.5 — Destinations cassées / parcours incomplets

| Problème | Localisation | Impact |
|---------|-------------|--------|
| `/mission-details/:missionId` → Scaffold placeholder | `main.dart:268–303` | Deep-links FCM mission → juste un écran "voir mes missions". Pas de détail réel | 🔴 P0 |
| `SoutraWalletMainScreen` non exposé mais données mock existent | `walletpagem/screens/soutraWalletMainScreen.dart` | Si exposé, montre un solde fictif de 125 000 FCFA | 🔴 P0 (si exposé) |
| CTA "Contacter pour cette offre" vide | `freelance_service_offer_detail_screen.dart:533` | Utilisateur bloqué à la dernière étape du parcours Freelance | 🔴 P0 |
| CTA principal `FreelanceDetailsScreen` vides (L133, L138) | `freelance_details_screen.dart` | Contact/Demande impossible depuis la fiche Freelance | 🔴 P0 |
| Mini-fiche carte Explorer : "Contacter" et "Voir profil" → même action | `explorer_metiers_map_panel.dart:311–324` | Redondance UX, "Contacter" ne contacte pas | ⚠️ P1 |
| `ProviderDashboardScreen` possiblement legacy (non utilisé par `ProviderMainScreen`) | `provider_dashboard_screen.dart` | Double source de vérité, états divergents possibles | ⚠️ P2 |

---

## D. LISTE DES PROCHAINES MAQUETTES

| Priorité | Écran ou panneau | Statut | Pourquoi | Contenu nécessaire | Action principale | Inspiration interne | Dépendance |
|----------|-----------------|--------|---------|-------------------|------------------|--------------------|-----------| 
| **P0** | Détail mission prestataire (client) | À CRÉER — PARCOURS EXISTANT | Deep-link `/mission-details/:missionId` → placeholder. Parcours cassé | Titre mission, statut, date, prestataire, CTA gérer | Aller vers `/providermain` | `ProviderMissionsScreen` | API mission GET by ID |
| **P0** | CTA contact Freelance (fiche + offre) | À COMPLÉTER | `onPressed: () {}` sur les CTA principaux de FreelanceDetailsScreen et FreelanceServiceOfferDetailScreen | Bouton "Contacter" → ouvre conversation | `ChatPageScreenM` | `ProviderProfileScreen` CTA existants | ChatBlocM + conversationId |
| **P0** | Paiement E-marché (checkout) | À CRÉER — PARCOURS EXISTANT | TODO paiement dans ConfirmationCommandeScreen. Parcours bloqué | Récap panier, choix paiement Mobile Money/Wave/Cash, CTA confirmer | Déclencher paiement backend | `PanierProductScreenM` | API paiement |
| **P1** | Écran messagerie — filtres actifs + recherche | À COMPLÉTER | 2 callbacks vides dans ChatPageScreenM (L1605, L1770) — recherche conversation non implémentée | Barre de recherche active, filtre par univers fonctionnel | Filtrer la liste de conversations | `AlertPageScreenM` (même pattern) | ChatBlocM |
| **P1** | Actions missions prestataire | À COMPLÉTER | 2× `onPressed: () {}` dans ProviderMissionsScreen (L987, L1019). Prestataires ne peuvent pas agir sur missions | Accepter/Refuser/Terminer mission | Changer statut mission | `ServiceRequestSummaryScreen` | API PATCH mission |
| **P1** | Historique de consultation détaillé | À HARMONISER | `HistoryPageScreenM` actif mais visuellement non validé | 2 onglets Annonces/Recherches, cartes mini-profil | Retapper sur un historique → ré-ouvrir | `FavoritePageScreenM` (même pattern) | LocalStorageService |
| **P1** | `ServiceRequestsListScreen` (commandes client) | À HARMONISER | Accessible depuis profil "Mes commandes" mais visuellement non validé | Liste demandes service + statuts | Tap → `CommandeDetailsScreen` | `OrderPageScreenM` | API commandes |
| **P1** | Profil invité (state authentification) | À HARMONISER | `GuestAuthState` dans ProfilPageScreenM — état visuel non validé | Illustration + 2 CTA (Connexion / Inscription) | `context.push('/login')` | `UnauthenticatedBanner` | AuthCubit |
| **P2** | Hub paramètres profil | À HARMONISER | `ProfileSettingsHubScreen` visuellement non validé | Liste paramètres groupés (compte, sécurité, langue, notifications) | Naviguer vers sous-écrans | `ProfilPageScreenM` | — |
| **P2** | SoutraPay — écran d'attente / activation | À HARMONISER | `WalletPageScreenM` est un placeholder. L'encart SoutraPay du dashboard prestataire (solde) est déjà visible | Solde, transactions, boutons Recharger/Transférer (désactivés jusqu'à backend) | Afficher état "en cours de déploiement" clair | `ProviderHomeDashboard` solde section | API wallet |
| **P2** | Partage réalisation Freelance | À COMPLÉTER | `onPressed: () {}` (L195) — partage futur | Share natif système + URL partageable | `Share.share()` | `PortfolioDetailScreen` | — |
| **P2** | Onboarding screens | À CONFIRMER VISUELLEMENT | `OnboardingScreen` existant mais non audité visuellement | Slides présentation app, CTA s'inscrire | `context.go('/register')` | `FreelanceWelcomeScreen` structure | — |
| **P2** | Détail commande client | À HARMONISER | `CommandeDetailsScreen` accessible via historique mais visuellement non validé | Statuts, produits, livraison, actions | Suivre commande | `ConfirmationCommandeScreen` | API commande |
| **P3** | Page Aide & Support | À CONFIRMER VISUELLEMENT | `HelpSupportScreen` non audité visuellement | FAQ, contact support, liens légaux | Envoyer message support | `AboutScreen` | — |
| **P3** | Page À propos | À CONFIRMER VISUELLEMENT | `AboutScreen` non audité visuellement | Version app, mentions légales, CGU | Liens légaux | `SDLegalFooterLinks` widget | `legal_urls.dart` |
| **P3** | Suppression de compte | À CONFIRMER VISUELLEMENT | `DeleteAccountScreen` — flux destructif non audité | Confirmation 2 étapes, raison, mot de passe | API DELETE utilisateur | Dialogs sécurité | API DELETE /user |
| **P3** | 2FA Setup | À CONFIRMER VISUELLEMENT | `TwoFactorSetupScreenM` existant | QR code, code backup, activation | Activer 2FA | `SecurityPageScreenM` | Backend 2FA |
| **P3** | AI Assistant chat | OPTION PRODUIT | `AIAssistantChatScreen` existe avec interfaces AI mock | Interface chat bot, suggestions | Envoyer demande | `ChatPageScreenM` thread | AI backend |
| **P3** | Préférences utilisateur | À CONFIRMER | `PreferencesPageScreenM` — non référencé dans shell clairement | Préférences notifs, thème, langue | Sauvegarder préférences | `LanguageSettingsScreen` | `UserPreferences` model |
| **EXCLURE** | `RondPageScreenM` / `RondPageScreenMVO` | À EXCLURE | Pages sans usage clair, nombreux callbacks vides, non référencées | — | — | — | — |
| **EXCLURE** | `MorePageScreenM` | À EXCLURE | Remplacée par l'onglet Profil. Drawer vide | — | — | — | — |

---

## E. ORDRE DE RÉALISATION

### Lot 1 — Corrections bloquantes (parcours cassés)
*Objectif : aucun CTA mort visible de l'utilisateur*

1. **Contacter Freelance** → câbler `onPressed` sur FreelanceDetailsScreen L133/L138 + FreelanceServiceOfferDetailScreen L533 vers ChatPageScreenM
2. **Checkout E-marché** → concevoir l'écran de paiement (Mobile Money) et brancher le backend
3. **Détail mission prestataire** → remplacer le Scaffold placeholder `/mission-details/:id` par un vrai écran
4. **Actions missions prestataire** → câbler `onPressed: () {}` dans ProviderMissionsScreen L987/L1019
5. **Messagerie recherche** → implémenter les callbacks vides ChatPageScreenM L1605/L1770

### Lot 2 — Harmonisation des écrans actifs
*Objectif : cohérence visuelle validée sur tous les écrans existants*

6. ServiceRequestsListScreen / CommandeDetailsScreen
7. ProfileSettingsHubScreen + sous-écrans
8. SecurityPageScreenM (avec état désactivé cohérent)
9. HistoryPageScreenM
10. FavoritePageScreenM

### Lot 3 — Complétion du dashboard prestataire
11. ProviderMissionsScreen (design + actions)
12. ProviderPlanningScreen
13. ProviderStatisticsScreen
14. ProviderSoutrapayScreen (état attente)

### Lot 4 — Extensions produit
15. SoutraPay activation flow
16. AI Assistant
17. Onboarding screens
18. Partage réalisation

---

### ⭐ 5 PROCHAINES MAQUETTES PRIORITAIRES

| # | Maquette | Justification |
|---|---------|---------------|
| **1** | **CTA Contact Freelance (fiche + offre)** | `onPressed: () {}` sur le bouton principal de la fiche freelance (L133/L138) et de l'écran offre (L533). Le parcours découverte Freelance se termine sans contact possible — c'est le blocage le plus visible pour un utilisateur réel. |
| **2** | **Checkout E-marché — paiement intégré** | TODO explicite dans le code (`confirmationCommandeScreenM.dart:60`). L'utilisateur peut remplir un panier mais ne peut pas confirmer avec un paiement réel. Bloque toute conversion E-marché. |
| **3** | **Détail mission prestataire** | La route `/mission-details/:missionId` dans go_router pointe vers un Scaffold placeholder. Les notifications push FCM renvoient vers cet écran — tout prestataire notifié d'une nouvelle mission arrive sur une page vide. |
| **4** | **Messagerie — recherche + filtres fonctionnels** | 2 callbacks vides dans ChatPageScreenM. La messagerie est l'onglet 2 du shell principal (visible tout le temps). Les utilisateurs avec plusieurs conversations ne peuvent pas filtrer ni chercher. |
| **5** | **Actions missions prestataire** | 2× `onPressed: () {}` dans ProviderMissionsScreen (L987, L1019). Les prestataires voient leurs missions mais ne peuvent pas y répondre (Accepter/Refuser/Terminer). Bloque le cœur du flux prestataire. |

---

## F. LIMITES DE L'AUDIT

### Ce qui n'a pas pu être vérifié visuellement

1. **Rendu réel sur appareil** — L'audit est basé sur le code source. Les écrans marqués "À CONFIRMER VISUELLEMENT" n'ont pas été vus sur émulateur ou device.

2. **États chargement / erreur / vide** — Pour chaque écran, plusieurs états BLoC existent (loading, loaded, error, empty). Seul l'état principal a été audité. Les états alternatifs peuvent manquer de traitement visuel.

3. **Accessibilité** — Les `Semantics` sont présents sur les éléments critiques (vérifiés pour HomeNearbyCard, HomeUniverseChoiceCard, ExplorerChips) mais une passe d'accessibilité complète n'a pas été faite.

4. **Breakpoints tablet / grand écran** — `ResponsiveBuilder` est utilisé dans MyApp mais les widgets enfants ne sont pas tous adaptés pour les tablettes.

5. **Interactions gestuelles avancées** — Swipe pour supprimer, drag-and-drop, longPress — non testés systématiquement.

6. **Performance listes longues** — Les `ListView.builder` / `GridView.builder` ont des skeleton loaders, mais la performance réelle avec beaucoup de données API n'a pas été mesurée.

7. **Comportement offline / dégradé** — L'application gère les erreurs réseau (bannières inline, messages retry), mais la persistance locale (Hive) et le comportement offline complet n'ont pas été audités.

8. **Tests automatisés** — Aucun dossier `test/` audité. La couverture de tests des BLoC est inconnue.

9. **Intégration Firebase / Crashlytics** — Les services FCM et Crashlytics sont initialisés en `no-op si non configuré`. L'intégration réelle n'a pas été vérifiée.

10. **Contenu des étapes d'inscription** (`steps/`)— Les sous-étapes des formulaires d'inscription (provider, freelance, seller) ont été inventoriées par nom de fichier mais leur contenu détaillé n'a pas été audité.

11. **`ProviderDashboardScreen` vs `ProviderHomeDashboard`** — La relation entre ces deux fichiers n'est pas entièrement claire. `ProviderHomeDashboard` semble être le composant actif (utilisé par `ProviderMainScreen`), mais `ProviderDashboardScreen` pourrait être une version de transition.

12. **Données AI mock** — Les interfaces `ai_services/` et leurs mock implementations n'ont pas été auditées en détail. `AIAssistantChatScreen` pourrait utiliser ces mocks en production si non switchée vers de vrais endpoints.

---

*Audit réalisé par analyse statique du code source. Conforme aux contraintes : aucun fichier applicatif modifié.*
