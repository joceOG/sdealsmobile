# SOUTRALI DEALS — Illustration & Motion Identity System

**Version proposée :** 1.1 — candidate à validation  
**Date :** 5 octobre 2026  
**Périmètre :** illustrations 2D, empty states, onboarding, feedback et motion design de l’application mobile  
**Statut :** définition uniquement — aucune image, aucun SVG, aucun Lottie et aucun Rive générés

**Révision 1.1 :** orange exclu des illustrations ; bleu pétrole et beige chaud adoptés comme palette secondaire Illustration.

---

## 0. Base d’audit et niveau de preuve

Cette proposition s’appuie sur les éléments SOUTRALI réellement disponibles :

- l’audit du design system Flutter de `sdealsmobile`, branche `jordan`, commit de référence `1c4bf71`, version `1.2.3+9` ;
- les composants relevés dans le code : `SDButton`, `SDInput`, `SDCard`, `SDEntityCard`, `SDWhiteAppBar`, `SDAppBar`, `GuestAuthState`, `SDErrorState`, `SDLoadingInline` ;
- les captures récentes de l’application entre le 26 septembre et le 4 octobre 2026 ;
- le cahier « SOUTRALI DEALS — Illustration & Motion Design System » fourni le 5 octobre 2026.

### Limite de vérification

Le dépôt Flutter courant, le fichier source des couleurs et le logo vectoriel ne sont pas présents dans le dossier de travail de cette session. Quatre tokens ont néanmoins été relevés directement lors de l’audit antérieur du code : `primary500`, `primary600`, `secondary` et `neutral900`. Le blanc et le fond `#FAFAFA` sont visibles dans les rendus actuels, mais leur déclaration source n’a pas été relue aujourd’hui.

Conséquence :

- les quatre tokens de marque ci-dessous sont **confirmés par lecture du code** ;
- le blanc et `#FAFAFA` sont **confirmés visuellement dans l’application rendue** ;
- les neutres complémentaires portent explicitement le statut **Illustration**, car ils sont ajoutés pour rendre le système exploitable sans prétendre qu’ils existaient déjà dans Flutter ;
- le bleu pétrole et le beige chaud sont introduits comme tokens Illustration sur décision de direction artistique du 5 octobre 2026 ; ils ne remplacent pas les tokens Flutter existants.

Cette distinction évite d’inventer une couleur et permet de verrouiller la direction artistique de façon honnête.

---

# 1. Palette officielle exacte

## 1.1 Couleurs détectées dans le projet

| Rôle | Nom | HEX | RGB | Utilisation | Niveau de preuve |
| --- | --- | --- | --- | --- | --- |
| Primary | `primary500` | `#1CBF3F` | `28, 191, 63` | Couleur de marque, actions positives, point focal principal | Confirmé par audit du code Flutter |
| Primary strong | `primary600` | `#1AA12A` | `26, 161, 42` | CTA renforcé, état actif, contraste du vert principal | Confirmé par audit du code Flutter |
| Secondary existant, exclu des illustrations | `secondary` | `#F97316` | `249, 115, 22` | Token présent dans Flutter, mais non retenu dans la collection d’illustrations | Confirmé par audit du code Flutter |
| Background | `app background` | `#FAFAFA` | `250, 250, 250` | Fond de plusieurs écrans récents | Confirmé dans le rendu actuel ; déclaration source à recontrôler |
| Surface | `white surface` | `#FFFFFF` | `255, 255, 255` | Cartes, champs, surfaces et fonds internes | Confirmé dans le rendu actuel et les audits |
| Text dark | `neutral900` | `#171717` | `23, 23, 23` | Titres, texte fort et contraste sombre | Confirmé par audit du code Flutter |

### Décision sur le bleu, le beige et l’orange

Le token orange `#F97316` existe bien dans Flutter, mais il est **exclu du système d’illustration** par décision de direction artistique. Il ne doit apparaître ni dans les personnages, ni dans les objets, ni dans les micro-accents de la collection fondatrice.

Le système Illustration adopte un mélange contrôlé de :

- **bleu pétrole `#2F6F8F`** comme accent secondaire fonctionnel ;
- **beige chaud `#E7D8C5`** comme neutre humain et chaleureux ;
- **beige clair `#F5EFE6`** pour les surfaces ou vêtements secondaires.

Ces couleurs sont de nouveaux tokens Illustration explicitement validés. Elles ne sont pas présentées comme des couleurs déjà présentes dans Flutter et ne modifient pas l’identité principale verte de l’application.

### Couleur exclue du noyau mobile

Le vert `#159630`, observé dans l’application terrain SDEALSIDENTIFICATION, n’est pas retenu comme token officiel de la collection mobile SOUTRALI DEALS. Il appartient à un autre sous-produit et créerait une troisième variante de vert inutile.

## 1.2 Palette Illustration SOUTRALI

Les six couleurs précédentes restent intactes. Les couleurs suivantes complètent uniquement le langage d’illustration.

| Groupe | Token Illustration | HEX | RGB | Rôle |
| --- | --- | --- | --- | --- |
| Marque | `ill-brand-green` | `#1CBF3F` | `28, 191, 63` | Point focal principal |
| Marque | `ill-brand-green-strong` | `#1AA12A` | `26, 161, 42` | Petit contraste vert, état actif |
| Accent secondaire | `ill-accent-blue` | `#2F6F8F` | `47, 111, 143` | Technologie, accès, communication et petit contrepoint au vert |
| Neutre chaud | `ill-warm-beige` | `#E7D8C5` | `231, 216, 197` | Vêtements, mobilier et chaleur humaine |
| Neutre chaud clair | `ill-warm-beige-light` | `#F5EFE6` | `245, 239, 230` | Grandes surfaces secondaires discrètes |
| Encre | `ill-ink` | `#27302A` | `39, 48, 42` | Contours des illustrations |
| Texte/UI simulée | `ill-text-dark` | `#171717` | `23, 23, 23` | Lignes fortes et détails sombres |
| Neutre sombre | `ill-neutral-700` | `#68706A` | `104, 112, 106` | Vêtements, lignes secondaires, objets |
| Neutre moyen | `ill-neutral-300` | `#C9D0CB` | `201, 208, 203` | Bordures, séparateurs, métal clair |
| Neutre clair | `ill-neutral-100` | `#EEF2EF` | `238, 242, 239` | Vêtements clairs et surfaces secondaires |
| Surface | `ill-surface` | `#FFFFFF` | `255, 255, 255` | Cartes fictives et objets clairs |
| Fond de prévisualisation | `ill-canvas-preview` | `#FAFAFA` | `250, 250, 250` | Prévisualisation seulement ; jamais incorporé à l’asset |
| Teinte verte | `ill-green-tint` | `#E8F8EC` | `232, 248, 236` | Grande zone verte non saturée |
| Teinte bleue | `ill-blue-tint` | `#E8F1F5` | `232, 241, 245` | Surface technologique ou informationnelle discrète |

Les nouveaux neutres, l’encre et les deux teintes sont des **tokens Illustration**. Ils ne remplacent pas les tokens Flutter et ne doivent pas être présentés comme des couleurs déjà présentes dans le code.

## 1.3 Palette humaine

Pour assurer la continuité des personnages, les carnations sont également tokenisées. Elles ne participent pas au statut ou à la hiérarchie de marque.

| Token | HEX | Usage |
| --- | --- | --- |
| `skin-01-deep` | `#5A2F1F` | Carnation profonde |
| `skin-02-deep-warm` | `#70402B` | Carnation profonde chaude |
| `skin-03-medium` | `#8C573B` | Carnation moyenne |
| `skin-04-medium-light` | `#B97853` | Carnation moyenne claire |
| `skin-05-light-warm` | `#D99B73` | Carnation claire chaude |

Chaque personnage officiel conserve son token de base. Une ombre de peau peut être obtenue avec une seule valeur 8 à 12 % plus sombre ; aucun modelé réaliste, blush ou rendu brillant.

---

# 2. Ratio d’utilisation des couleurs

Le ratio est calculé sur les **zones peintes**, en excluant la transparence du canvas.

| Famille | Ratio cible | Limite absolue |
| --- | ---: | ---: |
| Neutres froids + couleurs humaines naturelles | 55–62 % | Minimum 52 % |
| Famille beige | 10–15 % | Maximum 18 % |
| Famille verte complète | 18–24 % | Maximum 26 % |
| Bleu pétrole | 5–8 % | Maximum 10 % |
| Autres couleurs contextuelles validées | 0–5 % | Maximum 5 % |

Règles supplémentaires :

- le vert saturé `#1CBF3F` ne dépasse jamais **12 %** de la surface peinte ; les grandes zones utilisent `#E8F8EC` ;
- une illustration contient un seul point focal vert dominant ;
- le bleu reste secondaire : il ne concurrence jamais le point focal vert et ne dépasse pas 10 % de la surface peinte ;
- le beige peut occuper une grande zone de vêtement ou de mobilier, mais jamais le point focal ;
- l’orange est exclu de tous les assets d’illustration, même comme petite étoile ou décoration ;
- aucune illustration ne doit être « entièrement verte » ;
- les carnations ne sont jamais recolorées avec une couleur de marque.

---

# 3. Style visuel définitif — 10 règles

1. **Construction 2D vectorielle en aplats :** formes fermées propres, sans texture raster, sans photoréalisme, sans 3D, sans grain et sans dégradé décoratif.
2. **Anatomie adulte stylisée :** personnage de 6,25 à 6,75 têtes de hauteur, posture crédible, tête jamais surdimensionnée et articulations lisibles.
3. **Perspective limitée :** vue frontale ou trois-quarts légère ; profondeur obtenue par chevauchement, jamais par perspective extrême, fisheye ou isométrie complexe.
4. **Distribution chromatique contrôlée :** majorité de neutres, tons humains et beige ; 18–24 % de verts ; bleu pétrole limité à 10 % ; orange absent ; un seul point focal saturé.
5. **Contour hybride constant :** contour principal sombre sur les silhouettes et objets clés ; détails internes simplifiés ou séparés par les aplats.
6. **Visages à cinq familles de signes :** yeux, sourcils, nez, bouche et oreilles dessinés avec des formes minimales identiques pour toute la bibliothèque.
7. **Ombres de contact uniquement :** aucune lumière volumétrique, aucun glow et aucun modelé réaliste sur les visages ou vêtements.
8. **Une idée par composition :** un sujet ou objet principal, deux à trois objets secondaires maximum et 35–45 % d’espace négatif dans la zone utile.
9. **UI abstraite :** aucune phrase, aucun faux nom et aucun chiffre ; les cartes utilisent avatar, lignes, badges et boutons abstraits rappelant SOUTRALI.
10. **Continuité avant nouveauté :** réutiliser personnages, smartphone, cartes, badges et objets officiels ; tout nouvel élément doit reprendre palette, contour, rayon et niveau de détail existants.

---

# 4. Contours

## Décision

Le système officiel est **hybride à contour contrôlé**.

Le contour est présent sur :

- la silhouette externe des personnages ;
- les cheveux lorsqu’ils se détachent du visage ;
- les mains lorsqu’elles touchent un objet ;
- le smartphone, les cartes principales et les objets métier ;
- les formes qui se confondraient sans séparation.

Le contour disparaît sur :

- les ombres ;
- les aplats décoratifs ;
- les reflets ;
- les lignes fictives à l’intérieur des cartes UI ;
- deux zones adjacentes déjà clairement distinguées par leur couleur.

## Standard technique

- couleur : `ill-ink #27302A` ;
- contour externe : **5 unités** sur le canvas maître de 1000 px, soit environ 1,3 px à 260 px d’affichage ;
- contour interne utile : **4 unités** sur le canvas maître ;
- extrémités : `round cap` ;
- jointures : `round join` ;
- opacité : 100 % sur silhouette, 72–85 % sur détail secondaire ;
- noir pur `#000000` interdit ;
- aucune alternance entre illustration sans contour et contour noir épais.

---

# 5. Ombres

## Décision

Utiliser uniquement des **petites ombres vectorielles de contact**.

Règles :

- couleur : `#171717` ;
- opacité : 6–9 % ;
- direction : 4 à 6 unités vers le bas et 2 unités vers la droite sur le canvas maître ;
- blur visuel : 0 à 4 unités maximum ; préférer une ellipse ou une forme douce en aplat à un filtre de blur ;
- autorisées sous les pieds, sous un téléphone posé, sous une carte flottante majeure ou à la jonction de deux objets ;
- interdites sur chaque petit composant, autour des visages, sous toutes les cartes ou pour simuler une profondeur 3D ;
- une illustration Empty State utilise au maximum deux ombres de contact.

Les ombres ne sont jamais animées indépendamment. Elles suivent leur objet parent.

---

# 6. Formes et géométrie

Le langage géométrique reprend les décisions du produit : rayons de 8, 12, 16 et 24 dp.

| Élément | Géométrie |
| --- | --- |
| Carte principale | Rectangle arrondi, rayon visuel équivalent à 16 dp |
| Contrôle / smartphone interne | Rayon visuel équivalent à 12 dp |
| Chip / petit badge | Rayon visuel équivalent à 8 dp |
| Avatar | Cercle parfait |
| Bouton abstrait | Rectangle arrondi, rayon 25–35 % de sa hauteur ; pas forcément pilule complète |
| Bulle de message | Rectangle arrondi avec une seule pointe courte |
| Décor | Petite forme organique ou cercle ; jamais une grande « blob » derrière toute la scène |

Règles générales :

- angles légèrement arrondis, jamais coupants sauf outil métier qui l’exige ;
- cercles réservés aux avatars, badges, points de statut et très petites décorations ;
- objets flottants alignés sur une grille invisible de 8 unités ;
- asymétrie recommandée 55/45, avec un équilibre visuel clair ;
- deux formes décoratives maximum ;
- aucune accumulation de confettis, feuilles, étoiles ou ronds sans fonction ;
- aucun cadre blanc ou rectangle de fond englobant l’illustration entière.

---

# 7. Personnages officiels

Les personnages A à F forment la distribution fondatrice. Leur visage, carnation, coiffure, silhouette et détails distinctifs doivent rester identifiables d’une scène à l’autre.

## PERSONNAGE A — Awa, cliente mobile

- **Présentation :** femme ;
- **Âge visuel :** 24–30 ans ;
- **Carnation :** `skin-02-deep-warm #70402B` ;
- **Coiffure :** petites twists attachées en chignon haut compact, deux mèches latérales courtes ;
- **Silhouette :** taille moyenne, ligne fine à moyenne, épaules souples ;
- **Tenue habituelle :** surchemise vert pâle, haut blanc cassé, pantalon droit anthracite, baskets sobres ;
- **Couleurs dominantes :** `ill-green-tint`, blanc, anthracite ;
- **Rôle principal :** cliente, recherche, profil, favoris, messagerie ;
- **Personnalité visuelle :** attentive, autonome, chaleureuse sans exagération.

## PERSONNAGE B — Kader, professionnel indépendant

- **Présentation :** homme ;
- **Âge visuel :** 28–35 ans ;
- **Carnation :** `skin-03-medium #8C573B` ;
- **Coiffure :** coupe basse avec contour net, barbe très courte stylisée ;
- **Silhouette :** taille moyenne à haute, carrure moyenne ;
- **Tenue habituelle :** polo gris clair, pantalon bleu-charbon, détail vert sur manche ou poche ;
- **Couleurs dominantes :** gris, charbon, petit accent vert ;
- **Rôle principal :** prestataire de service, professionnel local ;
- **Personnalité visuelle :** fiable, accessible, posé.

## PERSONNAGE C — Mariam, entrepreneure

- **Présentation :** femme ;
- **Âge visuel :** 33–41 ans ;
- **Carnation :** `skin-04-medium-light #B97853` ;
- **Coiffure :** tresses mi-longues regroupées en queue basse ;
- **Silhouette :** taille moyenne, posture droite, formes adultes naturelles ;
- **Tenue habituelle :** veste courte écrue, top anthracite, pantalon vert très sombre, chaussures plates ;
- **Couleurs dominantes :** écru, beige chaud, vert sombre, petit accent bleu pétrole ;
- **Rôle principal :** entrepreneure, entreprise cliente, supervision ou validation ;
- **Personnalité visuelle :** décision, calme, professionnalisme.

## PERSONNAGE D — Yao, technicien / artisan

- **Présentation :** homme ;
- **Âge visuel :** 36–46 ans ;
- **Carnation :** `skin-01-deep #5A2F1F` ;
- **Coiffure :** cheveux très courts, ligne simple, sans casque par défaut ;
- **Silhouette :** carrure robuste, avant-bras légèrement marqués, proportions toujours stylisées ;
- **Tenue habituelle :** chemise de travail gris-bleu à manches retroussées, pantalon de travail anthracite, chaussures fermées ;
- **Couleurs dominantes :** gris-bleu, anthracite, poignée ou poche verte ;
- **Rôle principal :** technicien, artisan, réparation, intervention ;
- **Personnalité visuelle :** précis, compétent, ancré dans le réel.

## PERSONNAGE E — Éli, freelance digital

- **Présentation :** personne androgyne à expression masculine légère ;
- **Âge visuel :** 23–31 ans ;
- **Carnation :** `skin-03-medium #8C573B` ;
- **Coiffure :** courtes locs souples orientées vers un côté ;
- **Silhouette :** fine, légèrement grande, posture concentrée ;
- **Tenue habituelle :** t-shirt écru, veste légère anthracite ouverte, pantalon droit, sneakers ;
- **Couleurs dominantes :** écru, anthracite, vert sur l’accessoire numérique ;
- **Rôle principal :** développement, design, rédaction, travail à distance ;
- **Personnalité visuelle :** créatif, analytique, discret.

## PERSONNAGE F — Moussa, client adulte

- **Présentation :** homme ;
- **Âge visuel :** 43–53 ans ;
- **Carnation :** `skin-02-deep-warm #70402B` ;
- **Coiffure :** cheveux ras très courts avec tempes légèrement marquées ;
- **Silhouette :** taille moyenne, morphologie pleine mais non caricaturale ;
- **Tenue habituelle :** chemise claire manches courtes, pantalon brun-charbon, mocassins simples ;
- **Couleurs dominantes :** blanc cassé, brun, vert sur le téléphone ou l’objet focal ;
- **Rôle principal :** client particulier, demande de service, commande, assistance ;
- **Personnalité visuelle :** pragmatique, rassuré, direct.

### Règle de continuité

On peut modifier un vêtement selon le métier ou la scène, mais jamais simultanément la coiffure, la silhouette, la carnation et le visage. Deux caractéristiques distinctives au minimum doivent rester stables.

---

# 8. Proportions humaines

- hauteur totale : **6,25 à 6,75 têtes** ; cible standard 6,5 ;
- hauteur de tête : environ **15,4 %** du corps ;
- épaules : 1,75 à 2,25 largeurs de tête selon la morphologie, sans règle rigide liée au sexe ;
- cou : court à moyen, jamais filiforme ;
- coudes : proches de la taille ;
- poignets : au niveau du haut des cuisses ;
- jambes : environ 50–53 % de la hauteur totale ;
- mains : longueur équivalente à 65–75 % du visage ; quatre doigts lisibles au maximum, pouce séparé ;
- pieds : simples, orientés avec la pose, sans chaussures démesurées ;
- tête jamais supérieure à 17 % du corps ;
- aucune taille de guêpe extrême, épaules héroïques, musculature réaliste ou anatomie de mannequin publicitaire.

Le corps reste adulte même à petite taille. Les poses utilisent une ligne d’action faible, avec poids posé sur une jambe et articulation naturelle des bras.

---

# 9. Visages

Tous les visages utilisent la même grille :

- ligne des yeux à environ 46 % de la hauteur de tête ;
- base du nez à environ 63 % ;
- bouche à environ 74 % ;
- oreilles entre la ligne des yeux et la base du nez ;
- yeux : deux petits ovales ou traits courts `ill-ink`, sans iris détaillé ni grand blanc cartoon ;
- sourcils : un trait légèrement courbe par œil, épaisseur identique au contour interne ;
- nez : un seul trait ou une petite forme en L doux ;
- bouche : une ligne simple, droite ou courbe ; dents visibles seulement dans un sourire ponctuel et discret ;
- oreilles : forme en C simplifiée, sans détail interne complexe ;
- expressions : variation des sourcils, de la courbe de bouche et de l’orientation de la tête, jamais déformation du visage.

Expressions officielles : neutre attentive, légère satisfaction, concentration, interrogation calme et soulagement. Cris, bouche ouverte exagérée, yeux géants et emojis faciaux sont interdits.

---

# 10. Vêtements et métiers

Une profession doit être comprise grâce à **un vêtement fonctionnel maximum et un ou deux objets**, pas grâce à un uniforme caricatural.

| Profil | Signaux autorisés | À éviter |
| --- | --- | --- |
| Client | Smartphone, tenue urbaine simple, sac discret | Caddie, colis ou argent si l’état ne concerne pas l’achat |
| Artisan | Chemise de travail, boîte à outils ou outil unique | Casque systématique, dix outils autour du personnage |
| Technicien | Poche fonctionnelle, petit tournevis/testeur, tablette | Combinaison futuriste, câbles partout |
| Freelance | Ordinateur portable, carnet ou stylet | Hoodie de hacker, néons, code illisible en arrière-plan |
| Professionnel digital | Laptop, smartphone, casque posé | Casque sur les oreilles dans chaque scène |
| Entrepreneur | Veste légère, tablette ou dossier | Costume-cravate obligatoire, posture autoritaire clichée |
| Commerçant | Polo ou chemise, petit terminal ou fiche produit | Étal rural par défaut, accumulation de marchandises |

Les vêtements sont contemporains et adaptés à Abidjan : tissus légers, coupes urbaines, chaussures réalistes. Les motifs culturels peuvent apparaître ponctuellement sur une petite zone, jamais sur toute la distribution ni sur chaque illustration.

---

# 11. Objets récurrents

| Objet | Construction officielle |
| --- | --- |
| Smartphone | Ratio proche de 9:19, contour `ill-ink`, écran blanc, rayon 12 %, un seul élément vert interne |
| Carte prestataire | Ratio 5:3, surface blanche, avatar circulaire, deux lignes neutres, un chip vert et aucun texte |
| Carte profil | Ratio 4:5, grand avatar, deux lignes abstraites, petit contrôle d’accès neutre |
| Bulle message | Rectangle arrondi, une pointe courte, version principale vert pâle et version secondaire blanche |
| Cœur | Forme géométrique douce, vert principal lorsqu’il est focal, contour facultatif selon contraste |
| Étoile | Quatre ou cinq branches simples, bleu pétrole uniquement, très petite |
| Document / commande | Feuille blanche à coin plié, contour sombre, deux lignes neutres et statut vert |
| Pin localisation | Goutte simple avec centre circulaire, vert principal ; aucune carte détaillée obligatoire |
| Cloche | Contour sombre, petit badge vert ; pas de rouge clignotant |
| Loupe | Cercle sombre ou vert et manche court, angle de 40–45° |
| Badge vérifié | Rosace ou cercle vert avec coche blanche ; utilisé uniquement si le statut métier est réellement vérifié |
| Boîte à outils | Corps gris neutre, poignée verte, une seule séparation interne |
| Ordinateur | Écran 16:10, contour sombre, surface gris clair, point de statut vert facultatif |

Tous les objets sont construits avec les mêmes contours, rayons et ombres. La carte d’Afrique, le logo complet, les pièces de monnaie, les colis et les éclairs décoratifs ne sont jamais ajoutés automatiquement.

---

# 12. Cartes et éléments UI dans les illustrations

Les cartes fictives doivent évoquer SOUTRALI sans copier un écran Flutter complet.

- fond : `#FFFFFF` ;
- rayon : équivalent visuel à 16 dp ;
- bordure : `ill-neutral-300`, équivalent à 1 dp ;
- ombre : aucune par défaut ; ombre de contact 6 % uniquement si la carte est l’objet principal flottant ;
- avatar : cercle de 20 à 24 % de la hauteur de la carte ;
- lignes fictives : deux ou trois rectangles arrondis, longueurs 58 %, 42 % et éventuellement 28 % ;
- badge : cercle ou chip de 14 à 18 % de la hauteur ;
- bouton abstrait : largeur 28–36 % de la carte, vert, sans mot ni glyphe complexe ;
- nombre maximal d’éléments internes : six ;
- aucun vrai nom, prix, métier, chiffre, logo ou phrase ;
- aucune barre de navigation complète, clavier ou statut système à l’intérieur de l’illustration.

---

# 13. Composition mobile officielle — Empty States

## Canvas

- ratio : **5:4** ;
- canvas maître : **1000 × 800** ;
- `viewBox` : `0 0 1000 800` ;
- safe area : 80 unités à gauche/droite et 64 unités en haut/bas ;
- fond : transparent.

## Placement

- personnage ou objet principal : centré entre x = 440 et x = 560, avec décalage autorisé jusqu’à 8 % ;
- point focal : dans les 55 % centraux du canvas ;
- sujet principal : 58–68 % de la largeur utile et 68–78 % de la hauteur utile ;
- espace négatif : 35–45 % de la zone utile ;
- objets secondaires : maximum trois ;
- aucun objet essentiel dans les 8 % périphériques ;
- aucun mouvement ne franchit la safe area.

## Intégration Flutter

- largeur d’affichage : 220 à 300 dp ;
- largeur recommandée : **264 dp** ;
- hauteur recommandée : **211 dp** ;
- rendu : `BoxFit.contain` ;
- marge horizontale minimale dans l’écran : 32 dp ;
- espace entre illustration et titre natif : 20–24 dp ;
- l’illustration ne doit jamais contenir les CTA « Se connecter » ou « Créer un compte » : ces boutons restent natifs.

---

# 14. Niveaux de détail

## HERO / ONBOARDING

- un à deux personnages ;
- un objet principal et jusqu’à cinq objets secondaires utiles ;
- 22 à 32 groupes/calques ;
- trois plans visuels maximum ;
- trois couleurs de marque visibles maximum ;
- un détail métier par personnage ;
- aucun décor plein écran.

## EMPTY STATE

- un personnage **ou** un objet principal dominant ;
- deux à trois objets secondaires ;
- 12 à 24 groupes/calques ;
- un seul plan principal et un léger chevauchement ;
- un seul point focal vert ;
- visage et mains lisibles à 220 dp.

## FEEDBACK

- aucun personnage par défaut ;
- un objet principal et zéro à deux particules ;
- 5 à 10 groupes/calques ;
- composition occupant 40–55 % du canvas ;
- lecture immédiate en moins d’une seconde.

---

# 15. Motion Design officiel

## ENTER

L’entrée globale est gérée par Flutter autour de l’asset, pour éviter de la dupliquer dans chaque fichier.

- durée : **220 ms** ;
- opacity : `0 → 1` ;
- translation Y : `6 dp → 0` ;
- scale : `0.985 → 1` ;
- easing : `easeOutCubic`, équivalent `cubic-bezier(0.33, 1, 0.68, 1)` ;
- aucun rebond et aucun overshoot ;
- en Reduce Motion : opacity seule sur 120 ms, ou affichage immédiat.

## IDLE

- durée de boucle standard : **4 000 ms** ;
- repos initial : **800 ms** ;
- repos cumulé : au moins 55 % de la boucle ;
- maximum trois éléments animables dans le fichier ;
- maximum deux éléments en mouvement simultané ;
- translation : 2–4 dp, maximum absolu 6 dp ;
- rotation : ±1,5°, maximum absolu 2° ;
- scale courant : `1 → 1.04 → 1` ; maximum `1.06` pour cœur ou badge ;
- opacity : `0.65 → 1` seulement pour bulle, badge ou petite étoile ;
- le corps entier d’un personnage ne flotte jamais en continu ;
- la boucle revient exactement à la frame de repos.

Chronologie de base :

- 0–800 ms : repos ;
- 800–1 200 ms : premier micro-événement ;
- 1 250–1 700 ms : second micro-événement éventuel ;
- 1 700–4 000 ms : repos complet.

## SUCCESS

- durée totale : **560 ms** ;
- non bouclé ;
- coche : opacity `0 → 1`, scale `0.72 → 1.06 → 1` ;
- deux petites particules maximum, disparition avant 450 ms ;
- illustration totalement statique à partir de 560 ms.

## ERROR

- aucune boucle ;
- entrée douce de 180 ms ;
- option autorisée : pictogramme d’erreur `0.96 → 1` sur 220 ms une seule fois ;
- aucune secousse, aucun clignotement, aucun rouge pulsant et aucune vibration visuelle permanente.

---

# 16. Règle Lottie / Rive

## Lottie

Utiliser lorsque :

- l’animation est autonome ;
- la chronologie est déterministe ;
- il s’agit d’un Empty State, d’un onboarding ou d’un feedback ;
- la boucle ne dépend pas d’une variable métier ;
- trois éléments animés ou moins suffisent.

## Rive

Utiliser uniquement lorsque :

- une State Machine est nécessaire ;
- l’asset réagit au tap, au drag ou à une valeur continue ;
- plusieurs états métier doivent partager le même fichier, par exemple `idle → loading → success` ;
- l’interaction ne peut pas être reproduite proprement avec Flutter + Lottie.

## Recommandation pour la collection fondatrice

La collection des 12 illustrations utilisera :

- **SVG optimisé** comme version statique et fallback ;
- **Lottie** pour les assets réellement animés ;
- **aucun Rive** dans la première collection.

Cette décision réduit le poids, le risque technique et la complexité de maintenance.

---

# 17. Contraintes techniques

| Sujet | Règle |
| --- | --- |
| Canvas | 1000 × 800, ratio 5:4 |
| ViewBox SVG | `0 0 1000 800` |
| Fond | Transparent, sans rectangle de fond |
| Preview | PNG 2000 × 1600 maximum, validation uniquement |
| SVG cible | ≤ 75 Ko optimisé ; maximum absolu 120 Ko |
| Lottie cible | ≤ 180 Ko JSON brut ; maximum absolu 250 Ko ; idéal ≤ 60 Ko compressé |
| Rive futur | ≤ 150 Ko sauf justification documentée |
| Calques Empty | 12–24 groupes, 3 groupes animés maximum |
| Calques Hero | 22–32 groupes |
| Calques Feedback | 5–10 groupes |
| Points vectoriels | Empty ≤ 1 200 ; Hero ≤ 2 000 ; Feedback ≤ 400 |
| Framerate | 30 fps |
| Raster embarqué | Interdit en production SVG/Lottie |
| Masques | Maximum deux, uniquement si indispensables |
| Effets | Pas de glow, 3D, texture, blur complexe, expression AE ou plugin |

### Découpage des parties animées

- chaque objet animé possède son groupe propre ;
- bras, main et objet tenu sont séparés seulement si le mouvement l’exige ;
- les points d’ancrage sont placés sur les articulations ou centres de rotation réels ;
- les parties cachées sous un vêtement se chevauchent suffisamment pour éviter les trous pendant la rotation ;
- le téléphone, la carte, le badge et les décorations ne sont jamais fusionnés s’ils doivent bouger séparément ;
- les ombres suivent le groupe parent ;
- la frame 0 et la frame de repos constituent une illustration complète ;
- aucune information essentielle ne dépend du mouvement ;
- le composant Flutter doit désactiver l’idle loop lorsque la préférence système de réduction des animations est active.

---

# 18. Nommage des assets

## Structure

`sd_ill_<id>_<type>_<sujet>_<etat>_<format>.<extension>`

Règles :

- `sd` : SOUTRALI DEALS ;
- `ill` : illustration ;
- `id` : numéro immuable sur trois chiffres ;
- `type` : `hero`, `empty` ou `feedback` ;
- noms en anglais technique, minuscules, `snake_case`, sans accent ;
- le numéro reste identique dans tous les formats ;
- aucune version `final_final_2` ; la version est gérée par Git.

## Exemple pour l’illustration maîtresse

- statique : `sd_ill_001_empty_profile_guest_static.svg` ;
- Lottie : `sd_ill_001_empty_profile_guest_lottie.json` ;
- Rive éventuel : `sd_ill_001_empty_profile_guest.riv` ;
- preview : `sd_ill_001_empty_profile_guest_preview.png` ;
- fiche : `sd_ill_001_empty_profile_guest_spec.md`.

## Dossiers recommandés

```text
assets/illustrations/static/
assets/illustrations/lottie/
assets/illustrations/rive/
assets/illustrations/previews/
assets/illustrations/specs/
```

---

# 19. Cadre de l’illustration maîtresse — Profil non connecté

## Message à transmettre

L’utilisateur se trouve dans l’espace personnel de SOUTRALI mais doit s’identifier pour y accéder. L’illustration doit communiquer :

- identité personnelle ;
- profil ou compte ;
- smartphone ;
- accès à un espace personnel ;
- invitation calme à se connecter ou à créer un compte.

## Éléments interdits dans cet asset

- panier, sac de courses ou produit ;
- colis, livraison ou véhicule ;
- document de commande ;
- pin de localisation ;
- outil d’artisan ;
- bulle de recherche ;
- carte prestataire ;
- badge « vérifié » ;
- coche de succès ;
- texte « Connexion » ou « Inscription » dans l’image ;
- logo ou carte d’Afrique.

## Métadonnées prévues

- **ID :** `SD-ILL-001` ;
- **Nom :** `empty_profile_guest` ;
- **Écran :** Profil ;
- **État :** utilisateur non connecté ;
- **Type :** Empty State ;
- **Format cible :** SVG + Lottie ;
- **Boucle :** oui, 4 secondes ;
- **Fond :** transparent.

---

# 20. Trois concepts pour « Profil non connecté »

## Concept A — La carte profil sort du smartphone

**Scène :** Awa tient un smartphone dans sa main gauche. Une carte profil abstraite, verticale et blanche émerge légèrement derrière l’écran : grand avatar circulaire, deux lignes neutres et petit marqueur d’accès. Sa main droite est ouverte vers la carte, sans la toucher.

**Personnage utilisé :** Personnage A — Awa.

**Pose :** debout en trois-quarts, poids sur la jambe droite, tête légèrement orientée vers la carte, smartphone à hauteur de poitrine.

**Objet principal :** smartphone relié visuellement à une carte profil.

**Point focal vert :** anneau vert de l’avatar sur la carte profil.

**Éléments secondaires :** petit marqueur d’accès neutre ; deux lignes abstraites de profil ; une micro-étoile bleu pétrole facultative.

**Composition :** Awa occupe les 55 % gauches ; smartphone au centre ; carte profil dans les 35 % droits ; la zone supérieure droite reste aérée.

**Éléments animables :** carte profil ; anneau d’avatar ; smartphone.

**Boucle proposée :** 0–800 ms repos ; 800–1 150 ms la carte monte de 4 dp et passe de 92 à 100 % d’opacité ; 1 200–1 500 ms l’anneau d’avatar fait `1 → 1.04 → 1` ; 1 500–4 000 ms repos. Le smartphone peut effectuer une rotation unique de 1° pendant le mouvement de la carte.

**Pourquoi ce concept communique « Profil » :** l’association immédiate smartphone + avatar + carte personnelle ne peut pas être confondue avec une commande ou une recherche.

## Concept B — L’avatar prêt à rejoindre le compte

**Scène :** Moussa se tient à droite d’un smartphone légèrement agrandi. Il porte dans une main un médaillon-avatar abstrait correspondant à son visage ; le même emplacement circulaire, encore vide, apparaît sur l’écran du téléphone. Un petit cadenas neutre sous l’avatar indique que l’espace personnel demande un accès.

**Personnage utilisé :** Personnage F — Moussa.

**Pose :** debout de face avec légère rotation du buste vers le smartphone ; bras gauche relâché ; main droite présentant le médaillon-avatar près de l’écran.

**Objet principal :** grand smartphone avec emplacement de profil vide.

**Point focal vert :** contour vert de l’emplacement-avatar dans le téléphone.

**Éléments secondaires :** médaillon-avatar ; petit cadenas neutre ; deux lignes de profil abstraites.

**Composition :** smartphone sur les 48 % gauches ; Moussa sur les 45 % droits ; médaillon entre les deux pour créer la relation identité → compte.

**Éléments animables :** médaillon-avatar ; anneau vert du téléphone ; cadenas.

**Boucle proposée :** 0–900 ms repos ; 900–1 300 ms le médaillon avance de 3 dp vers l’écran sans s’y insérer ; 1 320–1 600 ms l’anneau vert s’éclaire par opacity `0.75 → 1` ; 1 600–4 000 ms repos. Le cadenas reste fermé et effectue seulement un déplacement vertical de 2 dp.

**Pourquoi ce concept communique « Profil » :** le même avatar physique et numérique matérialise clairement l’identité personnelle avant l’accès au compte.

## Concept C — La porte vers l’espace personnel

**Scène :** Mariam tient son smartphone près du corps. À sa droite se trouve une grande carte profil verticale conçue comme une porte arrondie : avatar en haut, lignes abstraites au centre et poignée circulaire discrète. La carte est entrouverte visuellement par un léger chevauchement, sans montrer un décor intérieur.

**Personnage utilisé :** Personnage C — Mariam.

**Pose :** debout en trois-quarts, smartphone dans la main gauche, main droite orientée vers la carte-porte, expression calme et invitante.

**Objet principal :** carte profil transformée en seuil d’accès personnel.

**Point focal vert :** cadre vert de la carte-porte et avatar circulaire.

**Éléments secondaires :** smartphone ; poignée neutre ; deux lignes de profil abstraites.

**Composition :** Mariam dans les 48 % gauches ; carte-porte dans les 42 % droits ; chevauchement central léger ; espace négatif concentré en haut à gauche et autour des pieds.

**Éléments animables :** cadre de la carte ; avatar ; smartphone.

**Boucle proposée :** 0–800 ms repos ; 800–1 200 ms le cadre se décale de 3 dp vers la droite comme une ouverture discrète ; 1 250–1 550 ms l’avatar effectue `1 → 1.04 → 1` ; 1 550–4 000 ms repos. Le smartphone pivote de 1° puis revient.

**Pourquoi ce concept communique « Profil » :** la carte personnelle agit comme un accès visuel à « mon espace », sans évoquer commerce, livraison ou recherche.

## Recommandation de direction

**Concept A** est recommandé comme illustration maîtresse. Il est le plus explicite à 220 px, le plus simple à décliner et le moins dépendant d’une métaphore. Il établit immédiatement les composants récurrents les plus utiles pour la collection : Personnage A, smartphone, carte profil, avatar, contour, ombre et micro-animation.

---

# 21. Critères de validation avant toute génération

L’illustration maîtresse ne pourra être générée qu’après validation explicite des éléments suivants :

1. vert principal conservé et orange exclu des illustrations ;
2. bleu pétrole comme accent secondaire et beige comme neutre chaud ;
3. système hybride de contours ;
4. proportions adultes à 6,5 têtes ;
5. personnages A à F ;
6. canvas 1000 × 800 et composition mobile ;
7. Motion System 220 ms / boucle 4 s ;
8. SVG + Lottie, sans Rive pour la première collection ;
9. concept A, B ou C pour `SD-ILL-001`.

Après cette validation, ces règles deviennent la base figée du SOUTRALI Illustration System. Toute modification ultérieure doit être explicite, documentée et versionnée.
