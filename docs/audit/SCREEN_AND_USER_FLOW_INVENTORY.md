# Inventaire écrans et parcours — sdealsmobile

**Mode :** lecture de code. **UI device : STATIC_ONLY.**  
Aucun score /10 n’est inventé pour un écran non affiché sur téléphone. Les notes ci-dessous sont des notes de **lisibilité du flux dans le code** (étapes, CTA morts, messages), pas un jugement visuel.

## Navigation réelle

Shell client (`lib/mobile/view/home.dart`) : Accueil, Explorer, bouton Publier, Messagerie, Profil.  
Si rôle actif prestataire, `Home` pousse `/providermain`.

### Routes GoRouter (`lib/main.dart` L122–271)

| Path | Écran |
|---|---|
| `/` | Splash |
| `/homepage` | Home (shell) |
| `/onboarding` | Onboarding |
| `/register` | Inscription |
| `/login` | Connexion |
| `/serviceProviderWelcome` | Welcome métiers |
| `/freelanceWelcome` | Welcome freelance |
| `/emarketWelcome` | Welcome é-marché |
| `/serviceProviderRegistration` | Inscription prestataire |
| `/providermain` | Espace prestataire (auth) |
| `/prestataire-finalization` | Finalisation (auth) |
| `/vendeurDetails` | Fiche vendeur |
| `/wallet` et `/wallet/profile` | Même placeholder SoutraPay (auth) |
| `/mission-details/:missionId` | Stub « ouvrez le tableau » (auth) |
| `/chat/:conversationId` | Chat (auth) |

Auth obligatoire uniquement sur wallet, providermain, finalisation, mission, chat (`main.dart` L100–118). Accueil, recherche et fiches sont ouverts.

87 fichiers `*Screen*` sous `lib/`. Beaucoup sont poussés par `Navigator`, pas par GoRouter.

## Parcours

| Parcours | Existe | Étapes (code) | Blocage / trou |
|---|---|---|---|
| Première ouverture | Oui | Splash → onboarding si besoin → accueil | Deep-link FCM peut court-circuiter l’onboarding |
| Inscription | Oui | 1 écran + OTP si activé | Succès en `push` vers accueil (pile formulaire conservée) |
| Connexion | Oui | 1 écran (email ou téléphone + MDP, Google) | OK |
| Mot de passe oublié | Dialogue | Email seulement, `POST /forgot-password` | Pas de saisie du nouveau mot de passe dans l’app ; erreur brute `$e` |
| Accueil | Oui | 3 univers + sections proches | Bannière réseau + Réessayer présente |
| Recherche | Oui, hors barre | 6 onglets | Erreur `Text('Erreur: …')` sans retry |
| Fiche pro | Oui | Liste/carte → profil | Appel `tel:` si numéro ; libellé « Contacter » parfois = appel |
| WhatsApp | **Non** | — | Aucun `wa.me` dans l’app |
| Favoris | Oui, via Profil | Liste + détail | Détail n’ouvre pas la fiche réelle |
| Carte | Oui | Explorer, Métiers, mini-carte fiche | Popup carte : SnackBar « Fonction de contact à implémenter » |
| Marketplace | Catalogue / panier oui | É-marché → produit → panier | Pas de publication d’annonce client ; fiche vendeur « Contacter » / « Voir produits » = « à venir » |
| Profil | Oui | Menu long | Portefeuille = `pushNamed('/wallet')` incompatible avec `MaterialApp.router` |
| Notifications | Oui | Cloche et menu → alertes | Un second écran notifications n’est jamais ouvert |
| Déconnexion | Oui | Dialogue → login | OK |
| Suppression de compte client | **Non** | — | Uniquement espace prestataire, et c’est une désactivation |

## Conserver / masquer / plus tard

**Conserver :** accueil métiers, fiche prestataire, appel, recherche, favoris (si le tap ouvre la fiche), chat utile, auth, déconnexion.

**Masquer avant production :** entrée Portefeuille et tarifs SoutraPay ; FAQ qui présente le paiement comme disponible ; CTA vendeur et popup carte sans action ; stub mission ; assistant IA uniquement joignable depuis `jobPageScreenM_.dart` (fichier doublon non branché).

**Fusionner plus tard :** trois cartes (Explorer, Métiers, fiche) ; deux inboxes notifications ; wallet mock vs placeholder honnête.

**Supprimer plus tard (pas avant prod) :** `morePage`, `rondPage`, `notification_screen` orphelin, écrans recharge/transfert mock non routés, `jobPageScreenM_.dart`.

## Notation familles (code seulement, /10)

| Famille | Note flux | P |
|---|---|---|
| Splash / onboarding / login / register | 7 | — |
| Accueil / explorer / fiche + appel | 7 | P2 densité |
| Recherche | 5 | P1 message technique |
| Carte popup contact | 3 | P1 CTA mort |
| É-marché / vendeur | 4 | P1 « à venir » |
| Profil / portefeuille | 3 | P1 trompeur + navigation cassée |
| Suppression compte client | 0 | P0 |
| Chat / alertes | 6 | P2 double modèle |

P0 visuels device : aucun prouvé (STATIC_ONLY). P0 produit : suppression de compte absente.
