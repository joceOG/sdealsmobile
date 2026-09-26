# PHASE 10C-0C — Clôture stricte de l’inventaire client

Application : `com.sdealsmobile.app` / dossier `sdealsmobile` / branche `jordan` / commit de référence `1c4bf7158a03d78f3b71619fbe189caf1c91a15c`.
Ce fichier remplace les versions 10C-0 et 10C-0B du même chemin. Aucun autre rapport. Aucun code Flutter modifié.

Statuts de preuve utilisés : `PROVED_BY_CODE`, `ABSENT_BY_CODE`, `NOT_APPLICABLE`, `MANUAL_REQUIRED`, `UNRESOLVED_STATIC`. Le jeton générique précédent n’est plus employé.

## FILE et interface unique

Un fichier physique `FILE-xxx` reste unique et exclusif. Une **interface unique** est une surface visuelle ou comportementale comptée une fois même si elle est ouverte plusieurs fois. Une **occurrence** est un site d’ouverture qui pointe vers cette interface unique.

Le shell `lib/mobile/view/home.dart` et l’onboarding `lib/mobile/view/onboarding/onboarding_screen.dart` restent hors glob `screens/*.dart`.

## Formule des 84 fichiers

| Catégorie exclusive | Nombre |
| --- | ---: |
| 1 invité | 0 |
| 2 client | 25 |
| 3 partagé | 21 |
| 4 frontière prestataire | 3 |
| 5 prestataire hors périmètre | 12 |
| 6 orphelin | 19 |
| 7 legacy | 1 |
| 8 test/démonstration | 2 |
| 9 widget mal placé | 1 |
| **Somme** | **84** |

Contrôle : `0 + 25 + 21 + 3 + 12 + 19 + 1 + 2 + 1 = 84`.
## Réconciliation occurrences / interfaces uniques

Les totaux d’occurrences reprennent le dénombrement global de `lib/` (commentaires exclus). Une occurrence orpheline est un appel dont la méthode englobante n’est jamais appelée, ou un fichier jamais importé. Hors périmètre = dashboard prestataire, legacy, démonstration.

| Type | Occurrences code | Interfaces uniques | Dans le périmètre client | Hors périmètre | Orphelines |
| --- | ---: | ---: | ---: | ---: | ---: |
| Écrans `screens/*.dart` | 84 | 84 | 49 | 12 | 23 |
| Shell hors glob | 1 | 1 | 1 | 0 | 0 |
| Onboarding hors glob | 1 | 1 | 1 | 0 | 0 |
| Bottom sheets | 22 | 22 | 12 | 4 | 6 |
| Dialogues | 51 | 50 | 29 | 13 | 8 |
| PageView | 4 | 4 | 3 | 1 | 0 |
| Drawers | 2 | 2 | 0 | 1 | 1 |
| Murs d’authentification | 3 | 2 | 2 | 0 | 0 |
| Overlays/popups | 2 | 2 | 2 | 0 | 0 |
| Étapes conditionnelles | 3 | 3 | 3 | 0 | 0 |

Murs : `GuestAuthState` dans `profilPageScreenM.dart` et `chatPageScreenM.dart` (même classe, deux interfaces uniques car contenu et parent différents), plus `showGuestAuthSheet` compté comme sheet et non comme troisième mur.
Étapes conditionnelles uniques : formulaire login, chargement login, mur invité versus contenu connecté (chat et profil). OTP et mot de passe oublié sont des interfaces propres, déjà dans les sheets et dialogues.

Contrôle sheets : chaque occurrence `showModalBottomSheet` a un identifiant unique. Nombre d’occurrences groupées = 22.
Contrôle dialogues : occurrences groupées = 51.

### Bottom sheets — occurrence vers interface unique

| Occurrence | Interface unique | Fichier:ligne | Portée | Retour |
| --- | --- | --- | --- | --- |
| `mobile/view/common/widgets/auth_form_widgets.dart:281` | `UI-SHEET-AUTH` | `mobile/view/common/widgets/auth_form_widgets.dart:281` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/chatpagem/screens/chatPageScreenM.dart:333` | `UI-SHEET-CHAT` | `mobile/view/chatpagem/screens/chatPageScreenM.dart:333` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/jobpagem/screens/detailPageScreenM.dart:1420` | `UI-SHEET-DETAIL-_openCheckoutSheet` | `mobile/view/jobpagem/screens/detailPageScreenM.dart:1420` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/jobpagem/screens/detailPageScreenM.dart:859` | `UI-SHEET-DETAIL-_openExtraFiltersSheet` | `mobile/view/jobpagem/screens/detailPageScreenM.dart:859` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/shoppingpagem/widgets/filter_bottom_sheet.dart:27` | `UI-SHEET-EMARKET` | `mobile/view/shoppingpagem/widgets/filter_bottom_sheet.dart:27` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/jobpagem/screens/jobPageScreenM.dart:812` | `UI-SHEET-JOB-_pickRadius` | `mobile/view/jobpagem/screens/jobPageScreenM.dart:812` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/jobpagem/screens/jobPageScreenM.dart:345` | `UI-SHEET-JOB-_showProviderDetailSheet` | `mobile/view/jobpagem/screens/jobPageScreenM.dart:345` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/loginpagem/screens/loginPageScreenM.dart:149` | `UI-SHEET-OTP` | `mobile/view/loginpagem/screens/loginPageScreenM.dart:149` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/shoppingpagem/screens/productDetailsScreenM.dart:504` | `UI-SHEET-PRODUCT` | `mobile/view/shoppingpagem/screens/productDetailsScreenM.dart:504` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/provider_dashboard/screens/provider_messages_screen.dart:82` | `UI-SHEET-PROVIDER-provider_messages_screen.dart-_showFilterSheet` | `mobile/view/provider_dashboard/screens/provider_messages_screen.dart:82` | hors | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/provider_dashboard/screens/provider_missions_screen.dart:312` | `UI-SHEET-PROVIDER-provider_missions_screen.dart-_showFilterSheet` | `mobile/view/provider_dashboard/screens/provider_missions_screen.dart:312` | hors | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/provider_dashboard/screens/provider_planning_screen.dart:119` | `UI-SHEET-PROVIDER-provider_planning_screen.dart-_showDisponibilitesSheet` | `mobile/view/provider_dashboard/screens/provider_planning_screen.dart:119` | hors | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/provider_dashboard/screens/provider_statistics_screen.dart:558` | `UI-SHEET-PROVIDER-provider_statistics_screen.dart-_showExportOptions` | `mobile/view/provider_dashboard/screens/provider_statistics_screen.dart:558` | hors | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/home.dart:326` | `UI-SHEET-PUBLISH` | `mobile/view/home.dart:326` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/jobpagem/widgets/service_request_sheet.dart:21` | `UI-SHEET-REQUEST` | `mobile/view/jobpagem/widgets/service_request_sheet.dart:21` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/rondpagem/screens/rondPageScreenM.dart:638` | `UI-SHEET-ROND-rondPageScreenM.dart` | `mobile/view/rondpagem/screens/rondPageScreenM.dart:638` | orpheline | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/rondpagem/screens/rondPageScreenMVO.dart:588` | `UI-SHEET-ROND-rondPageScreenMVO.dart` | `mobile/view/rondpagem/screens/rondPageScreenMVO.dart:588` | orpheline | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/searchpagem/screens/searchPageScreenM.dart:298` | `UI-SHEET-SEARCH` | `mobile/view/searchpagem/screens/searchPageScreenM.dart:298` | client | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/profilpagem/screens/profilPageScreenM.dart:47` | `UI-SHEET-SOUTRAPAY` | `mobile/view/profilpagem/screens/profilPageScreenM.dart:47` | orpheline | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/walletpagem/screens/soutraRechargeScreen.dart:250` | `UI-SHEET-WALLET-soutraRechargeScreen.dart-_showPaymentMethodBottomSheet` | `mobile/view/walletpagem/screens/soutraRechargeScreen.dart:250` | orpheline | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/walletpagem/screens/soutraTransferScreen.dart:304` | `UI-SHEET-WALLET-soutraTransferScreen.dart-_showReceiverSelectionModal` | `mobile/view/walletpagem/screens/soutraTransferScreen.dart:304` | orpheline | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |
| `mobile/view/walletpagem/screens/soutraWalletMainScreen.dart:397` | `UI-SHEET-WALLET-soutraWalletMainScreen.dart-_showQRCodeSheet` | `mobile/view/walletpagem/screens/soutraWalletMainScreen.dart:397` | orpheline | fermeture modal, `PROVED_BY_CODE` (pas de valeur lue hors OTP) |

### Dialogues — occurrence vers interface unique

| Occurrence | Interface unique | Portée | Retour |
| --- | --- | --- | --- |
| `mobile/view/common/screens/ai_assistant_chat_screen.dart:92` | `UI-DLG-ai_assistant_chat_screen.dart-Aide-Assistant-IA` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/alertpagem/screens/alertDetailScreenM.dart:528` | `UI-DLG-alertDetailScreenM.dart-Archiver-l-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/alertpagem/screens/alertDetailScreenM.dart:556` | `UI-DLG-alertDetailScreenM.dart-Supprimer-l-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/avispagem/screens/avisDetailScreenM.dart:550` | `UI-DLG-avisDetailScreenM.dart-Modifier-l-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/avispagem/screens/avisDetailScreenM.dart:685` | `UI-DLG-avisDetailScreenM.dart-R-pondre-l-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/avispagem/screens/avisDetailScreenM.dart:653` | `UI-DLG-avisDetailScreenM.dart-Signaler-cet-avis` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/avispagem/screens/avisDetailScreenM.dart:626` | `UI-DLG-avisDetailScreenM.dart-Supprimer-l-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/avispagem/screens/avisPageScreenM.dart:535` | `UI-DLG-avisPageScreenM.dart-Supprimer-l-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/orderpagem/screens/commande_details_screen.dart:233` | `UI-DLG-commande_details_screen.dart-Annuler-la-commande` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/jobpagem/screens/detailPageScreenM.dart:1829` | `UI-DLG-detailPageScreenM.dart-Envoi-en-cours-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/jobpagem/screens/detailPageScreenM.dart:1296` | `UI-DLG-detailPageScreenM.dart-Signaler-le-service` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/favorispagem/screens/favoriteDetailScreenM.dart:501` | `UI-DLG-favoriteDetailScreenM.dart-Archiver-le-favori` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/favorispagem/screens/favoriteDetailScreenM.dart:444` | `UI-DLG-favoriteDetailScreenM.dart-Modifier-le-favori` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/favorispagem/screens/favoriteDetailScreenM.dart:530` | `UI-DLG-favoriteDetailScreenM.dart-Supprimer-le-favori` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/favorispagem/screens/favorite_page_screen_m.dart:467` | `UI-DLG-favorite_page_screen_m.dart-Retirer-des-favoris` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/freelance_registration/screens/freelance_form_screen.dart:124` | `UI-DLG-freelance_form_screen.dart-Confirmation` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/freelance_registration/screens/freelance_registration_screen.dart:390` | `UI-DLG-freelance_registration_screen.dart-Conditions-pour-devenir-freelance` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/historypagem/screens/historyDetailScreenM.dart:578` | `UI-DLG-historyDetailScreenM.dart-Archiver-la-consultation` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/historypagem/screens/historyDetailScreenM.dart:608` | `UI-DLG-historyDetailScreenM.dart-Supprimer-la-consultation` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/historypagem/screens/historyPageScreenM.dart:662` | `UI-DLG-historyPageScreenM.dart-Effacer-les-recherches` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/historypagem/screens/historyPageScreenM.dart:634` | `UI-DLG-historyPageScreenM.dart-Supprimer` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/loginpagem/screens/loginPageScreenM.dart:504` | `UI-DLG-loginPageScreenM.dart-R-initialiser-le-mot-de-passe` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/notificationpagem/screens/notification_screen.dart:384` | `UI-DLG-notification_screen.dart-Supprimer-cette-notification-` | orpheline | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/notificationpagem/screens/notification_screen.dart:435` | `UI-DLG-notification_screen.dart-Supprimer-cette-notification-` | orpheline | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/orderpagem/screens/orderPageScreenM.dart:401` | `UI-DLG-orderPageScreenM.dart-Noter-cette-commande` | orpheline | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/shoppingpagem/screens/panierProductScreenM.dart:266` | `UI-DLG-panierProductScreenM.dart-Retirer-l-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/shoppingpagem/screens/panierProductScreenM.dart:50` | `UI-DLG-panierProductScreenM.dart-Vider-le-panier` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/freelance_registration/screens/steps/portfolio_step.dart:63` | `UI-DLG-portfolio_step.dart-portfolioItems` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/profilpagem/screens/profilPageScreenM.dart:398` | `UI-DLG-profilPageScreenM.dart-Se-d-connecter` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:1390` | `UI-DLG-provider_main_screen.dart-D-connexion` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:1436` | `UI-DLG-provider_main_screen.dart-SoutraPay-arrive-bient-t` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/provider_dashboard/screens/provider_notifications_screen.dart:865` | `UI-DLG-provider_notifications_screen.dart-Supprimer-la-notification` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/provider_dashboard/screens/provider_planning_screen.dart:1250` | `UI-DLG-provider_planning_screen.dart-Ajouter-un-cr-neau` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/provider_dashboard/screens/provider_profile_screen.dart:88` | `UI-DLG-provider_profile_screen.dart-Modifier-le-profil` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/jobpagem/screens/provider_profile_screen.dart:1266` | `UI-DLG-provider_profile_screen.dart-Signaler-ce-prestataire` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/provider_dashboard/screens/provider_settings_screen.dart:698` | `UI-DLG-provider_settings_screen.dart-Changer-le-mot-de-passe` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/provider_dashboard/screens/provider_settings_screen.dart:624` | `UI-DLG-provider_settings_screen.dart-D-sactiver-l-` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/provider_dashboard/screens/provider_settings_screen.dart:658` | `UI-DLG-provider_settings_screen.dart-Supprimer-le-compte-` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/provider_dashboard/screens/provider_soutrapay_screen.dart:984` | `UI-DLG-provider_soutrapay_screen.dart-Demander-un-retrait` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/securitypagem/screens/securityDetailScreenM.dart:358` | `UI-DLG-securityDetailScreenM.dart-Supprimer-l-` | orpheline | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/securitypagem/screens/securityPageScreenM.dart:519` | `UI-DLG-securityPageScreenM.dart-Effacer-l-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/securitypagem/screens/securitySettingsScreenM.dart:106` | `UI-DLG-securitySettingsScreenM.dart-Export-s-curit-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/seller_registration/screens/seller_form_screen.dart:140` | `UI-DLG-seller_form_screen.dart-F-licitations-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/seller_registration/screens/seller_registration_screen.dart:488` | `UI-DLG-seller_registration_screen.dart-Frais-et-conditions` | hors | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/jobpagem/widgets/service_request_sheet.dart:146` | `UI-DLG-service_request_sheet.dart-Envoi-en-cours-` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/orderpagem/screens/service_request_summary_screen.dart:498` | `UI-DLG-service_request_summary_screen.dart-Annuler-la-commande` | client | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart:797` | `UI-DLG-shoppingPageScreenM.dart-Comparer-les-produits` | orpheline | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/walletpagem/screens/soutraRechargeConfirmationScreen.dart:241` | `UI-DLG-soutraRechargeConfirmationScreen.dart-Rechargement-r-ussi-` | orpheline | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/walletpagem/screens/soutraRechargeConfirmationScreen.dart:216` | `UI-DLG-soutraRechargeConfirmationScreen.dart-Traitement-en-cours-` | orpheline | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/walletpagem/screens/soutraTransferScreen.dart:412` | `UI-DLG-soutraTransferScreen.dart-Confirmer-le-transfert` | orpheline | fermeture modal, `PROVED_BY_CODE` |
| `mobile/view/walletpagem/screens/soutraTransferScreen.dart:485` | `UI-DLG-soutraTransferScreen.dart-Transfert-r-ussi-` | orpheline | fermeture modal, `PROVED_BY_CODE` |

### PageView

| Occurrence | Interface unique | Portée |
| --- | --- | --- |
| `mobile/view/homepagem/widgets/promotion_carousel.dart:57` | `UI-PV-promotion_carousel` | client |
| `mobile/view/jobpagem/widgets/promotion_carousel.dart:57` | `UI-PV-promotion_carousel` | client |
| `mobile/view/onboarding/onboarding_screen.dart:100` | `UI-PV-onboarding_screen` | client |
| `mobile/view/provider_dashboard/screens/prestataire_finalization_screen.dart:104` | `UI-PV-prestataire_finalization_screen` | hors périmètre |

### Drawers

- `mobile/view/morepagem/screens/morePageScreenM.dart:39` : `Drawer(` . `RondPageScreenM` n’est importé par aucun fichier. `MorePageScreenM` n’est importé par aucun fichier. Portée : orpheline / hors graphe client. `PROVED_BY_CODE`.
- `mobile/view/rondpagem/screens/rondPageScreenM.dart:42` : `Drawer(` . `RondPageScreenM` n’est importé par aucun fichier. `MorePageScreenM` n’est importé par aucun fichier. Portée : orpheline / hors graphe client. `PROVED_BY_CODE`.

## Graphe client accessible

Point de départ : routes `/`, `/onboarding`, `/homepage`, `/login`, `/register`, welcomes, `/vendeurDetails`, `/wallet`, `/chat`, plus les classes instanciées depuis ces fichiers via import résolu. Les routes `/providermain`, `/prestataire-finalization` et `/mission-details` sont des sorties vers l’espace prestataire : l’arête est notée, les navigations internes du dashboard ne sont pas comptées.

| Mesure | Global `lib/` | Périmètre invité/client accessible |
| --- | ---: | ---: |
| GoRoute | 16 | 13 |
| context.go | 13 | 9 |
| context.push | 51 | 37 |
| Navigator.push | 40 | 24 |
| Navigator.of.push | 63 | 57 |
| Navigator.pushNamed | 2 | 0 |
| Bottom sheets | 22 | 12 |
| Dialogues | 51 | 29 |
| Fichiers atteints par le graphe | 323 dart | 74 |

Les 13 routes du graphe excluent `/providermain`, `/prestataire-finalization`, `/mission-details`. Les 16 routes globales restent listées en annexe.

Fichiers atteints : **74**.

## Classes homonymes

### `JobPageScreenM`

| Appelant | Import exact | Classe instanciée | Fichier réellement ciblé | Statut |
| --- | --- | --- | --- | --- |
| `mobile/view/explorer/screens/explorer_page_screen.dart` | `import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';` | `JobPageScreenM` | `mobile/view/jobpagem/screens/jobPageScreenM.dart` | PROVED_BY_CODE |
| `mobile/view/explorer/widgets/explorer_metiers_map_panel.dart` | `import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';` | `JobPageScreenM` | `mobile/view/jobpagem/screens/jobPageScreenM.dart` | PROVED_BY_CODE |
| `mobile/view/homepagem/screens/homePageScreenM.dart` | `import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';` | `JobPageScreenM` | `mobile/view/jobpagem/screens/jobPageScreenM.dart` | PROVED_BY_CODE |

Imports de `jobPageScreenM_.dart` : **0**. `ABSENT_BY_CODE` : aucun fichier n’importe la variante underscore. Elle n’est donc pas accessible.

### `ProviderProfileScreen`

| Appelant | Import exact | Classe instanciée | Fichier réellement ciblé | Statut |
| --- | --- | --- | --- | --- |
| `mobile/view/explorer/screens/explorer_page_screen.dart` | `import 'package:sdealsmobile/mobile/view/jobpagem/screens/provider_profile_screen.dart';` | `ProviderProfileScreen` | `mobile/view/jobpagem/screens/provider_profile_screen.dart` | PROVED_BY_CODE |
| `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `import 'package:sdealsmobile/mobile/view/jobpagem/screens/provider_profile_screen.dart';` | `ProviderProfileScreen` | `mobile/view/jobpagem/screens/provider_profile_screen.dart` | PROVED_BY_CODE |
| `mobile/view/jobpagem/utils/navigation_helper.dart` | `import '../screens/provider_profile_screen.dart';` | `ProviderProfileScreen` | `mobile/view/jobpagem/screens/provider_profile_screen.dart` | PROVED_BY_CODE |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart` | `import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_profile_screen.dart';` | `ProviderProfileScreen` | `mobile/view/provider_dashboard/screens/provider_profile_screen.dart` | PROVED_BY_CODE |
| `mobile/view/searchpagem/screens/searchPageScreenM.dart` | `import '../../jobpagem/screens/provider_profile_screen.dart';` | `ProviderProfileScreen` | `mobile/view/jobpagem/screens/provider_profile_screen.dart` | PROVED_BY_CODE |

Les deux fichiers définissent la même classe. Le dashboard n’importe que `provider_dashboard/screens/provider_profile_screen.dart`. Les appelants client n’importent que `jobpagem/screens/provider_profile_screen.dart`. Aucun alias. Homonymes résolus par import.

## Graphe de navigation du périmètre actif

`context.go` remplace la pile : conservation du contexte `ABSENT_BY_CODE` sauf si `extra` est passé. `context.push` et `Navigator.push` laissent un retour théorique par `pop`. La conservation visuelle du scroll au retour n’est affirmée que pour le parcours 12, qui reste appareil.

| ID | Interface source | Geste / site | Méthode | Destination exacte | Condition auth | Contexte transmis | Retour attendu | Preuve |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| G-001 | `mobile/view/home.dart` | `addPostFrameCallback` L73 | context.push | `/providermain` route | client, redirect `/login` si non authentifié (`main.dart` 141-159) | extra GoRouter si le littéral de la ligne contient `extra` | pop théorique disponible | PROVED_BY_CODE `mobile/view/home.dart:73` |
| G-002 | `mobile/view/home.dart` | `_showPublishOptions` L326 | showModalBottomSheet | `UI-SHEET-PUBLISH`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/home.dart:326` |
| G-003 | `mobile/view/home.dart` | `_openProviderPublishFlow` L441 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/home.dart:441` |
| G-004 | `mobile/view/home.dart` | `_openProviderPublishFlow` L448 | context.push | `/serviceProviderRegistration` route | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/home.dart:448` |
| G-005 | `mobile/view/home.dart` | `_openProviderPublishFlow` L456 | context.push | `/providermain` route | client, redirect `/login` si non authentifié (`main.dart` 141-159) | extra GoRouter si le littéral de la ligne contient `extra` | pop théorique disponible | PROVED_BY_CODE `mobile/view/home.dart:456` |
| G-006 | `mobile/view/home.dart` | `_openProviderPublishFlow` L466 | context.push | `/providermain` route | client, redirect `/login` si non authentifié (`main.dart` 141-159) | extra GoRouter si le littéral de la ligne contient `extra` | pop théorique disponible | PROVED_BY_CODE `mobile/view/home.dart:466` |
| G-007 | `mobile/view/home.dart` | `_openProviderPublishFlow` L471 | context.push | `/serviceProviderWelcome` route | partagé | extra GoRouter si le littéral de la ligne contient `extra` | pop théorique disponible | PROVED_BY_CODE `mobile/view/home.dart:471` |
| G-008 | `mobile/view/home.dart` | `_openFreelancePublishFlow` L477 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/home.dart:477` |
| G-009 | `mobile/view/home.dart` | `_openFreelancePublishFlow` L490 | Navigator.push | `FreelanceWelcomeScreen` mobile/view/freelance_registration/screens/freelance_welcome_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/home.dart:490` |
| G-010 | `mobile/view/home.dart` | `_openSellerPublishFlow` L501 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/home.dart:501` |
| G-011 | `mobile/view/home.dart` | `_openSellerPublishFlow` L514 | Navigator.push | `EmarketWelcomeScreen` mobile/view/seller_registration/screens/emarket_welcome_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/home.dart:514` |
| G-012 | `mobile/view/alertpagem/screens/alertDetailScreenM.dart` | `_archiveAlert` L528 | showDialog | `UI-DLG-alertDetailScreenM.dart-Archiver-l-` mobile/view/alertpagem/alertpageblocm/alertPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/alertpagem/screens/alertDetailScreenM.dart:528` |
| G-013 | `mobile/view/alertpagem/screens/alertDetailScreenM.dart` | `_deleteAlert` L556 | showDialog | `UI-DLG-alertDetailScreenM.dart-Supprimer-l-` mobile/view/alertpagem/alertpageblocm/alertPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/alertpagem/screens/alertDetailScreenM.dart:556` |
| G-014 | `mobile/view/alertpagem/screens/alertPageScreenM.dart` | `_buildTopBar` L102 | Navigator.of.push | `AlertPageBlocM` mobile/view/alertpagem/alertpageblocm/alertPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/alertpagem/screens/alertPageScreenM.dart:102` |
| G-015 | `mobile/view/alertpagem/screens/alertPageScreenM.dart` | `_buildAlertCard` L209 | Navigator.of.push | `AlertPageBlocM` mobile/view/alertpagem/alertpageblocm/alertPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/alertpagem/screens/alertPageScreenM.dart:209` |
| G-016 | `mobile/view/avispagem/screens/avisDetailScreenM.dart` | `_showEditDialog` L550 | showDialog | `UI-DLG-avisDetailScreenM.dart-Modifier-l-`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/avispagem/screens/avisDetailScreenM.dart:550` |
| G-017 | `mobile/view/avispagem/screens/avisDetailScreenM.dart` | `_showDeleteDialog` L626 | showDialog | `UI-DLG-avisDetailScreenM.dart-Supprimer-l-` mobile/view/avispagem/avispageblocm/avisPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/avispagem/screens/avisDetailScreenM.dart:626` |
| G-018 | `mobile/view/avispagem/screens/avisDetailScreenM.dart` | `_showReportDialog` L653 | showDialog | `UI-DLG-avisDetailScreenM.dart-Signaler-cet-avis` mobile/view/avispagem/avispageblocm/avisPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/avispagem/screens/avisDetailScreenM.dart:653` |
| G-019 | `mobile/view/avispagem/screens/avisDetailScreenM.dart` | `_showReplyDialog` L685 | showDialog | `UI-DLG-avisDetailScreenM.dart-R-pondre-l-` mobile/view/avispagem/avispageblocm/avisPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/avispagem/screens/avisDetailScreenM.dart:685` |
| G-020 | `mobile/view/avispagem/screens/avisPageScreenM.dart` | `_navigateToDetail` L524 | Navigator.of.push | `AvisPageBlocM` mobile/view/avispagem/avispageblocm/avisPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/avispagem/screens/avisPageScreenM.dart:524` |
| G-021 | `mobile/view/avispagem/screens/avisPageScreenM.dart` | `_showDeleteDialog` L535 | showDialog | `UI-DLG-avisPageScreenM.dart-Supprimer-l-` mobile/view/avispagem/avispageblocm/avisPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/avispagem/screens/avisPageScreenM.dart:535` |
| G-022 | `mobile/view/chatpagem/screens/chatPageScreenM.dart` | `_onComposeTap` L333 | showModalBottomSheet | `UI-SHEET-CHAT`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/chatpagem/screens/chatPageScreenM.dart:333` |
| G-023 | `mobile/view/chatpagem/screens/chatPageScreenM.dart` | `_onComposeTap` L374 | Navigator.of.push | `SearchPageScreenM` mobile/view/searchpagem/screens/searchPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/chatpagem/screens/chatPageScreenM.dart:374` |
| G-024 | `mobile/view/chatpagem/screens/chatPageScreenM.dart` | `_buildNotAuthenticatedScreen` L811 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/chatpagem/screens/chatPageScreenM.dart:811` |
| G-025 | `mobile/view/chatpagem/screens/chatPageScreenM.dart` | `_buildNotAuthenticatedScreen` L812 | context.push | `/register` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/chatpagem/screens/chatPageScreenM.dart:812` |
| G-026 | `mobile/view/common/widgets/auth_form_widgets.dart` | `showGuestAuthSheet` L281 | showModalBottomSheet | `UI-SHEET-AUTH`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/common/widgets/auth_form_widgets.dart:281` |
| G-027 | `mobile/view/common/widgets/auth_form_widgets.dart` | `showGuestAuthSheet` L324 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/common/widgets/auth_form_widgets.dart:324` |
| G-028 | `mobile/view/common/widgets/auth_form_widgets.dart` | `showGuestAuthSheet` L328 | context.push | `/register` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/common/widgets/auth_form_widgets.dart:328` |
| G-029 | `mobile/view/common/widgets/unauthenticated_banner.dart` | `build` L92 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/common/widgets/unauthenticated_banner.dart:92` |
| G-030 | `mobile/view/common/widgets/unauthenticated_banner.dart` | `build` L120 | context.push | `/register` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/common/widgets/unauthenticated_banner.dart:120` |
| G-031 | `mobile/view/explorer/screens/explorer_page_screen.dart` | `_openSearch` L91 | Navigator.of.push | `SearchPageScreenM` mobile/view/searchpagem/screens/searchPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/explorer/screens/explorer_page_screen.dart:91` |
| G-032 | `mobile/view/explorer/screens/explorer_page_screen.dart` | `_openMarketplace` L101 | Navigator.of.push | `ShoppingPageBlocM` mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/explorer/screens/explorer_page_screen.dart:101` |
| G-033 | `mobile/view/explorer/screens/explorer_page_screen.dart` | `_buildMetiersSection` L563 | Navigator.of.push | `JobPageScreenM` mobile/view/jobpagem/screens/jobPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/explorer/screens/explorer_page_screen.dart:563` |
| G-034 | `mobile/view/explorer/screens/explorer_page_screen.dart` | `_buildMetiersSection` L595 | Navigator.of.push | `JobPageScreenM` mobile/view/jobpagem/screens/jobPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/explorer/screens/explorer_page_screen.dart:595` |
| G-035 | `mobile/view/explorer/screens/explorer_page_screen.dart` | `_buildFreelanceSection` L633 | Navigator.of.push | `FreelancePageScreen` mobile/view/freelancepagem/screens/freelancePageScreen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/explorer/screens/explorer_page_screen.dart:633` |
| G-036 | `mobile/view/explorer/screens/explorer_page_screen.dart` | `_buildFreelanceSection` L668 | Navigator.of.push | `FreelancePageScreen` mobile/view/freelancepagem/screens/freelancePageScreen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/explorer/screens/explorer_page_screen.dart:668` |
| G-037 | `mobile/view/explorer/screens/explorer_page_screen.dart` | `build` L878 | Navigator.of.push | `ProviderProfileScreen` mobile/view/jobpagem/screens/provider_profile_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/explorer/screens/explorer_page_screen.dart:878` |
| G-038 | `mobile/view/explorer/screens/explorer_page_screen.dart` | `build` L982 | Navigator.of.push | `FreelanceDetailsScreen` mobile/view/freelancepagem/screens/freelance_details_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/explorer/screens/explorer_page_screen.dart:982` |
| G-039 | `mobile/view/explorer/screens/explorer_page_screen.dart` | `build` L1124 | Navigator.of.push | `ProductDetails` mobile/view/shoppingpagem/screens/productDetailsScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/explorer/screens/explorer_page_screen.dart:1124` |
| G-040 | `mobile/view/explorer/screens/explorer_page_screen.dart` | `build` L1215 | context.push | `/vendeurDetails` route | partagé | extra GoRouter si le littéral de la ligne contient `extra` | pop théorique disponible | PROVED_BY_CODE `mobile/view/explorer/screens/explorer_page_screen.dart:1215` |
| G-041 | `mobile/view/explorer/widgets/explorer_metiers_map_panel.dart` | `_openFullMetiers` L181 | Navigator.of.push | `JobPageScreenM` mobile/view/jobpagem/screens/jobPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/explorer/widgets/explorer_metiers_map_panel.dart:181` |
| G-042 | `mobile/view/favorispagem/screens/favoriteDetailScreenM.dart` | `_showEditDialog` L444 | showDialog | `UI-DLG-favoriteDetailScreenM.dart-Modifier-le-favori`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/favorispagem/screens/favoriteDetailScreenM.dart:444` |
| G-043 | `mobile/view/favorispagem/screens/favoriteDetailScreenM.dart` | `_showArchiveDialog` L501 | showDialog | `UI-DLG-favoriteDetailScreenM.dart-Archiver-le-favori` mobile/view/favorispagem/favorispageblocm/favoritePageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/favorispagem/screens/favoriteDetailScreenM.dart:501` |
| G-044 | `mobile/view/favorispagem/screens/favoriteDetailScreenM.dart` | `_showDeleteDialog` L530 | showDialog | `UI-DLG-favoriteDetailScreenM.dart-Supprimer-le-favori` mobile/view/favorispagem/favorispageblocm/favoritePageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/favorispagem/screens/favoriteDetailScreenM.dart:530` |
| G-045 | `mobile/view/favorispagem/screens/favorite_page_screen_m.dart` | `_navigateToDetail` L455 | Navigator.of.push | `FavoritePageBlocM` mobile/view/favorispagem/favorispageblocm/favoritePageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/favorispagem/screens/favorite_page_screen_m.dart:455` |
| G-046 | `mobile/view/favorispagem/screens/favorite_page_screen_m.dart` | `_showRemoveDialog` L467 | showDialog | `UI-DLG-favorite_page_screen_m.dart-Retirer-des-favoris` mobile/view/favorispagem/favorispageblocm/favoritePageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/favorispagem/screens/favorite_page_screen_m.dart:467` |
| G-047 | `mobile/view/freelancepagem/screens/freelancePageScreen.dart` | `openSearch` L199 | Navigator.of.push | `SearchPageScreenM` mobile/view/searchpagem/screens/searchPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/freelancepagem/screens/freelancePageScreen.dart:199` |
| G-048 | `mobile/view/freelancepagem/screens/freelancePageScreen.dart` | `_openSearchFreelance` L490 | Navigator.of.push | `SearchPageScreenM` mobile/view/searchpagem/screens/searchPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/freelancepagem/screens/freelancePageScreen.dart:490` |
| G-049 | `mobile/view/freelancepagem/screens/freelancePageScreen.dart` | `_openAllFreelancers` L502 | Navigator.of.push | `FilterByCategoryEvent` mobile/view/freelancepagem/freelancepageblocm/freelancePageEventM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/freelancepagem/screens/freelancePageScreen.dart:502` |
| G-050 | `mobile/view/freelancepagem/screens/freelancePageScreen.dart` | `_openCategory` L515 | Navigator.of.push | `ClearFiltersEvent` mobile/view/freelancepagem/freelancepageblocm/freelancePageEventM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/freelancepagem/screens/freelancePageScreen.dart:515` |
| G-051 | `mobile/view/freelancepagem/screens/freelancePageScreen.dart` | `build` L657 | Navigator.of.push | `FreelanceDetailsScreen` mobile/view/freelancepagem/screens/freelance_details_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/freelancepagem/screens/freelancePageScreen.dart:657` |
| G-052 | `mobile/view/freelancepagem/screens/freelancePageScreen.dart` | `build` L778 | Navigator.of.push | `FreelanceDetailsScreen` mobile/view/freelancepagem/screens/freelance_details_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/freelancepagem/screens/freelancePageScreen.dart:778` |
| G-053 | `mobile/view/freelancepagem/screens/freelancePageScreen.dart` | `build` L859 | Navigator.of.push | `FreelanceDetailsScreen` mobile/view/freelancepagem/screens/freelance_details_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/freelancepagem/screens/freelancePageScreen.dart:859` |
| G-054 | `mobile/view/freelancepagem/screens/freelance_details_screen.dart` | `_contactFreelancer` L820 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/freelancepagem/screens/freelance_details_screen.dart:820` |
| G-055 | `mobile/view/freelancepagem/screens/freelance_details_screen.dart` | `_contactFreelancer` L848 | Navigator.of.push | `ChatPageBlocM` mobile/view/chatpagem/chatpageblocm/chatPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/freelancepagem/screens/freelance_details_screen.dart:848` |
| G-056 | `mobile/view/freelancepagem/screens/freelance_service_offer_detail_screen.dart` | `_openFreelanceProfile` L95 | Navigator.of.push | `FreelanceDetailsScreen` mobile/view/freelancepagem/screens/freelance_details_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/freelancepagem/screens/freelance_service_offer_detail_screen.dart:95` |
| G-057 | `mobile/view/freelance_registration/screens/freelance_form_screen.dart` | `_submitForm` L124 | showDialog | `UI-DLG-freelance_form_screen.dart-Confirmation`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/freelance_registration/screens/freelance_form_screen.dart:124` |
| G-058 | `mobile/view/freelance_registration/screens/freelance_welcome_screen.dart` | `_buildBottomCta` L224 | Navigator.of.push | `FreelanceFormScreen` mobile/view/freelance_registration/screens/freelance_form_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/freelance_registration/screens/freelance_welcome_screen.dart:224` |
| G-059 | `mobile/view/freelance_registration/screens/steps/portfolio_step.dart` | `_addProject` L63 | showDialog | `UI-DLG-portfolio_step.dart-portfolioItems` mobile/view/freelance_registration/screens/steps/portfolio_step.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/freelance_registration/screens/steps/portfolio_step.dart:63` |
| G-060 | `mobile/view/historypagem/screens/historyDetailScreenM.dart` | `_archiveHistory` L578 | showDialog | `UI-DLG-historyDetailScreenM.dart-Archiver-la-consultation` mobile/view/historypagem/historypageblocm/historyPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/historypagem/screens/historyDetailScreenM.dart:578` |
| G-061 | `mobile/view/historypagem/screens/historyDetailScreenM.dart` | `_deleteHistory` L608 | showDialog | `UI-DLG-historyDetailScreenM.dart-Supprimer-la-consultation` mobile/view/historypagem/historypageblocm/historyPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/historypagem/screens/historyDetailScreenM.dart:608` |
| G-062 | `mobile/view/historypagem/screens/historyPageScreenM.dart` | `_openDetail` L622 | Navigator.of.push | `HistoryPageBlocM` mobile/view/historypagem/historypageblocm/historyPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/historypagem/screens/historyPageScreenM.dart:622` |
| G-063 | `mobile/view/historypagem/screens/historyPageScreenM.dart` | `_confirmDelete` L634 | showDialog | `UI-DLG-historyPageScreenM.dart-Supprimer` mobile/view/historypagem/historypageblocm/historyPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/historypagem/screens/historyPageScreenM.dart:634` |
| G-064 | `mobile/view/historypagem/screens/historyPageScreenM.dart` | `_confirmClearSearches` L662 | showDialog | `UI-DLG-historyPageScreenM.dart-Effacer-les-recherches`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/historypagem/screens/historyPageScreenM.dart:662` |
| G-065 | `mobile/view/historypagem/screens/historyPageScreenM.dart` | `_openSearch` L691 | Navigator.of.push | `SearchPageScreenM` mobile/view/searchpagem/screens/searchPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/historypagem/screens/historyPageScreenM.dart:691` |
| G-066 | `mobile/view/homepagem/screens/homePageScreenM.dart` | `_openNotifications` L511 | Navigator.of.push | `AlertPageBlocM` mobile/view/alertpagem/alertpageblocm/alertPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/homepagem/screens/homePageScreenM.dart:511` |
| G-067 | `mobile/view/homepagem/screens/homePageScreenM.dart` | `_openOrders` L522 | Navigator.of.push | `ServiceRequestsListScreen` mobile/view/orderpagem/screens/service_requests_list_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/homepagem/screens/homePageScreenM.dart:522` |
| G-068 | `mobile/view/homepagem/screens/homePageScreenM.dart` | `_openMetiers` L568 | Navigator.of.push | `JobPageScreenM` mobile/view/jobpagem/screens/jobPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/homepagem/screens/homePageScreenM.dart:568` |
| G-069 | `mobile/view/homepagem/screens/homePageScreenM.dart` | `_openFreelance` L574 | Navigator.of.push | `FreelancePageScreen` mobile/view/freelancepagem/screens/freelancePageScreen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/homepagem/screens/homePageScreenM.dart:574` |
| G-070 | `mobile/view/homepagem/screens/homePageScreenM.dart` | `_openFreelanceServiceOffer` L582 | Navigator.of.push | `FreelanceServiceOfferDetailScreen` mobile/view/freelancepagem/screens/freelance_service_offer_detail_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/homepagem/screens/homePageScreenM.dart:582` |
| G-071 | `mobile/view/homepagem/screens/homePageScreenM.dart` | `_openFreelanceById` L595 | Navigator.of.push | `FreelanceDetailsScreen` mobile/view/freelancepagem/screens/freelance_details_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/homepagem/screens/homePageScreenM.dart:595` |
| G-072 | `mobile/view/homepagem/screens/homePageScreenM.dart` | `_openMarketplace` L611 | Navigator.of.push | `ShoppingPageBlocM` mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/homepagem/screens/homePageScreenM.dart:611` |
| G-073 | `mobile/view/homepagem/screens/homePageScreenM.dart` | `_openProductFromHome` L657 | Navigator.of.push | `ShoppingPageBlocM` mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/homepagem/screens/homePageScreenM.dart:657` |
| G-074 | `mobile/view/jobpagem/screens/categories_list_screen.dart` | `_buildCategoryCard` L187 | Navigator.push | `DetailPage` mobile/view/jobpagem/screens/detailPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/categories_list_screen.dart:187` |
| G-075 | `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `build` L243 | Navigator.push | `ProviderProfileScreen` mobile/view/jobpagem/screens/provider_profile_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/detailPageScreenM.dart:243` |
| G-076 | `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `_contactProvider` L818 | Navigator.push | `ProviderProfileScreen` mobile/view/jobpagem/screens/provider_profile_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/detailPageScreenM.dart:818` |
| G-077 | `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `_toggleProviderFavorite` L846 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/detailPageScreenM.dart:846` |
| G-078 | `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `_openExtraFiltersSheet` L859 | showModalBottomSheet | `UI-SHEET-DETAIL-_openExtraFiltersSheet`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/jobpagem/screens/detailPageScreenM.dart:859` |
| G-079 | `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `_buildProviderCard` L1010 | Navigator.push | `ProviderProfileScreen` mobile/view/jobpagem/screens/provider_profile_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/detailPageScreenM.dart:1010` |
| G-080 | `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `_buildProviderCard` L1234 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/detailPageScreenM.dart:1234` |
| G-081 | `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `_onReportTap` L1296 | showDialog | `UI-DLG-detailPageScreenM.dart-Signaler-le-service`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/jobpagem/screens/detailPageScreenM.dart:1296` |
| G-082 | `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `_buildStickyCta` L1403 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/detailPageScreenM.dart:1403` |
| G-083 | `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `_openCheckoutSheet` L1420 | showModalBottomSheet | `UI-SHEET-DETAIL-_openCheckoutSheet`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/jobpagem/screens/detailPageScreenM.dart:1420` |
| G-084 | `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `_openCheckoutSheet` L1829 | showDialog | `UI-DLG-detailPageScreenM.dart-Envoi-en-cours-`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/jobpagem/screens/detailPageScreenM.dart:1829` |
| G-085 | `mobile/view/jobpagem/screens/detailPageScreenM.dart` | `_openCheckoutSheet` L1887 | Navigator.push | `ServiceRequestSummaryScreen` mobile/view/orderpagem/screens/service_request_summary_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/detailPageScreenM.dart:1887` |
| G-086 | `mobile/view/jobpagem/screens/jobPageScreenM.dart` | `_showProviderDetailSheet` L345 | showModalBottomSheet | `UI-SHEET-JOB-_showProviderDetailSheet`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/jobpagem/screens/jobPageScreenM.dart:345` |
| G-087 | `mobile/view/jobpagem/screens/jobPageScreenM.dart` | `_requestService` L391 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/jobPageScreenM.dart:391` |
| G-088 | `mobile/view/jobpagem/screens/jobPageScreenM.dart` | `_buildSearchRow` L501 | Navigator.of.push | `SearchPageScreenM` mobile/view/searchpagem/screens/searchPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/jobPageScreenM.dart:501` |
| G-089 | `mobile/view/jobpagem/screens/jobPageScreenM.dart` | `_buildCategories` L578 | Navigator.of.push | `JobPageBlocM` mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/jobPageScreenM.dart:578` |
| G-090 | `mobile/view/jobpagem/screens/jobPageScreenM.dart` | `_pickRadius` L812 | showModalBottomSheet | `UI-SHEET-JOB-_pickRadius`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/jobpagem/screens/jobPageScreenM.dart:812` |
| G-091 | `mobile/view/jobpagem/screens/provider_profile_screen.dart` | `_openProviderFullMap` L837 | Navigator.push | `FullMapScreenM` mobile/view/jobpagem/screens/fullMapScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/provider_profile_screen.dart:837` |
| G-092 | `mobile/view/jobpagem/screens/provider_profile_screen.dart` | `_onToggleFavorite` L1220 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/provider_profile_screen.dart:1220` |
| G-093 | `mobile/view/jobpagem/screens/provider_profile_screen.dart` | `_onReportProfile` L1260 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/provider_profile_screen.dart:1260` |
| G-094 | `mobile/view/jobpagem/screens/provider_profile_screen.dart` | `_onReportProfile` L1266 | showDialog | `UI-DLG-provider_profile_screen.dart-Signaler-ce-prestataire`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/jobpagem/screens/provider_profile_screen.dart:1266` |
| G-095 | `mobile/view/jobpagem/screens/provider_profile_screen.dart` | `_onRequestService` L1349 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/screens/provider_profile_screen.dart:1349` |
| G-096 | `mobile/view/jobpagem/utils/navigation_helper.dart` | `build` L17 | Navigator.push | `ProviderProfileScreen` mobile/view/jobpagem/screens/provider_profile_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/utils/navigation_helper.dart:17` |
| G-097 | `mobile/view/jobpagem/utils/navigation_helper.dart` | `build` L39 | Navigator.push | `DetailPage` mobile/view/jobpagem/screens/detailPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/utils/navigation_helper.dart:39` |
| G-098 | `mobile/view/jobpagem/utils/navigation_helper.dart` | `build` L58 | Navigator.push | `DetailPage` mobile/view/jobpagem/screens/detailPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/utils/navigation_helper.dart:58` |
| G-099 | `mobile/view/jobpagem/widgets/service_request_sheet.dart` | `showServiceRequestSheet` L21 | showModalBottomSheet | `UI-SHEET-REQUEST` mobile/view/jobpagem/widgets/service_request_sheet.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/jobpagem/widgets/service_request_sheet.dart:21` |
| G-100 | `mobile/view/jobpagem/widgets/service_request_sheet.dart` | `warn` L146 | showDialog | `UI-DLG-service_request_sheet.dart-Envoi-en-cours-`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/jobpagem/widgets/service_request_sheet.dart:146` |
| G-101 | `mobile/view/jobpagem/widgets/service_request_sheet.dart` | `warn` L194 | Navigator.push | `ServiceRequestSummaryScreen` mobile/view/orderpagem/screens/service_request_summary_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/jobpagem/widgets/service_request_sheet.dart:194` |
| G-102 | `mobile/view/loginpagem/screens/loginPageScreenM.dart` | `_promptOptionalPhoneVerification` L149 | showModalBottomSheet | `UI-SHEET-OTP` mobile/view/loginpagem/loginpageblocm/loginPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/loginpagem/screens/loginPageScreenM.dart:149` |
| G-103 | `mobile/view/loginpagem/screens/loginPageScreenM.dart` | `_buildLoginForm` L454 | context.push | `/register` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/loginpagem/screens/loginPageScreenM.dart:454` |
| G-104 | `mobile/view/loginpagem/screens/loginPageScreenM.dart` | `_showForgotPasswordDialog` L504 | showDialog | `UI-DLG-loginPageScreenM.dart-R-initialiser-le-mot-de-passe`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/loginpagem/screens/loginPageScreenM.dart:504` |
| G-105 | `mobile/view/onboarding/onboarding_screen.dart` | `_completeOnboarding` L84 | context.go | `/homepage` route | partagé | aucun extra sur la ligne d’appel | pile remplacée, pas de pop vers la source | PROVED_BY_CODE `mobile/view/onboarding/onboarding_screen.dart:84` |
| G-106 | `mobile/view/orderpagem/screens/service_requests_list_screen.dart` | `build` L318 | Navigator.push | `ServiceRequestSummaryScreen` mobile/view/orderpagem/screens/service_request_summary_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/orderpagem/screens/service_requests_list_screen.dart:318` |
| G-107 | `mobile/view/orderpagem/screens/service_request_summary_screen.dart` | `_buildActionButtons` L450 | Navigator.push | `ChatPageScreenM` mobile/view/chatpagem/screens/chatPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/orderpagem/screens/service_request_summary_screen.dart:450` |
| G-108 | `mobile/view/orderpagem/screens/service_request_summary_screen.dart` | `_confirmAndCancel` L498 | showDialog | `UI-DLG-service_request_summary_screen.dart-Annuler-la-commande`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/orderpagem/screens/service_request_summary_screen.dart:498` |
| G-109 | `mobile/view/profilpagem/screens/delete_account_screen.dart` | `_submit` L45 | context.go | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pile remplacée, pas de pop vers la source | PROVED_BY_CODE `mobile/view/profilpagem/screens/delete_account_screen.dart:45` |
| G-110 | `mobile/view/profilpagem/screens/profile_settings_hub_screen.dart` | `build` L66 | Navigator.of.push | `PreferencesPageBlocM` mobile/view/preferencespagem/preferencespageblocm/preferencesPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profile_settings_hub_screen.dart:66` |
| G-111 | `mobile/view/profilpagem/screens/profile_settings_hub_screen.dart` | `build` L80 | Navigator.of.push | `PreferencesPageBlocM` mobile/view/preferencespagem/preferencespageblocm/preferencesPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profile_settings_hub_screen.dart:80` |
| G-112 | `mobile/view/profilpagem/screens/profile_settings_hub_screen.dart` | `build` L95 | Navigator.of.push | `SecurityPageBlocM` mobile/view/securitypagem/securitypageblocm/securityPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profile_settings_hub_screen.dart:95` |
| G-113 | `mobile/view/profilpagem/screens/profile_settings_hub_screen.dart` | `build` L120 | Navigator.of.push | `AlertPageBlocM` mobile/view/alertpagem/alertpageblocm/alertPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profile_settings_hub_screen.dart:120` |
| G-114 | `mobile/view/profilpagem/screens/profile_settings_hub_screen.dart` | `build` L135 | Navigator.of.push | `DeleteAccountScreen` mobile/view/profilpagem/screens/delete_account_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profile_settings_hub_screen.dart:135` |
| G-115 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `build` L111 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:111` |
| G-116 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `build` L112 | context.push | `/register` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:112` |
| G-117 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `build` L127 | Navigator.of.push | `ServiceRequestsListScreen` mobile/view/orderpagem/screens/service_requests_list_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:127` |
| G-118 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `build` L138 | Navigator.of.push | `FavoritePageBlocM` mobile/view/favorispagem/favorispageblocm/favoritePageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:138` |
| G-119 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `build` L152 | Navigator.of.push | `AvisPageBlocM` mobile/view/avispagem/avispageblocm/avisPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:152` |
| G-120 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `build` L166 | Navigator.of.push | `HistoryPageBlocM` mobile/view/historypagem/historypageblocm/historyPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:166` |
| G-121 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `build` L180 | Navigator.of.push | `AlertPageBlocM` mobile/view/alertpagem/alertpageblocm/alertPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:180` |
| G-122 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `build` L196 | Navigator.of.push | `ProfileSettingsHubScreen` mobile/view/profilpagem/screens/profile_settings_hub_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:196` |
| G-123 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `build` L207 | Navigator.of.push | `LocationPageBlocM` mobile/view/locationpagem/locationpageblocm/locationPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:207` |
| G-124 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `build` L221 | Navigator.of.push | `HelpSupportScreen` mobile/view/profilpagem/screens/help_support_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:221` |
| G-125 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `build` L232 | Navigator.of.push | `AboutScreen` mobile/view/profilpagem/screens/about_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:232` |
| G-126 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `_navigateToEditProfile` L374 | Navigator.push | `EditProfileScreen` mobile/view/profilpagem/screens/edit_profile_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:374` |
| G-127 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `_showLogoutDialog` L398 | showDialog | `UI-DLG-profilPageScreenM.dart-Se-d-connecter` literal | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:398` |
| G-128 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `_showLogoutDialog` L419 | context.go | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pile remplacée, pas de pop vers la source | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:419` |
| G-129 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `delayed` L459 | context.push | `/providermain` route | client, redirect `/login` si non authentifié (`main.dart` 141-159) | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:459` |
| G-130 | `mobile/view/profilpagem/screens/profilPageScreenM.dart` | `delayed` L462 | context.push | `/providermain` route | client, redirect `/login` si non authentifié (`main.dart` 141-159) | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/profilpagem/screens/profilPageScreenM.dart:462` |
| G-131 | `mobile/view/registerpagem/screens/registerPageScreenM.dart` | `_handleBack` L140 | context.go | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pile remplacée, pas de pop vers la source | PROVED_BY_CODE `mobile/view/registerpagem/screens/registerPageScreenM.dart:140` |
| G-132 | `mobile/view/registerpagem/screens/registerPageScreenM.dart` | `_signInWithGoogle` L194 | context.push | `/homepage` route | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/registerpagem/screens/registerPageScreenM.dart:194` |
| G-133 | `mobile/view/registerpagem/screens/registerPageScreenM.dart` | `_signInWithGoogle` L202 | context.go | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pile remplacée, pas de pop vers la source | PROVED_BY_CODE `mobile/view/registerpagem/screens/registerPageScreenM.dart:202` |
| G-134 | `mobile/view/registerpagem/screens/registerPageScreenM.dart` | `_signInWithGoogle` L207 | context.go | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pile remplacée, pas de pop vers la source | PROVED_BY_CODE `mobile/view/registerpagem/screens/registerPageScreenM.dart:207` |
| G-135 | `mobile/view/registerpagem/screens/registerPageScreenM.dart` | `addPostFrameCallback` L266 | context.push | `/homepage` route | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/registerpagem/screens/registerPageScreenM.dart:266` |
| G-136 | `mobile/view/registerpagem/screens/registerPageScreenM.dart` | `_buildFormStep` L419 | context.go | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pile remplacée, pas de pop vers la source | PROVED_BY_CODE `mobile/view/registerpagem/screens/registerPageScreenM.dart:419` |
| G-137 | `mobile/view/searchpagem/screens/searchPageScreenM.dart` | `_showFilterModal` L298 | showModalBottomSheet | `UI-SHEET-SEARCH`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/searchpagem/screens/searchPageScreenM.dart:298` |
| G-138 | `mobile/view/searchpagem/screens/searchPageScreenM.dart` | `_openVendor` L746 | Navigator.push | `VendorDetailsScreenM` mobile/view/shoppingpagem/screens/vendorDetailsScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/searchpagem/screens/searchPageScreenM.dart:746` |
| G-139 | `mobile/view/searchpagem/screens/searchPageScreenM.dart` | `_buildServiceCard` L877 | Navigator.push | `DetailPage` mobile/view/jobpagem/screens/detailPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/searchpagem/screens/searchPageScreenM.dart:877` |
| G-140 | `mobile/view/searchpagem/screens/searchPageScreenM.dart` | `_openSearchPerson` L900 | Navigator.push | `FreelanceDetailsScreen` mobile/view/freelancepagem/screens/freelance_details_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/searchpagem/screens/searchPageScreenM.dart:900` |
| G-141 | `mobile/view/searchpagem/screens/searchPageScreenM.dart` | `_openSearchPerson` L909 | Navigator.push | `ProviderProfileScreen` mobile/view/jobpagem/screens/provider_profile_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/searchpagem/screens/searchPageScreenM.dart:909` |
| G-142 | `mobile/view/searchpagem/screens/searchPageScreenM.dart` | `_buildArticleCard` L1026 | Navigator.push | `ShoppingPageBlocM` mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/searchpagem/screens/searchPageScreenM.dart:1026` |
| G-143 | `mobile/view/securitypagem/screens/securityPageScreenM.dart` | `_openWithBloc` L424 | Navigator.of.push | `argument child : SecuritySettingsScreenM (L198), TwoFactorSetupScreenM (L207 et L214), _HistorySubScreen (L243)`  | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/securitypagem/screens/securityPageScreenM.dart:424` |
| G-144 | `mobile/view/securitypagem/screens/securityPageScreenM.dart` | `build` L519 | showDialog | `UI-DLG-securityPageScreenM.dart-Effacer-l-` mobile/view/securitypagem/securitypageblocm/securityPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/securitypagem/screens/securityPageScreenM.dart:519` |
| G-145 | `mobile/view/securitypagem/screens/securitySettingsScreenM.dart` | `build` L106 | showDialog | `UI-DLG-securitySettingsScreenM.dart-Export-s-curit-`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/securitypagem/screens/securitySettingsScreenM.dart:106` |
| G-146 | `mobile/view/seller_registration/screens/emarket_welcome_screen.dart` | `_buildBottomCta` L222 | Navigator.of.push | `SellerFormScreen` mobile/view/seller_registration/screens/seller_form_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/seller_registration/screens/emarket_welcome_screen.dart:222` |
| G-147 | `mobile/view/seller_registration/screens/seller_form_screen.dart` | `_submitForm` L140 | showDialog | `UI-DLG-seller_form_screen.dart-F-licitations-`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/seller_registration/screens/seller_form_screen.dart:140` |
| G-148 | `mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart` | `_openProviderSpace` L230 | context.push | `/providermain` route | client, redirect `/login` si non authentifié (`main.dart` 141-159) | extra GoRouter si le littéral de la ligne contient `extra` | pop théorique disponible | PROVED_BY_CODE `mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart:230` |
| G-149 | `mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart` | `build` L281 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart:281` |
| G-150 | `mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart` | `build` L288 | context.push | `/register` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart:288` |
| G-151 | `mobile/view/shoppingpagem/screens/confirmationCommandeScreenM.dart` | `build` L331 | Navigator.push | `DeliveryAddressScreen` mobile/view/shoppingpagem/screens/delivery_address_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/confirmationCommandeScreenM.dart:331` |
| G-152 | `mobile/view/shoppingpagem/screens/confirmationCommandeScreenM.dart` | `build` L360 | Navigator.push | `DeliveryAddressScreen` mobile/view/shoppingpagem/screens/delivery_address_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/confirmationCommandeScreenM.dart:360` |
| G-153 | `mobile/view/shoppingpagem/screens/panierProductScreenM.dart` | `build` L50 | showDialog | `UI-DLG-panierProductScreenM.dart-Vider-le-panier` mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/panierProductScreenM.dart:50` |
| G-154 | `mobile/view/shoppingpagem/screens/panierProductScreenM.dart` | `build` L266 | showDialog | `UI-DLG-panierProductScreenM.dart-Retirer-l-` mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageEventM.dart | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/panierProductScreenM.dart:266` |
| G-155 | `mobile/view/shoppingpagem/screens/panierProductScreenM.dart` | `build` L561 | Navigator.push | `DeliveryAddressScreen` mobile/view/shoppingpagem/screens/delivery_address_screen.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/panierProductScreenM.dart:561` |
| G-156 | `mobile/view/shoppingpagem/screens/panierProductScreenM.dart` | `build` L640 | Navigator.push | `ConfirmationCommandeScreen` mobile/view/shoppingpagem/screens/confirmationCommandeScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/panierProductScreenM.dart:640` |
| G-157 | `mobile/view/shoppingpagem/screens/productDetailsScreenM.dart` | `_showGuestCartGate` L504 | showModalBottomSheet | `UI-SHEET-PRODUCT`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/productDetailsScreenM.dart:504` |
| G-158 | `mobile/view/shoppingpagem/screens/productDetailsScreenM.dart` | `_showGuestCartGate` L571 | context.push | `/login` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/productDetailsScreenM.dart:571` |
| G-159 | `mobile/view/shoppingpagem/screens/productDetailsScreenM.dart` | `_showGuestCartGate` L581 | context.push | `/register` route | invité, ou client redirigé vers `/homepage` si déjà authentifié | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/productDetailsScreenM.dart:581` |
| G-160 | `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart` | `_openSearchShop` L200 | Navigator.of.push | `SearchPageScreenM` mobile/view/searchpagem/screens/searchPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart:200` |
| G-161 | `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart` | `openSearch` L376 | Navigator.of.push | `SearchPageScreenM` mobile/view/searchpagem/screens/searchPageScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart:376` |
| G-162 | `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart` | `_buildVendeurCard` L1792 | context.push | `/vendeurDetails` route | partagé | extra GoRouter si le littéral de la ligne contient `extra` | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart:1792` |
| G-163 | `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart` | `build` L2062 | Navigator.of.push | `ProductDetails` mobile/view/shoppingpagem/screens/productDetailsScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart:2062` |
| G-164 | `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart` | `build` L2181 | context.push | `/vendeurDetails` route | partagé | extra GoRouter si le littéral de la ligne contient `extra` | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart:2181` |
| G-165 | `mobile/view/shoppingpagem/utils/cart_navigation.dart` | `openShoppingCart` L10 | Navigator.of.push | `PanierProductScreenM` mobile/view/shoppingpagem/screens/panierProductScreenM.dart | partagé | aucun extra sur la ligne d’appel | pop théorique disponible | PROVED_BY_CODE `mobile/view/shoppingpagem/utils/cart_navigation.dart:10` |
| G-166 | `mobile/view/shoppingpagem/widgets/filter_bottom_sheet.dart` | `build` L27 | showModalBottomSheet | `UI-SHEET-EMARKET`  | partagé | aucun extra sur la ligne d’appel | fermeture modal | PROVED_BY_CODE `mobile/view/shoppingpagem/widgets/filter_bottom_sheet.dart:27` |
| G-167 | `mobile/view/splashcreenm/screens/splashScreenM.dart` | `_tryNavigate` L129 | context.go | `variable dest = ready?.destination ?? '/homepage' (splashScreenM.dart:110)`  | partagé | extra GoRouter si le littéral de la ligne contient `extra` | pile remplacée, pas de pop vers la source | PROVED_BY_CODE `mobile/view/splashcreenm/screens/splashScreenM.dart:129` |
| G-168 | `mobile/view/splashcreenm/screens/splashScreenM.dart` | `_tryNavigate` L131 | context.go | `variable dest = ready?.destination ?? '/homepage' (splashScreenM.dart:110)`  | partagé | aucun extra sur la ligne d’appel | pile remplacée, pas de pop vers la source | PROVED_BY_CODE `mobile/view/splashcreenm/screens/splashScreenM.dart:131` |

Navigations du graphe actif : **168**.

## Interfaces attendues absentes

### UI-012 — Filtres Freelance

| Champ | Valeur |
| --- | --- |
| Besoin | Filtrer la liste freelance comme l’é-marché filtre ses produits. |
| Pourquoi recherchée | Cahier 10C-0B, liste obligatoire. |
| Recherche | `FilterBottomSheet` n’est appelé que depuis `shoppingPageScreenM.dart` ligne 1225. Aucun fichier `*filter*` sous `freelancepagem/`. Aucune classe `Filter` dans `freelance_details_screen.dart` ou `freelancePageScreen.dart` hors tri local. |
| Conclusion | ABSENT_BY_CODE |

### UI-026 — Écran permission localisation refusée

| Champ | Valeur |
| --- | --- |
| Besoin | Un écran dédié lorsque l’utilisateur refuse la localisation. |
| Pourquoi recherchée | Cahier 10C-0B. |
| Recherche | Aucune classe `Permission` sous `screens/`. Aucun `showDialog` dont le titre contient `permission` ou `localisation refus`. La carte métiers continue dans `jobPageScreenM.dart` / widgets carte. |
| Conclusion | ABSENT_BY_CODE |

Variante `service_request_sheet_integrated.dart` citée au passage précédent : recherche `integrated` dans les sheets, **0 fichier**. ABSENT_BY_CODE. Un seul sheet : `jobpagem/widgets/service_request_sheet.dart`.

## Fiches des interfaces actives

Périmètre : fichiers du graphe classés client, partagé ou frontière, plus shell et onboarding. Prestataire dashboard, orphelins, legacy et démos sont dans l’annexe, pas ici.

## SHELL-001 — Home

| Champ | Valeur |
| --- | --- |
| Identifiant | `SHELL-001` |
| Fichier et lignes | `lib/mobile/view/home.dart` classe ligne 23 |
| Classe | `Home` |
| Nom visible | Accueil ; Explorer ; Messagerie ; Profil ; Connectez-vous pour publier |
| Rôle | partagé |
| Point d’entrée | route GoRouter ou onglet du shell |
| CTA principal | _showPublishOptions L240 |
| Actions secondaires | callbacks : _showPublishOptions L240, Navigator L420, onTap L543 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, _chatBloc, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## FILE-HORS-001 — OnboardingScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `FILE-HORS-001` |
| Fichier et lignes | `lib/mobile/view/onboarding/onboarding_screen.dart` classe ligne 23 |
| Classe | `OnboardingScreen` |
| Nom visible | Trouvez tout\nprès de vous ; 300+ Métiers\nà votre service ; Plombiers, menuisiers, designers, développeurs... Trouvez l\ ; Achetez ce\nque vous voulez ; Un compte,\ntout les possibles |
| Rôle | invité |
| Point d’entrée | route GoRouter ou onglet du shell |
| CTA principal | Trouvez tout\nprès de vous |
| Actions secondaires | Trouvez tout\nprès de vous → `OnboardingContent` L36 ; 300+ Métiers\nà votre service → `OnboardingContent` L42 ; Achetez ce\nque vous voulez → `OnboardingContent` L48 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | ABSENT_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | PROVED_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | NOT_APPLICABLE |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-003 — AlertDetailScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-003` |
| Fichier et lignes | `lib/mobile/view/alertpagem/screens/alertDetailScreenM.dart` classe ligne 9 |
| Classe | `AlertDetailScreenM` |
| Nom visible | Archiver l\ ; Supprimer l\ ; Détails de l\ |
| Rôle | client |
| Point d’entrée | mobile/view/alertpagem/screens/alertPageScreenM.dart |
| CTA principal | Êtes-vous sûr de vouloir archiver cette alerte ? |
| Actions secondaires | Êtes-vous sûr de vouloir archiver cette alerte ? → `ArchiveAlertM` L535 ; Annuler → `ArchiveAlertM` L539 ; Êtes-vous sûr de vouloir supprimer cette alerte ? Cette action est irréversible. → `DeleteAlertM` L564 ; Annuler → `DeleteAlertM` L568 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatelessWidget |
| Loading | ABSENT_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-004 — AlertPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-004` |
| Fichier et lignes | `lib/mobile/view/alertpagem/screens/alertPageScreenM.dart` classe ligne 15 |
| Classe | `AlertPageScreenM` |
| Nom visible | Toutes (${total - archived}) ; Non lues ($unread) ; Archivées ($archived) |
| Rôle | client |
| Point d’entrée | mobile/view/homepagem/screens/homePageScreenM.dart, mobile/view/profilpagem/screens/profilPageScreenM.dart |
| CTA principal | Navigator L95 |
| Actions secondaires | callbacks : Navigator L95 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDErrorState |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-005 — AlertSettingsScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-005` |
| Fichier et lignes | `lib/mobile/view/alertpagem/screens/alertSettingsScreenM.dart` classe ligne 13 |
| Classe | `AlertSettingsScreenM` |
| Nom visible | Préférences de notification ; Email ; Notifications push ; SMS |
| Rôle | client |
| Point d’entrée | mobile/view/alertpagem/screens/alertPageScreenM.dart, mobile/view/profilpagem/screens/profile_settings_hub_screen.dart |
| CTA principal | _save L81 |
| Actions secondaires | callbacks : _save L81, onChanged L346 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | ABSENT_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-006 — AvisDetailScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-006` |
| Fichier et lignes | `lib/mobile/view/avispagem/screens/avisDetailScreenM.dart` classe ligne 10 |
| Classe | `AvisDetailScreenM` |
| Nom visible | Modifier l\ ; Supprimer l\ ; Signaler cet avis ; Répondre à l\ ; Détail de l\ |
| Rôle | client |
| Point d’entrée | mobile/view/avispagem/screens/avisPageScreenM.dart |
| CTA principal | Annuler |
| Actions secondaires | Annuler → `UpdateAvisM` L598 ; Êtes-vous sûr de vouloir supprimer cet avis ? → `DeleteAvisM` L633 ; Annuler → `DeleteAvisM` L637 ; Pourquoi souhaitez-vous signaler cet avis ? → `SignalerAvisM` L660 ; Annuler → `SignalerAvisM` L664 ; Annuler → `RepondreAvisM` L703 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | ABSENT_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-007 — AvisPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-007` |
| Fichier et lignes | `lib/mobile/view/avispagem/screens/avisPageScreenM.dart` classe ligne 13 |
| Classe | `AvisPageScreenM` |
| Nom visible | Supprimer l\ ; Donnés ($donnesCount) ; Reçus ($recusCount) |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| CTA principal | Êtes-vous sûr de vouloir supprimer cet avis ? |
| Actions secondaires | Êtes-vous sûr de vouloir supprimer cet avis ? → `DeleteAvisM` L542 ; Annuler → `DeleteAvisM` L546 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-008 — ChatPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-008` |
| Fichier et lignes | `lib/mobile/view/chatpagem/screens/chatPageScreenM.dart` classe ligne 21 |
| Classe | `ChatPageScreenM` |
| Nom visible | Tous ; Travaux ; Freelance ; Produits ; Messages ; Connectez-vous pour accéder à vos messages |
| Rôle | partagé |
| Point d’entrée | main.dart, mobile/view/home.dart, mobile/view/freelancepagem/screens/freelance_details_screen.dart, mobile/view/orderpagem/screens/service_request_summary_screen.dart |
| CTA principal | Connectez-vous pour accéder à vos messages |
| Actions secondaires | Connectez-vous pour accéder à vos messages → `/login` L807 ; Ouvrir la recherche → `SDAppBarIconThemed` L384 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, _chatBloc, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | GuestAuthState, SDAppBarIconThemed |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-009 — ExplorerPageScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-009` |
| Fichier et lignes | `lib/mobile/view/explorer/screens/explorer_page_screen.dart` classe ligne 42 |
| Classe | `ExplorerPageScreen` |
| Nom visible | Liste ; Carte ; Métiers ; Freelance ; Vente & Achat ; Plus |
| Rôle | partagé |
| Point d’entrée | mobile/view/home.dart |
| CTA principal | _openSearch L337 |
| Actions secondaires | callbacks : _openSearch L337, _selectUniverse L407, onSeeAll L504, onTap L825 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-010 — FavoriteDetailScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-010` |
| Fichier et lignes | `lib/mobile/view/favorispagem/screens/favoriteDetailScreenM.dart` classe ligne 9 |
| Classe | `FavoriteDetailScreenM` |
| Nom visible | Modifier le favori ; Archiver le favori ; Supprimer le favori ; Détail du Favori |
| Rôle | client |
| Point d’entrée | mobile/view/favorispagem/screens/favorite_page_screen_m.dart |
| CTA principal | Annuler |
| Actions secondaires | Annuler → `UpdateFavoriteM` L477 ; Êtes-vous sûr de vouloir archiver  → `ArchiveFavoriteM` L509 ; Annuler → `ArchiveFavoriteM` L513 ; Êtes-vous sûr de vouloir supprimer  → `DeleteFavoriteM` L538 ; Annuler → `DeleteFavoriteM` L542 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | ABSENT_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-011 — FavoritePageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-011` |
| Fichier et lignes | `lib/mobile/view/favorispagem/screens/favorite_page_screen_m.dart` classe ligne 15 |
| Classe | `FavoritePageScreenM` |
| Nom visible | Retirer des favoris ; Tous ; Métiers ; Freelance ; Vente & Achat ; Vos coups de cœur |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| CTA principal | Retirer « ${favorite.titre} » de vos favoris ? |
| Actions secondaires | Retirer « ${favorite.titre} » de vos favoris ? → `DeleteFavoriteM` L474 ; Annuler → `DeleteFavoriteM` L478 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDButton |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-012 — FreelanceWelcomeScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-012` |
| Fichier et lignes | `lib/mobile/view/freelance_registration/screens/freelance_welcome_screen.dart` classe ligne 8 |
| Classe | `FreelanceWelcomeScreen` |
| Nom visible | Trouvez de nouvelles missions ; Mettez en avant votre expertise ; Gérez vos échanges simplement ; Votre métier ou spécialité ; Vos compétences principales ; Une photo de profil |
| Rôle | frontière prestataire |
| Point d’entrée | main.dart, mobile/view/home.dart |
| CTA principal | Navigator L188 |
| Actions secondaires | callbacks : Navigator L188 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatelessWidget |
| Loading | ABSENT_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDButton |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-013 — FreelancePageScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-013` |
| Fichier et lignes | `lib/mobile/view/freelancepagem/screens/freelancePageScreen.dart` classe ligne 54 |
| Classe | `FreelancePageScreen` |
| Nom visible | Toutes les catégories ; Freelances recommandés ; Compétences populaires ; Aucun freelance disponible |
| Rôle | partagé |
| Point d’entrée | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/homepagem/screens/homePageScreenM.dart |
| CTA principal | Aucun freelance disponible |
| Actions secondaires | Aucun freelance disponible → `SearchPageScreenM` L469 ; Freelances recommandés → `FilterByCategoryEvent` L506 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDErrorState, SDEntityCard, SDAppBarIconThemed, SDLoadingInline, SDEmptyState |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-014 — FreelanceDetailsScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-014` |
| Fichier et lignes | `lib/mobile/view/freelancepagem/screens/freelance_details_screen.dart` classe ligne 14 |
| Classe | `FreelanceDetailsScreen` |
| Nom visible | Note ; Projets ; Réponse ; Satisfaction |
| Rôle | partagé |
| Point d’entrée | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/freelancepagem/screens/freelancePageScreen.dart, mobile/view/freelancepagem/screens/freelance_service_offer_detail_screen.dart, mobile/view/homepagem/screens/homePageScreenM.dart |
| CTA principal | Navigator L91 |
| Actions secondaires | callbacks : Navigator L91, _makePhoneCall L735, _contactFreelancer L766 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatelessWidget |
| Loading | ABSENT_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-015 — FreelanceServiceOfferDetailScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-015` |
| Fichier et lignes | `lib/mobile/view/freelancepagem/screens/freelance_service_offer_detail_screen.dart` classe ligne 11 |
| Classe | `FreelanceServiceOfferDetailScreen` |
| Nom visible | ABSENT_BY_CODE |
| Rôle | partagé |
| Point d’entrée | mobile/view/homepagem/screens/homePageScreenM.dart |
| CTA principal | Navigator L176 |
| Actions secondaires | callbacks : Navigator L176, freelanceId L324 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | FreelanceService |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDButton |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | ABSENT_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-016 — HistoryDetailScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-016` |
| Fichier et lignes | `lib/mobile/view/historypagem/screens/historyDetailScreenM.dart` classe ligne 9 |
| Classe | `HistoryDetailScreenM` |
| Nom visible | Archiver la consultation ; Supprimer la consultation ; Détails de la Consultation |
| Rôle | client |
| Point d’entrée | mobile/view/historypagem/screens/historyPageScreenM.dart |
| CTA principal | Êtes-vous sûr de vouloir archiver cette consultation ? |
| Actions secondaires | Êtes-vous sûr de vouloir archiver cette consultation ? → `ArchiveHistoryM` L586 ; Annuler → `ArchiveHistoryM` L590 ; Êtes-vous sûr de vouloir supprimer cette consultation ? Cette action est irréversible. → `DeleteHistoryM` L616 ; Annuler → `DeleteHistoryM` L620 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatelessWidget |
| Loading | ABSENT_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-017 — HistoryPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-017` |
| Fichier et lignes | `lib/mobile/view/historypagem/screens/historyPageScreenM.dart` classe ligne 18 |
| Classe | `HistoryPageScreenM` |
| Nom visible | Supprimer ; Effacer les recherches ; Votre historique ; Annonces consultées ; Recherches récentes ; Aucune consultation |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| CTA principal | Aucune consultation |
| Actions secondaires | Aucune consultation → `LoadHistoryDataM` L232 ; Retirer « ${h.titre} » de l\ → `DeleteHistoryM` L641 ; Annuler → `DeleteHistoryM` L645 ; Supprimer toutes vos recherches récentes ? → `SearchPageScreenM` L671 ; Annuler → `SearchPageScreenM` L675 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, LocalStorageService, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | PROVED_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-018 — HomePageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-018` |
| Fichier et lignes | `lib/mobile/view/homepagem/screens/homePageScreenM.dart` classe ligne 35 |
| Classe | `HomePageScreenM` |
| Nom visible | Marketplace ; Promo limitée ; Métiers ; Freelance ; É-marché ; Métiers près de vous |
| Rôle | partagé |
| Point d’entrée | mobile/view/home.dart |
| CTA principal | _openNotifications L690 |
| Actions secondaires | callbacks : _openNotifications L690, _openNotifications L704, _openOrders L771, _openMetiers L835, _openFreelance L847, _openMarketplace L859, onTap L973, onTapCta L1124 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, NotificationBloc, WebSocketService, _notificationBloc, authCubit, nomService |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | PROVED_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDListingPreviewCard, SDEntityCard, SDAppBarIconThemed |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-019 — CategoriesListScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-019` |
| Fichier et lignes | `lib/mobile/view/jobpagem/screens/categories_list_screen.dart` classe ligne 10 |
| Classe | `CategoriesListScreen` |
| Nom visible | Toutes les Catégories |
| Rôle | partagé |
| Point d’entrée | mobile/view/jobpagem/screens/jobPageScreenM.dart |
| CTA principal | ABSENT_BY_CODE |
| Actions secondaires | ABSENT_BY_CODE |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | ABSENT_BY_CODE |

## UI-ACT-020 — DetailPage

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-020` |
| Fichier et lignes | `lib/mobile/view/jobpagem/screens/detailPageScreenM.dart` classe ligne 23 |
| Classe | `DetailPage` |
| Nom visible | Signaler le service ; Distance : toutes ; ≤ 2 km ; ≤ 5 km ; ≤ 10 km ; Plus |
| Rôle | partagé |
| Point d’entrée | mobile/view/jobpagem/screens/categories_list_screen.dart, mobile/view/jobpagem/screens/jobPageScreenM_.dart, mobile/view/jobpagem/screens/services_list_screen.dart, mobile/view/jobpagem/utils/navigation_helper.dart |
| CTA principal | Commander ce service |
| Actions secondaires | Commander ce service → `/login` L1395 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit, fetchPrestatairesByService |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-021 — FullMapScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-021` |
| Fichier et lignes | `lib/mobile/view/jobpagem/screens/fullMapScreenM.dart` classe ligne 17 |
| Classe | `FullMapScreenM` |
| Nom visible | Ma position ; Carte complète |
| Rôle | partagé |
| Point d’entrée | mobile/view/jobpagem/screens/provider_profile_screen.dart, mobile/view/jobpagem/widgets/mini_map_widget.dart |
| CTA principal | _getCurrentLocation L337 |
| Actions secondaires | callbacks : _getCurrentLocation L337, _searchNearbyProviders L342 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | CustomMarkerService, _selectedService, selectedService |
| État | StatefulWidget |
| Loading | ABSENT_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-022 — JobPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-022` |
| Fichier et lignes | `lib/mobile/view/jobpagem/screens/jobPageScreenM.dart` classe ligne 26 |
| Classe | `JobPageScreenM` |
| Nom visible | ≤ ${r.toInt()} km ; ${_metier(p)}${d != null ?  ; Liste ; Carte ; ≤ ${radius == radius.roundToDouble() ? radius.toInt() : radius} km ; Vérifiés |
| Rôle | partagé |
| Point d’entrée | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/explorer/widgets/explorer_metiers_map_panel.dart, mobile/view/homepagem/screens/homePageScreenM.dart |
| CTA principal | ≤ ${r.toInt()} km |
| Actions secondaires | ≤ ${r.toInt()} km → `LoadNearbyProvidersM` L836 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, CustomMarkerService, _requestService, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-023 — ProviderProfileScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-023` |
| Fichier et lignes | `lib/mobile/view/jobpagem/screens/provider_profile_screen.dart` classe ligne 20 |
| Classe | `ProviderProfileScreen` |
| Nom visible | Signaler ce prestataire |
| Rôle | partagé |
| Point d’entrée | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/jobpagem/screens/detailPageScreenM.dart, mobile/view/jobpagem/utils/navigation_helper.dart, mobile/view/searchpagem/screens/searchPageScreenM.dart |
| CTA principal | _loadProviderData L191 |
| Actions secondaires | callbacks : _loadProviderData L191, onPressed L253, Navigator L317, _onShareProfile L328, _onToggleFavorite L333, _onReportProfile L338, hasGps L685, _openProviderFullMap L824 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, _onRequestService, authCubit, selectedService |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-024 — LocationPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-024` |
| Fichier et lignes | `lib/mobile/view/locationpagem/screens/locationPageScreenM.dart` classe ligne 10 |
| Classe | `LocationPageScreenM` |
| Nom visible | ABSENT_BY_CODE |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| CTA principal | Navigator L66 |
| Actions secondaires | callbacks : Navigator L66 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | ABSENT_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-025 — LoginPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-025` |
| Fichier et lignes | `lib/mobile/view/loginpagem/screens/loginPageScreenM.dart` classe ligne 22 |
| Classe | `LoginPageScreenM` |
| Nom visible | Réinitialiser le mot de passe ; Bienvenue ! ; Connectez-vous pour continuer ; Téléphone ; Email ; Mot de passe |
| Rôle | partagé |
| Point d’entrée | main.dart |
| CTA principal | Bienvenue ! |
| Actions secondaires | Bienvenue ! → `AuthFieldGap` L362 ; Connectez-vous pour continuer → `AuthFieldGap` L363 ; Modifier le numéro → `GooglePhoneSkippedM` L321 ; Annuler → `ApiClient` L524 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDInput, SDAppBar, SDButton, SDGoogleSignInButton |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-026 — ServiceRequestSummaryScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-026` |
| Fichier et lignes | `lib/mobile/view/orderpagem/screens/service_request_summary_screen.dart` classe ligne 12 |
| Classe | `ServiceRequestSummaryScreen` |
| Nom visible | Annuler la commande ; Suivi de commande |
| Rôle | client |
| Point d’entrée | mobile/view/jobpagem/screens/detailPageScreenM.dart, mobile/view/jobpagem/widgets/service_request_sheet.dart, mobile/view/orderpagem/screens/service_requests_list_screen.dart |
| CTA principal | Non |
| Actions secondaires | Non → `ApiClient` L511 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, ServiceRequestCubit, authCubit |
| État | StatelessWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-027 — ServiceRequestsListScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-027` |
| Fichier et lignes | `lib/mobile/view/orderpagem/screens/service_requests_list_screen.dart` classe ligne 11 |
| Classe | `ServiceRequestsListScreen` |
| Nom visible | Vos commandes ; Toutes ; En attente ; En cours ; Terminées ; Annulées |
| Rôle | client |
| Point d’entrée | mobile/view/homepagem/screens/homePageScreenM.dart, mobile/view/profilpagem/screens/profilPageScreenM.dart |
| CTA principal | Vos commandes |
| Actions secondaires | Vos commandes → `ServiceRequestCubit` L21 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, ServiceRequestCubit, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-028 — PreferencesPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-028` |
| Fichier et lignes | `lib/mobile/view/preferencespagem/screens/preferencesPageScreenM.dart` classe ligne 9 |
| Classe | `PreferencesPageScreenM` |
| Nom visible | Notifications par email ; Recevoir les notifications par email ; Notifications push ; Recevoir les notifications push ; Notifications SMS ; Recevoir les notifications par SMS |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profile_settings_hub_screen.dart |
| CTA principal | _loadPreferences L118 |
| Actions secondaires | callbacks : _loadPreferences L118, _loadPreferences L190 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-029 — AboutScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-029` |
| Fichier et lignes | `lib/mobile/view/profilpagem/screens/about_screen.dart` classe ligne 8 |
| Classe | `AboutScreen` |
| Nom visible | Conditions d’utilisation ; Politique de confidentialité ; Conditions de vente (CGV) ; Mentions légales ; Politique cookies ; En savoir plus |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| CTA principal | Navigator L76 |
| Actions secondaires | callbacks : Navigator L76, _openUrl L189, _openUrl L195, _openUrl L201, _openUrl L207, _openUrl L213, _openUrl L219, _openUrl L225 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatelessWidget |
| Loading | ABSENT_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-030 — DeleteAccountScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-030` |
| Fichier et lignes | `lib/mobile/view/profilpagem/screens/delete_account_screen.dart` classe ligne 12 |
| Classe | `DeleteAccountScreen` |
| Nom visible | Supprimer mon compte |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profile_settings_hub_screen.dart |
| CTA principal | launchUrl L92 |
| Actions secondaires | callbacks : launchUrl L92, _busy L126 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-031 — EditProfileScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-031` |
| Fichier et lignes | `lib/mobile/view/profilpagem/screens/edit_profile_screen.dart` classe ligne 11 |
| Classe | `EditProfileScreen` |
| Nom visible | Modifier le profil |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| CTA principal | _pickImage L257 |
| Actions secondaires | callbacks : _pickImage L257, Navigator L412, _updateProfile L423 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, EditProfileBloc, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDAppBarIconThemed |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-032 — HelpSupportScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-032` |
| Fichier et lignes | `lib/mobile/view/profilpagem/screens/help_support_screen.dart` classe ligne 9 |
| Classe | `HelpSupportScreen` |
| Nom visible | Nous contacter ; Email · $_supportEmail ; Copier l’email ; Utile si votre messagerie ne s’ouvre pas ; Signaler un problème ; Ouvre un email prérempli |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| CTA principal | Navigator L121 |
| Actions secondaires | callbacks : Navigator L121, _openMail L184, _openMail L208, _openMail L289, onTap L332 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | ABSENT_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-033 — LanguageSettingsScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-033` |
| Fichier et lignes | `lib/mobile/view/profilpagem/screens/language_settings_screen.dart` classe ligne 11 |
| Classe | `LanguageSettingsScreen` |
| Nom visible | Langue de l’application ; Devise |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profile_settings_hub_screen.dart |
| CTA principal | Langue de l’application |
| Actions secondaires | Langue de l’application → `UpdateLanguageM` L141 ; Devise → `UpdateCurrencyM` L171 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-034 — ProfilPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-034` |
| Fichier et lignes | `lib/mobile/view/profilpagem/screens/profilPageScreenM.dart` classe ligne 26 |
| Classe | `ProfilPageScreenM` |
| Nom visible | Se déconnecter ; Profil ; Connectez-vous à votre profil ; Mes commandes ; Favoris ; Avis & évaluations |
| Rôle | partagé |
| Point d’entrée | mobile/view/home.dart |
| CTA principal | Connectez-vous à votre profil |
| Actions secondaires | Connectez-vous à votre profil → `ServiceRequestsListScreen` L107 ; Mes commandes → `ServiceRequestsListScreen` L125 ; Favoris → `FavoritePageBlocM` L136 ; Avis & évaluations → `AvisPageBlocM` L150 ; Historique → `HistoryPageBlocM` L164 ; Notifications → `AlertPageBlocM` L178 ; Paramètres → `ProfileSettingsHubScreen` L194 ; Localisation → `LocationPageBlocM` L205 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatefulWidget |
| Loading | ABSENT_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDButton, GuestAuthState |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-035 — ProfileSettingsHubScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-035` |
| Fichier et lignes | `lib/mobile/view/profilpagem/screens/profile_settings_hub_screen.dart` classe ligne 19 |
| Classe | `ProfileSettingsHubScreen` |
| Nom visible | Langue & Devise ; Préférences ; Sécurité du compte ; Préférences de notifications ; Supprimer mon compte |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| CTA principal | Langue & Devise |
| Actions secondaires | Langue & Devise → `PreferencesPageBlocM` L64 ; Préférences → `PreferencesPageBlocM` L78 ; Sécurité du compte → `SecurityPageBlocM` L92 ; Préférences de notifications → `AlertPageBlocM` L118 ; Supprimer mon compte → `DeleteAccountScreen` L133 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatelessWidget |
| Loading | ABSENT_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-036 — RegisterPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-036` |
| Fichier et lignes | `lib/mobile/view/registerpagem/screens/registerPageScreenM.dart` classe ligne 20 |
| Classe | `RegisterPageScreenM` |
| Nom visible | Vous êtes maintenant connecté. ; Créer un compte ; Rejoignez Soutrali Deals ; Prénom ; Nom ; Email |
| Rôle | partagé |
| Point d’entrée | main.dart |
| CTA principal | Vous êtes maintenant connecté. |
| Actions secondaires | Vous êtes maintenant connecté. → `/homepage` L260 ; Créer un compte → `AuthFieldGap` L311 ; Rejoignez Soutrali Deals → `AuthFieldGap` L312 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, GoogleAuthService, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDInput, SDAppBar, SDButton, SDGoogleSignInButton |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-037 — SearchPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-037` |
| Fichier et lignes | `lib/mobile/view/searchpagem/screens/searchPageScreenM.dart` classe ligne 22 |
| Classe | `SearchPageScreenM` |
| Nom visible | À partir de $price FCFA ; Aucun résultat |
| Rôle | partagé |
| Point d’entrée | mobile/view/chatpagem/screens/chatPageScreenM.dart, mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/freelancepagem/screens/freelancePageScreen.dart, mobile/view/historypagem/screens/historyPageScreenM.dart |
| CTA principal | Réinitialiser |
| Actions secondaires | Réinitialiser → `UpdateFilters` L409 ; À partir de $price FCFA → `DetailPage` L876 ;  $rating → `Product` L1002 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | searchBloc |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-038 — SecurityPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-038` |
| Fichier et lignes | `lib/mobile/view/securitypagem/screens/securityPageScreenM.dart` classe ligne 12 |
| Classe | `SecurityPageScreenM` |
| Nom visible | Effacer l\ ; Mot de passe ; Authentification à deux facteurs ; Alertes de connexion ; Historique des connexions |
| Rôle | client |
| Point d’entrée | mobile/view/profilpagem/screens/profile_settings_hub_screen.dart |
| CTA principal | Mot de passe |
| Actions secondaires | Mot de passe → `SecuritySettingsScreenM` L191 ; Authentification à deux facteurs → `TwoFactorSetupScreenM` L203 ; Alertes de connexion → `UpdateSecuritySettingsEventM` L220 ; ******** → `SecuritySettingsScreenM` L198 ; Tous les enregistrements d\ → `ClearLoginHistoryEventM` L528 ; Annuler → `ClearLoginHistoryEventM` L532 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | _openWithBloc |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-039 — SecuritySettingsScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-039` |
| Fichier et lignes | `lib/mobile/view/securitypagem/screens/securitySettingsScreenM.dart` classe ligne 11 |
| Classe | `SecuritySettingsScreenM` |
| Nom visible | Export sécurité ; Notifications de connexion ; Recevoir des notifications lors de nouvelles connexions ; Authentification à deux facteurs requise ; Forcer l\ ; Délai d\ |
| Rôle | client |
| Point d’entrée | mobile/view/securitypagem/screens/securityPageScreenM.dart |
| CTA principal | Télécharger un rapport de sécurité |
| Actions secondaires | Télécharger un rapport de sécurité → `MarkAllAlertsAsReadEventM` L408 ; Réinitialiser les alertes non lues → `MarkAllAlertsAsReadEventM` L417 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-040 — TwoFactorSetupScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-040` |
| Fichier et lignes | `lib/mobile/view/securitypagem/screens/twoFactorSetupScreenM.dart` classe ligne 8 |
| Classe | `TwoFactorSetupScreenM` |
| Nom visible | Authentification à deux facteurs |
| Rôle | client |
| Point d’entrée | mobile/view/securitypagem/screens/securityPageScreenM.dart |
| CTA principal | _isDisabling L269 |
| Actions secondaires | callbacks : _isDisabling L269, _isVerifying L416 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-041 — EmarketWelcomeScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-041` |
| Fichier et lignes | `lib/mobile/view/seller_registration/screens/emarket_welcome_screen.dart` classe ligne 8 |
| Classe | `EmarketWelcomeScreen` |
| Nom visible | Vendez vos produits plus facilement ; Développez votre visibilité ; Gérez votre boutique depuis l’application ; Le nom de votre boutique ; Votre logo ou photo de boutique ; Les catégories de produits |
| Rôle | frontière prestataire |
| Point d’entrée | main.dart, mobile/view/home.dart |
| CTA principal | Navigator L186 |
| Actions secondaires | callbacks : Navigator L186 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatelessWidget |
| Loading | ABSENT_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDButton |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-042 — ServiceProviderWelcomeScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-042` |
| Fichier et lignes | `lib/mobile/view/serviceproviderwelcomepagem/screens/serviceProviderWelcomeScreenM.dart` classe ligne 7 |
| Classe | `ServiceProviderWelcomeScreenM` |
| Nom visible | Trouvez de nouveaux clients ; Présentez votre savoir-faire ; Gérez vos demandes depuis l’application ; Votre métier et vos spécialités ; Votre zone d’intervention ; Une photo de profil |
| Rôle | frontière prestataire |
| Point d’entrée | main.dart, mobile/view/jobpagem/screens/jobPageScreenM_.dart |
| CTA principal | Navigator L188 |
| Actions secondaires | callbacks : Navigator L188 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatelessWidget |
| Loading | ABSENT_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDButton |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-043 — ConfirmationCommandeScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-043` |
| Fichier et lignes | `lib/mobile/view/shoppingpagem/screens/confirmationCommandeScreenM.dart` classe ligne 14 |
| Classe | `ConfirmationCommandeScreen` |
| Nom visible | Aucune adresse de livraison ; Veuillez ajouter une adresse ; Livraison standard ; Livraison sous 2-5 jours ouvrés ; Passez votre commande |
| Rôle | client |
| Point d’entrée | mobile/view/shoppingpagem/screens/panierProductScreenM.dart |
| CTA principal | ${cart.adresseLivraison!.adresse}\n${cart.adresseLivraison!.ville}, ${cart.adresseLivraison!.pays}\n${cart.adresseLivraison!.telephone} |
| Actions secondaires | ${cart.adresseLivraison!.adresse}\n${cart.adresseLivraison!.ville}, ${cart.adresseLivraison!.pays}\n${cart.adresseLivraison!.telephone} → `DeliveryAddressScreen` L330 ; Veuillez ajouter une adresse → `DeliveryAddressScreen` L359 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-044 — DeliveryAddressScreen

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-044` |
| Fichier et lignes | `lib/mobile/view/shoppingpagem/screens/delivery_address_screen.dart` classe ligne 15 |
| Classe | `DeliveryAddressScreen` |
| Nom visible | Adresse de livraison ; Nom complet ; Téléphone ; Adresse complète ; Ville ; Code postal |
| Rôle | partagé |
| Point d’entrée | mobile/view/shoppingpagem/screens/confirmationCommandeScreenM.dart, mobile/view/shoppingpagem/screens/panierProductScreenM.dart |
| CTA principal | isLoading L300 |
| Actions secondaires | callbacks : isLoading L300 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-045 — PanierProductScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-045` |
| Fichier et lignes | `lib/mobile/view/shoppingpagem/screens/panierProductScreenM.dart` classe ligne 15 |
| Classe | `PanierProductScreenM` |
| Nom visible | Vider le panier ; Retirer l\ ; Votre panier ; Votre panier est vide |
| Rôle | partagé |
| Point d’entrée | mobile/view/shoppingpagem/utils/cart_navigation.dart |
| CTA principal | Votre panier |
| Actions secondaires | Votre panier → `ClearCartEvent` L41 ; Êtes-vous sûr de vouloir vider votre panier ? → `ClearCartEvent` L59 ; Annuler → `ClearCartEvent` L63 ; Voulez-vous retirer cet article du panier ? → `RemoveFromCartEvent` L279 ; Annuler → `RemoveFromCartEvent` L287 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-046 — ProductDetails

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-046` |
| Fichier et lignes | `lib/mobile/view/shoppingpagem/screens/productDetailsScreenM.dart` classe ligne 18 |
| Classe | `ProductDetails` |
| Nom visible | Voir |
| Rôle | partagé |
| Point d’entrée | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/homepagem/screens/homePageScreenM.dart, mobile/view/searchpagem/screens/searchPageScreenM.dart, mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart |
| CTA principal | _quantity L439 |
| Actions secondaires | callbacks : _quantity L439, Navigator L586, openShoppingCart L711, isAdding L719 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDButton |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-047 — ShoppingPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-047` |
| Fichier et lignes | `lib/mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart` classe ligne 168 |
| Classe | `ShoppingPageScreenM` |
| Nom visible | Comparer les produits ; Toutes les catégories ; Boutiques ; Catégories ; Produits à découvrir |
| Rôle | partagé |
| Point d’entrée | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/homepagem/screens/homePageScreenM.dart |
| CTA principal | Boutiques |
| Actions secondaires | Boutiques → `SDLoadingInline` L585 ; Marque: ${product.brand} → `RemoveFromCompareEvent` L840 ; Fermer → `ClearCompareListEvent` L861 ; Vider la liste → `ClearCompareListEvent` L865 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatefulWidget |
| Loading | PROVED_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDAppBarIconThemed, SDLoadingInline |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-048 — VendorDetailsScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-048` |
| Fichier et lignes | `lib/mobile/view/shoppingpagem/screens/vendorDetailsScreenM.dart` classe ligne 7 |
| Classe | `VendorDetailsScreenM` |
| Nom visible | ABSENT_BY_CODE |
| Rôle | partagé |
| Point d’entrée | main.dart, mobile/view/searchpagem/screens/searchPageScreenM.dart |
| CTA principal | hasPhone L678 |
| Actions secondaires | callbacks : hasPhone L678 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatelessWidget |
| Loading | ABSENT_BY_CODE |
| Empty | PROVED_BY_CODE |
| Error | PROVED_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | ABSENT_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-049 — SplashScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-049` |
| Fichier et lignes | `lib/mobile/view/splashcreenm/screens/splashScreenM.dart` classe ligne 18 |
| Classe | `SplashScreenM` |
| Nom visible | ABSENT_BY_CODE |
| Rôle | partagé |
| Point d’entrée | main.dart |
| CTA principal | _onSkipTap L165 |
| Actions secondaires | callbacks : _onSkipTap L165 |
| Destination de chaque action | incluse dans la colonne actions |
| Données | ABSENT_BY_CODE dans ce fichier |
| État | StatefulWidget |
| Loading | ABSENT_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | PROVED_BY_CODE |
| Garde auth | ABSENT_BY_CODE dans ce fichier (la garde de route est dans main.dart 141-159 pour les préfixes auth) |
| Comportement invité | mur ou route publique |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | ABSENT_BY_CODE |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | ABSENT_BY_CODE |
| Preuve actions | PROVED_BY_CODE |

## UI-ACT-050 — WalletPageScreenM

| Champ | Valeur |
| --- | --- |
| Identifiant | `UI-ACT-050` |
| Fichier et lignes | `lib/mobile/view/walletpagem/screens/walletPageScreenM.dart` classe ligne 9 |
| Classe | `WalletPageScreenM` |
| Nom visible | Connexion requise ; SoutraPay |
| Rôle | client |
| Point d’entrée | main.dart |
| CTA principal | ABSENT_BY_CODE |
| Actions secondaires | ABSENT_BY_CODE |
| Destination de chaque action | incluse dans la colonne actions |
| Données | AuthCubit, authCubit |
| État | StatelessWidget |
| Loading | ABSENT_BY_CODE |
| Empty | ABSENT_BY_CODE |
| Error | ABSENT_BY_CODE |
| Offline | ABSENT_BY_CODE |
| Cache | ABSENT_BY_CODE |
| Garde auth | PROVED_BY_CODE : AuthCubit / AuthAuthenticated lu dans le fichier |
| Comportement invité | NOT_APPLICABLE : entrée client uniquement |
| Comportement client | contenu authentifié du même fichier ou écran client |
| Retour | pop théorique si ouvert par Navigator.push ou context.push ; pile remplacée si ouvert par context.go |
| Contexte | mécanisme de pile `PROVED_BY_CODE` ; conservation visuelle réservée au parcours 12 |
| Design system | SDWhiteAppBar |
| Doublon | voir section doublons si la classe est homonyme |
| Statut | actif |
| Preuve titre | PROVED_BY_CODE |
| Preuve actions | ABSENT_BY_CODE |

Fiches actives écrites : **50**.

## Doublons — aucune fusion

| Groupe | Imports | Données | Navigation | Composant commun | Décision |
| --- | --- | --- | --- | --- | --- |
| `jobPageScreenM.dart` / `jobPageScreenM_.dart` | tous les `JobPageScreenM(` importent `jobPageScreenM.dart` ; `_` a 0 import | liste métiers seulement dans le fichier importé | `_` contient `Navigator.pushNamed` L156 vers `/wallet`, jamais atteint | ABSENT_BY_CODE | conserver séparé, legacy non accessible |
| `rondPageScreenM.dart` / `rondPageScreenMVO.dart` | 0 import externe des deux classes | pages démo | Drawer L42 dans `rondPageScreenM.dart` | ABSENT_BY_CODE | ne pas supprimer dans cette phase, hors graphe |
| sheets de demande | un seul fichier `service_request_sheet.dart` ; variante integrated ABSENT_BY_CODE | formulaire du widget | appelé L394 `jobPageScreenM.dart` et L1358 `provider_profile_screen.dart` client | le widget lui-même | pas de fusion nécessaire |
| trois welcome | routes distinctes dans `main.dart` 194-208 | catégories prestataire versus freelance versus vendeur | sheet Publier `home.dart` 326 puis `context.push` vers la route welcome | ABSENT_BY_CODE | conserver séparé |
| `ProviderProfileScreen` homonyme | tableau d’imports ci-dessus | fiche client versus profil dashboard | aucun appel croisé | ABSENT_BY_CODE | conserver séparé |
| murs invité chat et profil | pas un import croisé : les deux instancient `GuestAuthState` | textes différents (`pageTitle` Profil versus messagerie) | `context.push('/login')` et `context.push('/register')` | `GuestAuthState` dans `design_system/widgets/sd_feedback_states.dart` L112 | harmoniser plus tard, ne pas fusionner les écrans |

Groupes : **6**. Aucun fichier fusionné.

## Composants réutilisés

Un composant est réutilisé seulement avec au moins deux fichiers consommateurs hors de sa définition. Le nombre d’occurrences est le nombre de lignes non commentées citant le nom. Le nombre de fichiers est distinct.

| Classe | Fichier | Occurrences | Fichiers distincts | Client | Prestataire | Orphelin/legacy | Statut |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| `SDWhiteAppBar` | `design_system/widgets/sd_white_appbar.dart` | 39 | 38 | 25 | 5 | 8 | PROVED_BY_CODE |
| `SDAppBarIconThemed` | `design_system/widgets/sd_app_bar_icon_button.dart` | 13 | 11 | 7 | 0 | 4 | PROVED_BY_CODE |
| `SDButton` | `design_system/widgets/sd_button.dart` | 18 | 10 | 10 | 0 | 0 | PROVED_BY_CODE |
| `SDEntityCard` | `design_system/widgets/sd_entity_card.dart` | 4 | 4 | 3 | 0 | 1 | PROVED_BY_CODE |
| `GuestAuthState` | `design_system/widgets/sd_feedback_states.dart` | 3 | 3 | 3 | 0 | 0 | PROVED_BY_CODE |
| `SDInput` | `design_system/widgets/sd_input.dart` | 12 | 3 | 3 | 0 | 0 | PROVED_BY_CODE |
| `SDErrorState` | `design_system/widgets/sd_feedback_states.dart` | 3 | 2 | 2 | 0 | 0 | PROVED_BY_CODE |
| `SDLoadingInline` | `design_system/widgets/sd_feedback_states.dart` | 3 | 2 | 2 | 0 | 0 | PROVED_BY_CODE |
| `SDAppBar` | `design_system/widgets/sd_appbar.dart` | 2 | 2 | 2 | 0 | 0 | PROVED_BY_CODE |
| `SDGoogleSignInButton` | `design_system/widgets/sd_google_sign_in_button.dart` | 2 | 2 | 2 | 0 | 0 | PROVED_BY_CODE |

Composants design system avec au moins 2 fichiers consommateurs listés : **10** (plafond d’affichage 24, le décompte ci-dessus est celui affiché).
`ProfileMenuItem` : 0 instanciation hors de son fichier. Présent dans `screens/`, statut widget orphelin. `PROVED_BY_CODE`.
`StandardScreenHeader` : rechercher les instanciations hors fichier de définition.
Consommateurs `StandardScreenHeader` : 3 fichier(s) mobile/view/morepagem/screens/morePageScreenM.dart, mobile/view/orderpagem/screens/orderPageScreenM.dart, mobile/view/rondpagem/screens/rondPageScreenM.dart. Occurrences : 3.

## Parcours appareil

Ces six parcours restent `MANUAL_REQUIRED`. Ils ne sont pas joués dans cette phase.

| # | Parcours | Statut | Limite du code |
| --- | --- | --- | --- |
| 1 | invité → Métiers → fiche → appel | MANUAL_REQUIRED | la fiche et la liste sont dans le graphe ; l’ouverture du composeur téléphone dépend du système |
| 2 | invité → fiche → demande → login | MANUAL_REQUIRED | `showServiceRequestSheet` est appelé ; le retour après login dépend de la pile réelle |
| 3 | login → retour ou perte du contexte | MANUAL_REQUIRED | `context.go('/login')` remplace la pile ; le retour visuel n’est pas un fait de code seul |
| 4 | invité → É-marché → produit → contact | MANUAL_REQUIRED | `ProductDetails` est atteint ; l’action contact finale dépend du rendu et du système |
| 5 | notification → destination | MANUAL_REQUIRED | splash fait `context.go(dest)` ; le payload FCM reçu n’est pas rejoué ici |
| 6 | recherche → résultat → retour avec état conservé | MANUAL_REQUIRED | `SearchPageScreenM` est dans le graphe ; la conservation du scroll dépend du cycle de vie |

### Protocole de smoke test (non exécuté)

| Parcours | État initial | Gestes | Résultat attendu | Preuve à collecter |
| --- | --- | --- | --- | --- |
| 1 | app fraîche, non connecté | Accueil ou Explorer, Métiers, une fiche, bouton d’appel | composeur avec le numéro, ou absence claire du bouton | capture écran + numéro masqué |
| 2 | non connecté, fiche métier ouverte | Demander un service | login, puis retour vers la demande ou perte de la fiche | capture avant et après login |
| 3 | fiche ouverte, puis login par une action | se connecter | l’écran précédent est encore sous la pile, ou l’accueil le remplace | capture de la route affichée |
| 4 | non connecté | É-marché, un produit, contact | appel, message, ou sheet, sans crash | capture du CTA contact |
| 5 | compte test connecté, une notification FCM | ouvrir la notification | écran cible ou login, pas un écran vide | capture de la route |
| 6 | une recherche avec résultats | ouvrir un résultat, revenir | la requête et le scroll sont encore là, ou non | capture avant et après retour |

## Annexe A — 84 fichiers physiques

| ID | Chemin | Classe | Catégorie | Appelé depuis (import + constructeur) |
| --- | --- | --- | --- | --- |
| FILE-001 | `lib/mobile/view/alertpagem/screens/alertDetailScreenM.dart` | AlertDetailScreenM | 2 client | mobile/view/alertpagem/screens/alertPageScreenM.dart |
| FILE-002 | `lib/mobile/view/alertpagem/screens/alertPageScreenM.dart` | AlertPageScreenM | 2 client | mobile/view/homepagem/screens/homePageScreenM.dart, mobile/view/profilpagem/screens/profilPageScreenM.dart |
| FILE-003 | `lib/mobile/view/alertpagem/screens/alertSettingsScreenM.dart` | AlertSettingsScreenM | 2 client | mobile/view/alertpagem/screens/alertPageScreenM.dart, mobile/view/profilpagem/screens/profile_settings_hub_screen.dart |
| FILE-004 | `lib/mobile/view/alertpagem/screens/createAlertScreenM.dart` | CreateAlertScreenM | 6 orphelin | aucun import instanciant cette classe |
| FILE-005 | `lib/mobile/view/avispagem/screens/avisDetailScreenM.dart` | AvisDetailScreenM | 2 client | mobile/view/avispagem/screens/avisPageScreenM.dart |
| FILE-006 | `lib/mobile/view/avispagem/screens/avisPageScreenM.dart` | AvisPageScreenM | 2 client | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| FILE-007 | `lib/mobile/view/avispagem/screens/createAvisScreenM.dart` | CreateAvisScreenM | 6 orphelin | aucun import instanciant cette classe |
| FILE-008 | `lib/mobile/view/chatpagem/screens/chatPageScreenM.dart` | ChatPageScreenM | 3 partagé | main.dart, mobile/view/home.dart, mobile/view/freelancepagem/screens/freelance_details_screen.dart, mobile/view/orderpagem/screens/service_request_summary_screen.dart |
| FILE-009 | `lib/mobile/view/common/screens/ai_assistant_chat_screen.dart` | AIAssistantChatScreen | 8 test/démonstration | mobile/view/jobpagem/screens/jobPageScreenM_.dart |
| FILE-010 | `lib/mobile/view/explorer/screens/explorer_page_screen.dart` | ExplorerPageScreen | 3 partagé | mobile/view/home.dart |
| FILE-011 | `lib/mobile/view/favorispagem/screens/addFavoriteScreenM.dart` | AddFavoriteScreenM | 6 orphelin | aucun import instanciant cette classe |
| FILE-012 | `lib/mobile/view/favorispagem/screens/favoriteDetailScreenM.dart` | FavoriteDetailScreenM | 2 client | mobile/view/favorispagem/screens/favorite_page_screen_m.dart |
| FILE-013 | `lib/mobile/view/favorispagem/screens/favorite_page_screen_m.dart` | FavoritePageScreenM | 2 client | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| FILE-014 | `lib/mobile/view/freelance_registration/screens/freelance_form_screen.dart` | FreelanceFormScreen | 5 prestataire hors périmètre | mobile/view/freelance_registration/screens/freelance_registration_screen.dart, mobile/view/freelance_registration/screens/freelance_welcome_screen.dart |
| FILE-015 | `lib/mobile/view/freelance_registration/screens/freelance_registration_screen.dart` | FreelanceRegistrationScreen | 6 orphelin | aucun import instanciant cette classe |
| FILE-016 | `lib/mobile/view/freelance_registration/screens/freelance_welcome_screen.dart` | FreelanceWelcomeScreen | 4 frontière prestataire | main.dart, mobile/view/home.dart |
| FILE-017 | `lib/mobile/view/freelancepagem/screens/freelancePageScreen.dart` | FreelancePageScreen | 3 partagé | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/homepagem/screens/homePageScreenM.dart |
| FILE-018 | `lib/mobile/view/freelancepagem/screens/freelance_details_screen.dart` | FreelanceDetailsScreen | 3 partagé | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/freelancepagem/screens/freelancePageScreen.dart, mobile/view/freelancepagem/screens/freelance_service_offer_detail_screen.dart, mobile/view/homepagem/screens/homePageScreenM.dart |
| FILE-019 | `lib/mobile/view/freelancepagem/screens/freelance_service_offer_detail_screen.dart` | FreelanceServiceOfferDetailScreen | 3 partagé | mobile/view/homepagem/screens/homePageScreenM.dart |
| FILE-020 | `lib/mobile/view/historypagem/screens/historyDetailScreenM.dart` | HistoryDetailScreenM | 2 client | mobile/view/historypagem/screens/historyPageScreenM.dart |
| FILE-021 | `lib/mobile/view/historypagem/screens/historyPageScreenM.dart` | HistoryPageScreenM | 2 client | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| FILE-022 | `lib/mobile/view/homepagem/screens/homePageScreenM.dart` | HomePageScreenM | 3 partagé | mobile/view/home.dart |
| FILE-023 | `lib/mobile/view/jobpagem/screens/categories_list_screen.dart` | CategoriesListScreen | 3 partagé | mobile/view/jobpagem/screens/jobPageScreenM.dart |
| FILE-024 | `lib/mobile/view/jobpagem/screens/detailPageScreenM.dart` | DetailPage | 3 partagé | mobile/view/jobpagem/screens/categories_list_screen.dart, mobile/view/jobpagem/screens/jobPageScreenM_.dart, mobile/view/jobpagem/screens/services_list_screen.dart, mobile/view/jobpagem/utils/navigation_helper.dart |
| FILE-025 | `lib/mobile/view/jobpagem/screens/fullMapScreenM.dart` | FullMapScreenM | 3 partagé | mobile/view/jobpagem/screens/provider_profile_screen.dart, mobile/view/jobpagem/widgets/mini_map_widget.dart |
| FILE-026 | `lib/mobile/view/jobpagem/screens/jobPageScreenM.dart` | JobPageScreenM | 3 partagé | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/explorer/widgets/explorer_metiers_map_panel.dart, mobile/view/homepagem/screens/homePageScreenM.dart |
| FILE-027 | `lib/mobile/view/jobpagem/screens/jobPageScreenM_.dart` | JobPageScreenM | 7 legacy | aucun import instanciant cette classe |
| FILE-028 | `lib/mobile/view/jobpagem/screens/provider_profile_screen.dart` | ProviderProfileScreen | 3 partagé | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/jobpagem/screens/detailPageScreenM.dart, mobile/view/jobpagem/utils/navigation_helper.dart, mobile/view/searchpagem/screens/searchPageScreenM.dart |
| FILE-029 | `lib/mobile/view/jobpagem/screens/providers_list_screen.dart` | ProvidersListScreen | 6 orphelin | aucun import instanciant cette classe |
| FILE-030 | `lib/mobile/view/jobpagem/screens/services_list_screen.dart` | ServicesListScreen | 6 orphelin | aucun import instanciant cette classe |
| FILE-031 | `lib/mobile/view/locationpagem/screens/locationPageScreenM.dart` | LocationPageScreenM | 2 client | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| FILE-032 | `lib/mobile/view/loginpagem/screens/loginPageScreenM.dart` | LoginPageScreenM | 3 partagé | main.dart |
| FILE-033 | `lib/mobile/view/morepagem/screens/morePageScreenM.dart` | MorePageScreenM | 6 orphelin | aucun import instanciant cette classe |
| FILE-034 | `lib/mobile/view/notificationpagem/screens/notification_screen.dart` | NotificationScreen | 6 orphelin | aucun import instanciant cette classe |
| FILE-035 | `lib/mobile/view/orderpagem/screens/commande_details_screen.dart` | CommandeDetailsScreen | 2 client | mobile/view/orderpagem/screens/orderPageScreenM.dart |
| FILE-036 | `lib/mobile/view/orderpagem/screens/orderPageScreenM.dart` | OrderPageScreenM | 6 orphelin | aucun import instanciant cette classe |
| FILE-037 | `lib/mobile/view/orderpagem/screens/service_request_summary_screen.dart` | ServiceRequestSummaryScreen | 2 client | mobile/view/jobpagem/screens/detailPageScreenM.dart, mobile/view/jobpagem/widgets/service_request_sheet.dart, mobile/view/orderpagem/screens/service_requests_list_screen.dart |
| FILE-038 | `lib/mobile/view/orderpagem/screens/service_requests_list_screen.dart` | ServiceRequestsListScreen | 2 client | mobile/view/homepagem/screens/homePageScreenM.dart, mobile/view/profilpagem/screens/profilPageScreenM.dart |
| FILE-039 | `lib/mobile/view/preferencespagem/screens/preferencesPageScreenM.dart` | PreferencesPageScreenM | 2 client | mobile/view/profilpagem/screens/profile_settings_hub_screen.dart |
| FILE-040 | `lib/mobile/view/profilpagem/screens/about_screen.dart` | AboutScreen | 2 client | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| FILE-041 | `lib/mobile/view/profilpagem/screens/delete_account_screen.dart` | DeleteAccountScreen | 2 client | mobile/view/profilpagem/screens/profile_settings_hub_screen.dart |
| FILE-042 | `lib/mobile/view/profilpagem/screens/edit_profile_screen.dart` | EditProfileScreen | 2 client | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| FILE-043 | `lib/mobile/view/profilpagem/screens/help_support_screen.dart` | HelpSupportScreen | 2 client | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| FILE-044 | `lib/mobile/view/profilpagem/screens/language_settings_screen.dart` | LanguageSettingsScreen | 2 client | mobile/view/profilpagem/screens/profile_settings_hub_screen.dart |
| FILE-045 | `lib/mobile/view/profilpagem/screens/profilPageScreenM.dart` | ProfilPageScreenM | 3 partagé | mobile/view/home.dart |
| FILE-046 | `lib/mobile/view/profilpagem/screens/profile_menu_item.dart` | ProfileMenuItem | 9 widget mal placé | aucun import instanciant cette classe |
| FILE-047 | `lib/mobile/view/profilpagem/screens/profile_settings_hub_screen.dart` | ProfileSettingsHubScreen | 2 client | mobile/view/profilpagem/screens/profilPageScreenM.dart |
| FILE-048 | `lib/mobile/view/provider_dashboard/screens/prestataire_finalization_screen.dart` | PrestataireFinalizationScreen | 5 prestataire hors périmètre | main.dart |
| FILE-049 | `lib/mobile/view/provider_dashboard/screens/provider_dashboard_screen.dart` | ProviderDashboardScreen | 6 orphelin | aucun import instanciant cette classe |
| FILE-050 | `lib/mobile/view/provider_dashboard/screens/provider_main_screen.dart` | ProviderMainScreen | 5 prestataire hors périmètre | main.dart |
| FILE-051 | `lib/mobile/view/provider_dashboard/screens/provider_messages_screen.dart` | ProviderMessagesScreen | 5 prestataire hors périmètre | mobile/view/provider_dashboard/screens/provider_main_screen.dart |
| FILE-052 | `lib/mobile/view/provider_dashboard/screens/provider_missions_screen.dart` | ProviderMissionsScreen | 5 prestataire hors périmètre | mobile/view/provider_dashboard/screens/provider_main_screen.dart |
| FILE-053 | `lib/mobile/view/provider_dashboard/screens/provider_notifications_screen.dart` | ProviderNotificationsScreen | 5 prestataire hors périmètre | mobile/view/provider_dashboard/screens/provider_main_screen.dart |
| FILE-054 | `lib/mobile/view/provider_dashboard/screens/provider_planning_screen.dart` | ProviderPlanningScreen | 5 prestataire hors périmètre | mobile/view/provider_dashboard/screens/provider_main_screen.dart |
| FILE-055 | `lib/mobile/view/provider_dashboard/screens/provider_profile_screen.dart` | ProviderProfileScreen | 5 prestataire hors périmètre | mobile/view/provider_dashboard/screens/provider_main_screen.dart |
| FILE-056 | `lib/mobile/view/provider_dashboard/screens/provider_settings_screen.dart` | ProviderSettingsScreen | 5 prestataire hors périmètre | mobile/view/provider_dashboard/screens/provider_main_screen.dart |
| FILE-057 | `lib/mobile/view/provider_dashboard/screens/provider_soutrapay_screen.dart` | ProviderSoutraPayScreen | 6 orphelin | aucun import instanciant cette classe |
| FILE-058 | `lib/mobile/view/provider_dashboard/screens/provider_statistics_screen.dart` | ProviderStatisticsScreen | 5 prestataire hors périmètre | mobile/view/provider_dashboard/screens/provider_main_screen.dart |
| FILE-059 | `lib/mobile/view/registerpagem/screens/registerPageScreenM.dart` | RegisterPageScreenM | 3 partagé | main.dart |
| FILE-060 | `lib/mobile/view/rondpagem/screens/rondPageScreenM.dart` | RondPageScreenM | 8 test/démonstration | aucun import instanciant cette classe |
| FILE-061 | `lib/mobile/view/rondpagem/screens/rondPageScreenMVO.dart` | RondPageScreenMVO | 6 orphelin | aucun import instanciant cette classe |
| FILE-062 | `lib/mobile/view/searchpagem/screens/searchPageScreenM.dart` | SearchPageScreenM | 3 partagé | mobile/view/chatpagem/screens/chatPageScreenM.dart, mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/freelancepagem/screens/freelancePageScreen.dart, mobile/view/historypagem/screens/historyPageScreenM.dart |
| FILE-063 | `lib/mobile/view/securitypagem/screens/securityDetailScreenM.dart` | SecurityDetailScreenM | 6 orphelin | aucun import instanciant cette classe |
| FILE-064 | `lib/mobile/view/securitypagem/screens/securityPageScreenM.dart` | SecurityPageScreenM | 2 client | mobile/view/profilpagem/screens/profile_settings_hub_screen.dart |
| FILE-065 | `lib/mobile/view/securitypagem/screens/securitySettingsScreenM.dart` | SecuritySettingsScreenM | 2 client | mobile/view/securitypagem/screens/securityPageScreenM.dart |
| FILE-066 | `lib/mobile/view/securitypagem/screens/twoFactorSetupScreenM.dart` | TwoFactorSetupScreenM | 2 client | mobile/view/securitypagem/screens/securityPageScreenM.dart |
| FILE-067 | `lib/mobile/view/seller_registration/screens/emarket_welcome_screen.dart` | EmarketWelcomeScreen | 4 frontière prestataire | main.dart, mobile/view/home.dart |
| FILE-068 | `lib/mobile/view/seller_registration/screens/seller_form_screen.dart` | SellerFormScreen | 5 prestataire hors périmètre | mobile/view/seller_registration/screens/emarket_welcome_screen.dart, mobile/view/seller_registration/screens/seller_registration_screen.dart |
| FILE-069 | `lib/mobile/view/seller_registration/screens/seller_registration_screen.dart` | SellerRegistrationScreen | 6 orphelin | aucun import instanciant cette classe |
| FILE-070 | `lib/mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart` | ServiceProviderRegistrationScreenM | 5 prestataire hors périmètre | main.dart |
| FILE-071 | `lib/mobile/view/serviceproviderwelcomepagem/screens/serviceProviderWelcomeScreenM.dart` | ServiceProviderWelcomeScreenM | 4 frontière prestataire | main.dart, mobile/view/jobpagem/screens/jobPageScreenM_.dart |
| FILE-072 | `lib/mobile/view/shoppingpagem/screens/confirmationCommandeScreenM.dart` | ConfirmationCommandeScreen | 2 client | mobile/view/shoppingpagem/screens/panierProductScreenM.dart |
| FILE-073 | `lib/mobile/view/shoppingpagem/screens/delivery_address_screen.dart` | DeliveryAddressScreen | 3 partagé | mobile/view/shoppingpagem/screens/confirmationCommandeScreenM.dart, mobile/view/shoppingpagem/screens/panierProductScreenM.dart |
| FILE-074 | `lib/mobile/view/shoppingpagem/screens/panierProductScreenM.dart` | PanierProductScreenM | 3 partagé | mobile/view/shoppingpagem/utils/cart_navigation.dart |
| FILE-075 | `lib/mobile/view/shoppingpagem/screens/productDetailsScreenM.dart` | ProductDetails | 3 partagé | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/homepagem/screens/homePageScreenM.dart, mobile/view/searchpagem/screens/searchPageScreenM.dart, mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart |
| FILE-076 | `lib/mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart` | ShoppingPageScreenM | 3 partagé | mobile/view/explorer/screens/explorer_page_screen.dart, mobile/view/homepagem/screens/homePageScreenM.dart |
| FILE-077 | `lib/mobile/view/shoppingpagem/screens/vendorDetailsScreenM.dart` | VendorDetailsScreenM | 3 partagé | main.dart, mobile/view/searchpagem/screens/searchPageScreenM.dart |
| FILE-078 | `lib/mobile/view/splashcreenm/screens/splashScreenM.dart` | SplashScreenM | 3 partagé | main.dart |
| FILE-079 | `lib/mobile/view/walletpagem/screens/soutraPayActivationScreen.dart` | SoutraPayActivationScreen | 6 orphelin | aucun import instanciant cette classe |
| FILE-080 | `lib/mobile/view/walletpagem/screens/soutraRechargeConfirmationScreen.dart` | SoutraRechargeConfirmationScreen | 6 orphelin | aucun import instanciant cette classe |
| FILE-081 | `lib/mobile/view/walletpagem/screens/soutraRechargeScreen.dart` | SoutraRechargeScreen | 6 orphelin | mobile/view/walletpagem/screens/soutraWalletMainScreen.dart |
| FILE-082 | `lib/mobile/view/walletpagem/screens/soutraTransferScreen.dart` | SoutraTransferScreen | 6 orphelin | mobile/view/walletpagem/screens/soutraWalletMainScreen.dart |
| FILE-083 | `lib/mobile/view/walletpagem/screens/soutraWalletMainScreen.dart` | SoutraWalletMainScreen | 6 orphelin | aucun import instanciant cette classe |
| FILE-084 | `lib/mobile/view/walletpagem/screens/walletPageScreenM.dart` | WalletPageScreenM | 2 client | main.dart |

## Annexe B — routes GoRouter

| Ligne main.dart | Chemin | Builder | Graphe client |
| --- | --- | --- | --- |
| 164 | `/` | / | oui |
| 174 | `/homepage` | mobile/view/home.dart | oui |
| 178 | `/onboarding` | mobile/view/onboarding/onboarding_screen.dart | oui |
| 182 | `/register` | mobile/view/registerpagem/screens/registerPageScreenM.dart | oui |
| 191 | `/login` | mobile/view/loginpagem/screens/loginPageScreenM.dart | oui |
| 195 | `/serviceProviderWelcome` | mobile/view/serviceproviderwelcomepagem/screens/serviceProviderWelcomeScreenM.dart | oui |
| 202 | `/freelanceWelcome` | mobile/view/freelance_registration/screens/freelance_welcome_screen.dart | oui |
| 206 | `/emarketWelcome` | mobile/view/seller_registration/screens/emarket_welcome_screen.dart | oui |
| 210 | `/serviceProviderRegistration` | mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart | oui |
| 219 | `/providermain` | mobile/view/provider_dashboard/screens/provider_main_screen.dart | non, sortie prestataire |
| 227 | `/prestataire-finalization` | mobile/view/provider_dashboard/screens/prestataire_finalization_screen.dart | non, sortie prestataire |
| 236 | `/vendeurDetails` | mobile/view/shoppingpagem/screens/vendorDetailsScreenM.dart | oui |
| 244 | `/wallet` | mobile/view/walletpagem/screens/walletPageScreenM.dart | oui |
| 250 | `/wallet/profile` | mobile/view/walletpagem/screens/walletPageScreenM.dart | oui |
| 257 | `/mission-details/:missionId` | INLINE_PROVIDER_STUB | non, sortie prestataire |
| 299 | `/chat/:conversationId` | mobile/view/chatpagem/screens/chatPageScreenM.dart | oui |

## Annexe C — navigations globales hors graphe client

Ces appels existent dans `lib/` mais leur fichier source n’est pas atteint depuis les seeds invité/client, ou ils sont dans le dashboard.

| Fichier:ligne | Méthode | Destination lue |
| --- | --- | --- |
| `main.dart:287` | context.go | /providermain |
| `mobile/view/common/screens/ai_assistant_chat_screen.dart:92` | showDialog | fenêtre sans classe importée |
| `mobile/view/freelance_registration/screens/freelance_registration_screen.dart:363` | Navigator.push | FreelanceFormScreen |
| `mobile/view/freelance_registration/screens/freelance_registration_screen.dart:390` | showDialog | fenêtre sans classe importée |
| `mobile/view/jobpagem/screens/jobPageScreenM_.dart:156` | Navigator.pushNamed | /wallet |
| `mobile/view/jobpagem/screens/jobPageScreenM_.dart:173` | Navigator.push | AIAssistantChatScreen |
| `mobile/view/jobpagem/screens/jobPageScreenM_.dart:311` | Navigator.push | DetailPage |
| `mobile/view/jobpagem/screens/jobPageScreenM_.dart:422` | Navigator.push | DetailPage |
| `mobile/view/jobpagem/screens/jobPageScreenM_.dart:680` | Navigator.push | ServiceProviderWelcomeScreenM |
| `mobile/view/jobpagem/screens/services_list_screen.dart:133` | Navigator.push | DetailPage |
| `mobile/view/jobpagem/widgets/job_app_bar.dart:53` | Navigator.of.push | SearchPageScreenM |
| `mobile/view/jobpagem/widgets/mini_map_widget.dart:322` | Navigator.push | FullMapScreenM |
| `mobile/view/morepagem/screens/morePageScreenM.dart:94` | Navigator.of.push | SearchPageScreenM |
| `mobile/view/morepagem/screens/morePageScreenM.dart:195` | context.push | /providermain |
| `mobile/view/morepagem/screens/morePageScreenM.dart:199` | context.push | /providermain |
| `mobile/view/notificationpagem/screens/notification_screen.dart:384` | showDialog | DeleteNotification |
| `mobile/view/notificationpagem/screens/notification_screen.dart:435` | showDialog | DeleteNotification |
| `mobile/view/notificationpagem/screens/notification_screen.dart:709` | context.push | /mission-details/$missionId |
| `mobile/view/notificationpagem/screens/notification_screen.dart:722` | context.push | /chat/$conversationId |
| `mobile/view/orderpagem/screens/commande_details_screen.dart:233` | showDialog | AnnulerCommande |
| `mobile/view/orderpagem/screens/orderPageScreenM.dart:381` | Navigator.push | CommandeDetailsScreen |
| `mobile/view/orderpagem/screens/orderPageScreenM.dart:401` | showDialog | fenêtre sans classe importée |
| `mobile/view/profilpagem/screens/profilPageScreenM.dart:47` | showModalBottomSheet | fenêtre sans classe importée |
| `mobile/view/provider_dashboard/screens/prestataire_finalization_screen.dart:82` | context.push | /homepage |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:611` | context.push | /prestataire-finalization |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:732` | context.push | /prestataire-finalization |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:760` | context.push | /homepage |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:837` | context.push | /homepage |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:940` | context.push | /homepage |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:992` | context.push | /homepage |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:1380` | context.push | /homepage |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:1384` | context.push | /homepage |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:1390` | showDialog | /login |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:1404` | context.go | /login |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:1419` | Navigator.push | NotificationsBloc |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:1436` | showDialog | fenêtre sans classe importée |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:1459` | Navigator.push | ProviderProfileBloc |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:1478` | Navigator.push | ProviderProfileBloc |
| `mobile/view/provider_dashboard/screens/provider_main_screen.dart:1497` | Navigator.push | ProviderStatisticsBloc |
| `mobile/view/provider_dashboard/screens/provider_messages_screen.dart:82` | showModalBottomSheet | fenêtre sans classe importée |
| `mobile/view/provider_dashboard/screens/provider_messages_screen.dart:636` | Navigator.of.push | ChatPageBlocM |
| `mobile/view/provider_dashboard/screens/provider_missions_screen.dart:312` | showModalBottomSheet | fenêtre sans classe importée |
| `mobile/view/provider_dashboard/screens/provider_notifications_screen.dart:865` | showDialog | DeleteNotification |
| `mobile/view/provider_dashboard/screens/provider_planning_screen.dart:119` | showModalBottomSheet | /prestataire/$id |
| `mobile/view/provider_dashboard/screens/provider_planning_screen.dart:1250` | showDialog | fenêtre sans classe importée |
| `mobile/view/provider_dashboard/screens/provider_profile_screen.dart:88` | showDialog | fenêtre sans classe importée |
| `mobile/view/provider_dashboard/screens/provider_settings_screen.dart:191` | context.go | /login |
| `mobile/view/provider_dashboard/screens/provider_settings_screen.dart:624` | showDialog | DeactivateAccount |
| `mobile/view/provider_dashboard/screens/provider_settings_screen.dart:658` | showDialog | DeleteAccount |
| `mobile/view/provider_dashboard/screens/provider_settings_screen.dart:698` | showDialog | fenêtre sans classe importée |
| `mobile/view/provider_dashboard/screens/provider_soutrapay_screen.dart:984` | showDialog | fenêtre sans classe importée |
| `mobile/view/provider_dashboard/screens/provider_statistics_screen.dart:558` | showModalBottomSheet | fenêtre sans classe importée |
| `mobile/view/rondpagem/screens/rondPageScreenM.dart:97` | Navigator.of.push | SearchPageScreenM |
| `mobile/view/rondpagem/screens/rondPageScreenM.dart:638` | showModalBottomSheet | fenêtre sans classe importée |
| `mobile/view/rondpagem/screens/rondPageScreenMVO.dart:588` | showModalBottomSheet | fenêtre sans classe importée |
| `mobile/view/securitypagem/screens/securityDetailScreenM.dart:358` | showDialog | DeleteAlertEventM |
| `mobile/view/seller_registration/screens/seller_registration_screen.dart:461` | Navigator.push | SellerFormScreen |
| `mobile/view/seller_registration/screens/seller_registration_screen.dart:488` | showDialog | fenêtre sans classe importée |
| `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart:797` | showDialog | AppImage |
| `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart:887` | Navigator.of.push | ProductDetails |
| `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart:1175` | context.push | /login |
| `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart:1378` | Navigator.push | SearchPageScreenM |
| `mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart:1489` | context.go | /wallet |
| `mobile/view/shoppingpagem/widgets/product_card_m.dart:35` | Navigator.of.push | ProductDetails |
| `mobile/view/walletpagem/screens/soutraRechargeConfirmationScreen.dart:216` | showDialog | fenêtre sans classe importée |
| `mobile/view/walletpagem/screens/soutraRechargeConfirmationScreen.dart:241` | showDialog | fenêtre sans classe importée |
| `mobile/view/walletpagem/screens/soutraRechargeScreen.dart:250` | showModalBottomSheet | SelectPaymentMethodSheet |
| `mobile/view/walletpagem/screens/soutraTransferScreen.dart:304` | showModalBottomSheet | fenêtre sans classe importée |
| `mobile/view/walletpagem/screens/soutraTransferScreen.dart:412` | showDialog | fenêtre sans classe importée |
| `mobile/view/walletpagem/screens/soutraTransferScreen.dart:485` | showDialog | fenêtre sans classe importée |
| `mobile/view/walletpagem/screens/soutraWalletMainScreen.dart:111` | Navigator.pushNamed | /wallet/profile |
| `mobile/view/walletpagem/screens/soutraWalletMainScreen.dart:284` | Navigator.push | SoutraRechargeScreen |
| `mobile/view/walletpagem/screens/soutraWalletMainScreen.dart:296` | Navigator.push | SoutraTransferScreen |
| `mobile/view/walletpagem/screens/soutraWalletMainScreen.dart:397` | showModalBottomSheet | fenêtre sans classe importée |

## Compte des statuts

| Statut | Nombre |
| --- | ---: |
| PROVED_BY_CODE | 620 |
| ABSENT_BY_CODE | 172 |
| NOT_APPLICABLE | 25 |
| MANUAL_REQUIRED | 6 |
| UNRESOLVED_STATIC | 0 |

## Verdict

`STATIC_INVENTORY_COMPLETE_DEVICE_VALIDATION_PENDING`

Aucun blocage `UNRESOLVED_STATIC`. Les six parcours appareil restent hors exécution.

## Arrêt

Aucun autre fichier modifié. Aucune refonte. Aucun composant créé. Aucune navigation corrigée. Aucun fichier supprimé.

## PHASE 10C-1 — Device validation

Date d’observation : 2026-09-16. Appareil : `2409BRN2CA`, Android 16, écran 720x1640. Build observé : `flutter run` debug de `lib/main.dart`, package `com.sdealsmobile.app`. Ce n’est pas l’AAB release. Le commit de référence reste `1c4bf7158a03d78f3b71619fbe189caf1c91a15c` ; l’arbre local comporte encore `lib/main.dart` et `pubspec.yaml` non commités, donc le binaire debug n’est pas prouvé identique à ce commit. Version annoncée du projet : `1.2.3+9`.

Session : une session était déjà ouverte au départ. Elle a été fermée uniquement par le dialogue in-app « Se déconnecter », sans effacement de données, sans désinstallation. Aucun mot de passe n’a été saisi. Aucun compte n’a été créé. Aucun appel n’a été lancé. Aucune commande n’a été passée. Aucune notification de test n’a été émise. Les captures restent hors dépôt : elles contiennent des identifiants et du contenu personnel. Le rapport ne recopie ni téléphone, ni email, ni nom, ni jeton.

| Parcours | Statut | Appareil/build | Résultat observé | Écart | Preuve |
| --- | --- | --- | --- | --- | --- |
| 1 Invité vers appel | FAIL | 2409BRN2CA, debug `flutter run` | Après déconnexion, l’accueil affiche « Bonjour, Invité ». Métiers s’ouvre sans login. Une fiche s’ouvre sans login. Le bouton « Appeler » est visible. Au toucher, le composeur Android ne s’ouvre pas. L’application reste sur la même fiche et affiche « Impossible d'appeler ce numéro ». Aucun appel n’est lancé. | Le résultat attendu était le composeur avec un numéro renseigné, puis le retour Android vers la même fiche. Le numéro n’est pas transmis au composeur. | Labels d’accessibilité de la fiche invitée et message in-app après « Appeler ». Focus fenêtre resté `MainActivity`. |
| 2 Demande puis connexion | BLOCKED | 2409BRN2CA, debug `flutter run` | Depuis la même fiche invitée, « Demander un service » ouvre directement l’écran « Connectez-vous pour continuer », avec le message « Veuillez vous connecter pour demander un devis. » Le formulaire n’est pas affiché avant l’authentification. Le bouton Android Retour ramène à la même fiche. | La connexion du compte de test n’a pas été exécutée : aucun mot de passe autorisé n’était disponible, et aucun compte n’a été créé. Le retour après login réussi n’est donc pas observé. | Labels de la fiche, puis de l’écran de connexion, puis de la fiche après Retour. |
| 3 Destination après login | BLOCKED | 2409BRN2CA, debug `flutter run` | Même limite que le parcours 2 : l’action protégée « Demander un service » arrive sur le login, et l’annulation ramène à la fiche. La déconnexion, elle, a remplacé la pile par le login : le Retour Android a alors quitté l’application. | Destination réelle après une authentification réussie : non observée. Boucle login/accueil après succès : non observée. | Dialogue de déconnexion, écran login, focus lanceur après Retour post-déconnexion, fiche restaurée après Retour post-demande. |
| 4 É-marché vers contact | BLOCKED | 2409BRN2CA, debug `flutter run` | Invité, tuile É-marché ouverte. Bannière « Aucun produit disponible ». Après défilement : « Aucun produit pour le moment. » Un toucher sur la tuile Mode a ouvert la recherche globale, pas une fiche produit. | Aucun produit réel à ouvrir, donc aucune action de contact vendeur observable. Pas classé PASS. | Labels « Aucun produit disponible », « Aucun produit pour le moment. », écran de recherche après la tuile Mode. |
| 5 Notification vers destination | BLOCKED | 2409BRN2CA, debug `flutter run` | Aucune notification de test autorisée n’a été générée. Le journal debug a montré un timeout de compteur de notifications non lues, sans ouverture de notification. | Envoyer une notification exigerait le backend ou une console FCM. Interdit dans cette phase. Pas de PASS fabriqué. | Absence de notification reçue ; log debug `getUnreadNotificationCount` timeout, sans jeton recopié. |
| 6 Recherche et retour | PASS | 2409BRN2CA, debug `flutter run` | Explorer, requête `serrurier`, onglet Services sélectionné, un résultat ouvert, deux retours Android. La requête `serrurier` est encore dans le champ. L’onglet Services reste `selected=true`. Le résultat unique est encore visible. Pas de loader bloquant au retour. Pas de clavier rouvert observé. | La liste n’avait qu’un résultat : le défilement n’a pas pu être mesuré au-delà de la présence du même item. Filtres de distance observés sur la liste métier, pas sur l’écran de recherche. | Champ `serrurier`, onglets avec `selected=true` sur Services, même libellé de résultat avant et après retour. |

### Détail conservé ou perdu — parcours 6

| Élément | Observation |
| --- | --- |
| Requête | Conservée : `serrurier` |
| Onglet | Conservé : Services |
| Filtres de l’écran de recherche | Non perdus : pas d’autre filtre appliqué sur cet écran |
| Scroll | Item unique encore visible ; delta de scroll non mesurable |
| Clavier | Non rouvert au retour |
| Réseau bloquant au retour | Non observé |

### Anomalies UX observées, non corrigées

- Bannière « Pas de connexion. Vérifiez votre réseau. » au premier accueil, puis disparition après « Réessayer ». Le Wi-Fi de l’appareil était déjà validé. Timeout debug du compteur de notifications.
- « Appeler » répond au premier toucher, mais par un message d’erreur in-app, sans composeur.
- « Demander un service » saute au login sans formulaire préalable. Aucun double toucher nécessaire.
- Après déconnexion, le Retour Android quitte l’application au lieu de revenir à l’accueil invité. Après une demande refusée, le Retour revient à la fiche.
- Tuile catégorie É-marché : le toucher observé a ouvert la recherche, pas une liste produit.
- Aucun crash observé. Aucun CTA masqué par le clavier pendant ces gestes. Aucune commande ni aucun appel réel.

- PASS : 1
- FAIL : 1
- BLOCKED : 4
- NOT_RUN : 0
- anomalies UX observées : bannière réseau alors que le Wi-Fi est actif ; appel in-app impossible ; login qui remplace la demande ; Retour post-déconnexion qui sort de l’app ; catégorie É-marché qui ouvre la recherche ; aucun produit.
- code modifié : NON
- backend modifié : NON
- données réelles créées : NON
- déploiement : NON

Verdict : `CLIENT_JOURNEYS_HAVE_BLOCKERS`

## Arrêt 10C-1

Aucune correction. Aucune refonte. Aucun autre fichier modifié.
