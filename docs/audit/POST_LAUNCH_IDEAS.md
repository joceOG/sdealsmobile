# Idées après lancement

Aucune de ces idées ne justifie de retarder la production une fois les P0 traités.  
Chaque idée répond à un trou vu dans le code, pas à une mode.

## Trois améliorations simples (peuvent tenir dans la mise à jour si P0 est bouclé, sinon J+7)

| Idée | Problème prouvé | Qui | Gain | Complexité | Risque | Mesure |
|---|---|---|---|---|---|---|
| Accueil : un bouton « Trouver un pro près de moi » au-dessus des 3 univers | 3 univers + Publier avant le geste principal (`homePageScreenM`, `home.dart`) | Nouveau client | Moins d’hésitation | S | Faible | Taux d’ouverture fiche depuis l’accueil |
| Erreur recherche en français + Réessayer | `searchPageScreenM` affiche `Erreur: ${state.error}` | Chercheur | Compréhension | S | Nul | Moins d’abandons sur écran erreur |
| Détail favori ouvre la fiche réelle | `FavoriteDetailScreenM` n’a pas de navigation vers le profil/produit | Client qui bookmark | Le favori sert | S | Faible | Taps favori → fiche |

## Trois après lancement

| Idée | Problème | Qui | Gain | Complexité | Risque | Mesure |
|---|---|---|---|---|---|---|
| WhatsApp `wa.me` sur la fiche si le numéro existe | Aucun lancement WhatsApp ; l’appel existe | Client qui ne veut pas appeler | Contact plus facile | S | Numéro mal formé | Part des contacts WhatsApp vs `tel:` |
| Minify + shrink release | `isMinifyEnabled = false` | Tous | APK plus petit, strings moins lisibles | M | Régression reflection | Taille AAB avant/après |
| Pagination réelle des métiers | `fetchPrestataires` charge la liste entière | Téléphones modestes | Scroll plus fluide | M | Régression filtres | Temps 1re liste, mémoire |

## Deux idées différenciantes (plus tard, à tester)

| Idée | Problème | Qui | Gain | Complexité | Risque | Mesure |
|---|---|---|---|---|---|---|
| Badge « profil vérifié » sur la fiche, seulement si un statut serveur existe déjà | La confiance n’est pas lisible au premier regard (pas d’audit visuel device ; le KYC prestataire existe côté dashboard/API) | Client qui hésite à appeler | Confiance sans nouveau métier | M | Afficher « vérifié » à tort | Taux d’appel sur fiches badgées vs non |
| Recherche sans résultat : 3 métiers proches au lieu d’un empty mort | Empty recherche existe ; pas de rebond observé dans le code | Recherche vaine | Moins d’impasse | M | Suggestions hors sujet | Taux de second tap après 0 résultat |

## À ne pas faire avant une V1 publique stable

Refonte design complète, chat IA (`ai_assistant_chat_screen` non branché), gamification, SoutraPay / paiement in-app, nouveau chat si l’appel suffit.
