# Matrice de rétention — suppression de compte (Phase 10B)

| Donnée | Action | Justification | Durée |
|---|---|---|---|
| Identité utilisateur (nom, email, téléphone, photo, googleId) | Anonymisé | Droit à l’effacement / Play User Data | Immédiat |
| Mot de passe | Remplacé (hash aléatoire) | Empêche reconnexion | Immédiat |
| JWT / refresh / FCM | Supprimé | Révocation session | Immédiat |
| Favoris | Supprimé | Donnée personnelle non partagée | Immédiat |
| Notifications | Supprimé | Donnée personnelle | Immédiat |
| Avis | Conservé (auteur anonymisé via user) | Intégrité marketplace / contreparties | Illimitée (anonymisé) |
| Commandes / réservations | Conservé (lien user anonymisé) | Obligations légales / litiges | Selon obligations locales |
| Conversations / messages | Conservé (expéditeur anonymisé) | Intégrité conversation contrepartie | Illimitée (anonymisé) |
| Profils prestataire / freelance / vendeur | Suspendu | Évite hard-delete cassant les relations | Jusqu’à purge admin |
| Médias Cloudinary (si liés au user) | Non hard-delete naïf en MVP | Évite état incohérent ; reprise manuelle/admin | À traiter en suivi |

**Interdit comme résultat final :** `isActive=false` seul (gel) sans anonymisation / révocation.
