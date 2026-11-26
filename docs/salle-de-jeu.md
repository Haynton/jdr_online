# La salle de jeu : comportements attendus

Ce document décrit la salle de jeu telle qu'elle a été validée par Anthony le 26 novembre 2026, sur la branche `feature/p1-game-room-frame`. Il sert de cahier des charges pour la brancher sur le vrai plateau (branche de Julien), les dés du serveur et le temps réel : **la forme et les comportements décrits ici sont validés**, seuls les points marqués « simulé » ou « à brancher » restent à faire.

Les fichiers cités sont ceux de la première version. **La maquette, ce sont des captures de la vraie salle** (voir « Captures » à la fin), fidèles au pixel : elles s'importent dans Figma comme des images.

## Ce qui est en ligne, ce qui ne l'est pas encore

Les parties **simulées** (rien d'enregistré ni de partagé) ne s'affichent qu'**en développement et dans les tests** (`GameRoom.preview_features?`, décision du 26 novembre : un joueur en ligne ne rencontre jamais une fonction qui oublie ce qu'elle a fait) :

- le **tour par tour** (« Lancer le tour par tour », la question sur l'initiative, la préparation, les tours, la réorganisation) ;
- la **fiche rapide** (PV, états, emplacements cochés) : en ligne, un portrait de la barre des combattants ouvre **la fiche complète** du personnage, dans sa fenêtre ;
- les boutons **« Placer »** des créatures (leurs jetons sur la carte). La carte du plateau, elle, est enregistrée et partagée depuis `feature/p1-board-map` : elle est en ligne.

En ligne, tout le reste marche pour de vrai : le cadre, les panneaux, les fenêtres de la bibliothèque, « Donner » un objet, la fiche complète, les paramètres de la partie, les réglages de chacun ; le chat (messages en direct et fil de jeu, depuis `feature/p1-game-room-chat`) ; les caméras, les dés et les outils de carte sont annoncés « Bientôt ». Brancher une partie simulée (voir les tableaux « à brancher ») la fait sortir de `preview_features?`.

## Principes

- **Un plateau sur tout l'écran, des îlots qui flottent dessus.** La navigation de l'application disparaît dans la salle. Rien ne pousse le plateau : panneaux, fiches et fenêtres se posent par-dessus.
- **Une mesure pour tous les îlots** : 60 px de haut (îlots du haut, chat replié, barre des combattants, bouton « Visio »), 60 px de large pour la barre d'outils repliée, **12 px entre deux îlots**, 16 px des bords de l'écran. Fond `surface`, bordure `line`, ombre, coins arrondis de 12 px (`GameRoomHelper::ISLAND_CLASSES`).
- **Le modèle de jeu décide, l'interface garde sa forme.** Ce qui relève des règles (jet d'initiative, case de CA, ligne sous le nom, états, emplacements de sorts, jauge de PV) est déclaré par le modèle de la table (JSON), jamais écrit pour D&D dans le code. Un modèle qui n'a pas un élément ne l'affiche pas.
- **Les permissions se vérifient côté serveur.** Masquer un bouton à un joueur ne suffit jamais.
- **Ce que chacun règle pour lui** (taille des caméras, chat caché, barre dépliée au survol...) est gardé dans son navigateur (`localStorage`). Tout le reste (état de la partie) sera enregistré et partagé.

## Disposition de l'écran (à partir de 768 px)

| Emplacement | Élément | Fichier |
|---|---|---|
| Haut gauche | Îlot du nom : d20 (pas un lien), nom de la table (`h1`, 288 px au plus), rôle (« MJ », « Joueur ») | `game_rooms/_top_bar` |
| Haut, centré sur l'écran | Ligne des caméras (320 px gardés de chaque côté pour les îlots) | `game_rooms/_video` |
| Haut droite | Îlot : Paramètres, Quitter la partie (demandé d'abord), avatar (info-bulles sous les boutons) | `game_rooms/_top_bar` |
| Gauche, centrée en hauteur | Barre d'outils | `game_rooms/_toolbar` |
| À droite de la barre, 12 px sous les îlots du haut | Panneau ouvert (360 px de large, aussi haut que son contenu, défile au-delà) | `game_rooms/_panel` |
| Bas, à gauche du chat | Barre des combattants ; ses fiches rapides s'ouvrent au-dessus | `game_rooms/_combat_strip` |
| Bas droite | Chat (à partir de 1024 px) | `game_rooms/_chat` |
| Tout l'écran, sous les îlots | Le plateau (la carte posée) | `game_tables/show` |

Sur téléphone (simplifié, décision) : la barre d'outils en bas, un panneau prend l'écran au-dessus ; ni barre des combattants, ni chat, ni caméras, ni avatar. **À trancher** : où voir les joueurs sous 768 px.

## Barre d'outils (gauche)

- Outils en **groupes sous un petit nom**, séparés d'un trait :
  - MJ : **Carte** (Cartes, Outils de carte · bientôt), **Biblio.** (PNJ et ennemis, Objets), **Dés** (Dés, avec le jet d'initiative dans le même panneau · bientôt).
  - Joueur : **Fiche** (Ma fiche), **Dés** (bientôt).
- Repliée : icônes seules, centrées, 60 px de large. **Elle se déplie au survol** (après 150 ms) ou quand le clavier y entre avec un focus visible : seule sa largeur glisse (60 → 240 px, 200 ms), les noms apparaissent en fondu. Le nom d'un groupe passe de centré à aligné à gauche, en fondu.
- **Elle se replie dès qu'on choisit un outil**, jusqu'à ce que la souris la quitte (les noms couvraient le panneau ouvert). Fermer un panneau à la souris ne la redéplie pas.
- Le dépliage au survol se coupe dans Paramètres › Affichage (« Déplier la barre au survol », le clavier la déplie toujours).
- Un outil à venir porte un petit point et « (bientôt) ».
- Chaque outil ouvre son panneau, un seul à la fois ; le même outil, la croix ou Échap le ferment, et le focus revient à l'outil. Le panneau ouvert est retenu pour l'onglet (`sessionStorage`) : un rafraîchissement le rouvre.

## Panneaux (MJ)

### Cartes
- Une carte par carte de la table : aperçu (dessin, jetons, zones bloquantes), nom, taille de grille.
- **« Placer »** (carte dessinée) : affiche la carte sur le plateau ; le bouton devient **« Retirer »** (doré, enfoncé), qui la retire. Une seule carte sur le plateau à la fois. **Enregistré** (`game_tables.board_game_map_id`) et vu de toute la table en direct. Serveur : MJ de la table, une de ses cartes dessinées, sinon 404 (`GameTables::BoardMapsController`). Une carte envoyée en image seule, avant l'éditeur, n'a pas de bouton : elle n'a pas de grille.
- Crayon : ouvre la carte dans l'éditeur (page entière).
- **« Ajouter une carte »** : ouvre **dans la salle** la fenêtre « Importer depuis Mes cartes » ; la carte choisie est copiée dans la table, la salle se rafraîchit, le panneau reste ouvert.

### PNJ et ennemis
- « Ajouter depuis le bestiaire » et « Créer un PNJ ou un ennemi » ouvrent leurs fenêtres **dans la salle** (jamais l'étape de création de la table).
- Une ligne par PNJ ou ennemi de la table : nom, « Ennemi · FP 1/4 · CA 15 · PV 10 », la ligne ouvre sa fenêtre.
- **« Placer »** : prend la créature **comme outil, comme un jeton dans l'éditeur de cartes** (voir Plateau). Sans carte sur le plateau, le bouton est grisé, ne fait rien et le dit (« Placez d'abord une carte sur le plateau »).

### Objets
- Recherche sans accents, objets par catégorie ; un objet ouvre ses détails (valeurs, description).
- « Créer un objet » ouvre sa fenêtre dans la salle.
- **« Donner »** : fenêtre « Donner « Arc court » » → à qui (personnages terminés des joueurs), combien (1 à 99) → « Donner ». **Enregistré** : une copie de l'objet entre dans l'inventaire du personnage ; bulle « 3 × « Dague » donnés à Aria. ». Serveur : MJ de la table, objet du catalogue de la table, personnage d'un de ses joueurs, sinon 404 (`GameTables::ItemGiftsController`).

### Ma fiche (joueur)
- Avatar, nom, choix ; « Ouvrir ma fiche » ouvre la fiche complète dans une fenêtre.

## Plateau

- **La carte posée prend tout l'écran**, sous les îlots, aussi grande qu'elle tient sans être coupée ; le reste de l'écran prend la couleur du fond de la carte. Sans carte : un écran d'attente au centre, qui dit au MJ de placer une carte depuis le panneau Cartes, et aux joueurs que le MJ n'en a pas encore posé.
- **Chacun voit la carte posée**, joueurs compris, et la voit changer en direct quand le MJ en pose une autre ou la retire (`BoardMapChanger`, par `GameTableChannel`). **Deux versions, préparées par le serveur** (`BoardHelper`) : les joueurs ne reçoivent ni les jetons de l'éditeur (ils diraient où attendent des ennemis cachés), ni les zones bloquantes ; le MJ voit en plus, en rouge, **ce que les joueurs ne peuvent pas atteindre** : les zones peintes, le vide et les murs qui arrêtent un pion (`map_editor/passage.js`). Chaque page n'a que le plateau de son public (`#game-room-board-player`, `#game-room-board-game-master`) : les joueurs reçoivent le leur par le flux de la table, le MJ le sien par la réponse à son clic (le flux du MJ servira aux jetons cachés).
- **Le plateau en trois couches** (décision de Julien, 26 novembre) : le fond (la carte, dessinée une fois ; changée seulement quand le MJ pose une autre carte), la grille et ce qui bloque, les jetons (seule couche que touchent les coups de la partie).
- **Placer une créature** :
  1. « Placer » sur la créature (panneau PNJ et ennemis) → elle devient l'outil ; une bulle en haut : « Cliquez sur la carte pour placer « Gobelin ». Échap ou clic droit pour arrêter. » ; curseur en croix sur la carte.
  2. Chaque clic sur la carte pose son jeton **dans la case visée**, une par case (une case occupée refuse).
  3. L'outil reste en main pour poser une bande ; Échap ou le clic droit le lâchent ; retirer la carte le lâche aussi.
- Jeton : rond, rouge (ennemi) ou vert (PNJ), initiales, numéro quand plusieurs jetons du même personnage.
- **Simulé** : les jetons posés dans la salle ne sont ni enregistrés ni vus des joueurs. **À brancher (plateau de Julien)**, une branche chacun :
  1. `feature/p1-board-tokens` : les jetons en jeu, dans une table `board_tokens` (qui portera aussi l'état de chaque combattant). Les jetons de l'éditeur y sont recopiés la première fois que la carte va sur le plateau, puis gardés là où la partie les a laissés (« Remettre au départ » les recopie, demandé d'abord). Une créature posée est **cachée aux joueurs** jusqu'à ce que le MJ la montre. Plusieurs jetons sur une même case sont permis pour l'instant ;
  2. `feature/p1-board-player-tokens` : les jetons des personnages des joueurs, posés par le MJ dans la salle **ou** à l'avance dans l'éditeur de la carte ;
  3. `feature/p1-board-moves` : déplacer un jeton en le glissant, case par case. Le MJ déplace tout et passe partout ; un joueur déplace seulement son personnage et ne peut pas finir sur une case bloquée (les murs viendront ensuite) ;
  4. `feature/p1-board-map-tools` : le MJ modifie la carte en direct depuis « Outils de carte » (murs, portes, zones bloquantes).

## Barre des combattants (bas)

Toujours là, 60 px de haut, à gauche du chat (contre le bord droit de 768 à 1023 px). Un portrait rond de 40 px par combattant : avatar d'un joueur, initiales d'une créature (rouge ennemi, doré PNJ), son numéro dans un coin (« 2 »), **anneau de ses PV** autour (jamais pour un joueur qui regarde une créature). Les portraits défilent quand ils ne tiennent pas ; le tour en cours est ramené au milieu.

### Les trois temps

1. **Hors du tour par tour** : les **joueurs seuls**, sans ordre. MJ : bouton **« Lancer le tour par tour »** (et non « combat » : on peut faire du tour par tour sans combat).
2. **La question** (fenêtre « Lancer le tour par tour ») : « Demander un jet d'initiative à toute la table ? »
   - **« Jet d'initiative »** : l'ordre suivra les résultats.
   - **« Sans jet »** : les joueurs font autrement ; l'ordre reste celui de la barre.
   - Un encadré explique que, dans les deux cas, on pourra changer l'ordre en faisant glisser un portrait (ou Alt + ← / →), puis valider.
   - Croix, Échap, clic à côté : rien ne se lance.
3. **La préparation** : le MJ place sa carte, ses ennemis et ses zones bloquantes. Les PNJ et ennemis **entrent dans la barre, cachés aux joueurs** (un œil barré sur leur portrait). Avec le jet : « Préparation · 2 joueurs en attente » puis « Préparation · initiatives lancées » ; les portraits des joueurs restent estompés jusqu'à leur jet. Sans jet : « Préparation ». Boutons **« Prêt »** (doré, l'action qui attend le MJ) et « Annuler » (retour hors du tour par tour).
4. **Les tours** (après « Prêt ») : les créatures deviennent visibles des joueurs ; l'ordre d'initiative (ou celui de la barre sans jet) ; « Tour N » (largeur fixe : la barre ne bouge pas quand le chiffre change) ; **contour doré** sur celui dont c'est le tour ; **« Tour suivant »** (le contour avance, le tour compte à la fin de la liste) ; **« Fin du tour par tour »**, demandé d'abord (« Mettre fin au tour par tour ? L'ordre et les tours seront effacés, les PV et les états restent. »), qui ramène hors du tour par tour.

### Ordre

- Chaque créature a **son propre portrait** (chaque gobelin le sien). Les créatures du même type partagent un jet et se suivent.
- **Le MJ réordonne** (pendant les tours, et dès la préparation sans jet) : il **fait glisser un portrait** à la souris ou au doigt (au-delà de 6 px, le portrait suit le pointeur, à moitié transparent ; le relâcher n'ouvre pas sa fiche), ou **Alt + ← / →** sur un portrait. **« Valider le nouvel ordre ? »** est demandé ; « Annuler » remet l'ordre d'avant.

### Fiche rapide (au clic sur un portrait)

Au-dessus de la barre, une à la fois ; Échap ou un clic ailleurs la ferment. Le MJ ouvre toutes les fiches, un joueur seulement la sienne.

- En tête : le nom ; dessous, **classe et espèce** (« Druide · Elfe ») pour un joueur, « Ennemi » ou « PNJ » pour une créature ; à droite, **la CA dans une case dorée** (mise en avant) et l'initiative dans une case à côté.
- **Points de vie** : − et +, « 21/21 », une barre (l'anneau du portrait suit).
- **« Ajouter un état »** : ouvre une fenêtre « Ajouter un état à Elowen » avec **les états du modèle et leur règle courte** (deux colonnes) ; un clic ajoute l'état et ferme la fenêtre. Les états choisis se rangent **sous le bouton**, en pastilles dorées ; un clic sur une pastille la retire **sans fermer la fiche**.
- **Emplacements de sorts** (joueur qui en a) : une ligne par niveau, un rond par emplacement, **coché quand il est utilisé**. Nom et aide viennent du modèle (« Emplacements de pacte » pour un occultiste).
- **Attaques** : nom et bonus, dés et type de dégâts, portée.
- « Voir la fiche complète » : la fiche du joueur, ou la fenêtre du PNJ.

### Ce qui reste simulé, et comment le brancher

| Simulé aujourd'hui | Attendu |
|---|---|
| Initiative : d20 tiré pareil à chaque chargement + modificateur de DEX (`CombatStrip`) | Jet tiré **par le serveur** selon la règle déclarée par le modèle (dés, caractéristique) ; un modèle sans règle : pas de jet proposé |
| Jets des joueurs arrivant un par un dans la page du MJ | Chaque joueur reçoit en direct « Lancez l'initiative » avec un bouton ; le MJ voit qui a lancé ; « Prêt » fait lancer le serveur pour les retardataires |
| Préparation, ordre, tours, PV, états, emplacements cochés : dans la page du MJ seulement | Enregistrés (état de chaque **combattant**, c'est-à-dire de chaque jeton) et diffusés par `GameTableChannel` (flux de la table ; créatures en préparation : flux du MJ seulement) |
| Créatures : celles posées sur la première carte qui a des jetons | Celles posées sur la carte du plateau |
| Clés D&D en dur : `armor_class`, `class`, `species`, DEX pour l'initiative | Champs marqués par le modèle |

## Trois niveaux de données à ne pas confondre

1. **La bibliothèque** : le catalogue (bestiaire, objets) et les PNJ créés par le MJ ; la fiche complète, pour préparer.
2. **La fiche d'un PNJ ou d'un ennemi de la table** : sa copie dans `characters`.
3. **Le combattant en jeu** : un jeton du plateau, avec **ses** PV, **ses** états, **son** initiative. Seulement ce qui sert pendant un combat. L'état d'un combattant vit avec le jeton (décidé avec Julien : une ligne de `board_tokens` par jeton en jeu).

## Caméras (visio)

- **Une ligne en haut, centrée sur l'écran, sans carte autour** : une vignette 16:9 par personne de la table (MJ puis joueurs), chacune un petit îlot, avatar et nom (« Vous » pour soi, « MJ ») en attendant Jitsi. Le haut des vignettes est aligné sur celui des îlots.
- **Trois tailles** : 60 px de haut (celle des îlots), 90 ou 135 px. **Jamais de défilement** : quand elles ne tiennent pas, elles rétrécissent ensemble en gardant leur format ; **sous 60 px de haut, la ligne se replie toute seule** en un bouton « Visio » (60 px de haut), qui ouvre la visio au centre.
- Au survol ou au clavier, une petite pastille sous la ligne : « Visio · Bientôt », −, +, **visio au centre**, replier. Repliée : un bouton « Visio ».
- **Visio au centre** : les vignettes prennent la place entre la barre d'outils, les îlots du haut et la barre des combattants, **posées sur le plateau, sans carte**, en rangées centrées de 320 px ; « Revenir en haut » ou Échap.
- Paramètres › Visio et son : « Afficher les caméras » (les cache entièrement) et « Taille des caméras ».
- **À brancher** : le conteneur de la visio garde un `id` fixe et `data-turbo-permanent` (règle du projet) : Jitsi s'installera dans `#game-room-video-places`. Donner à la salle Jitsi un nom impossible à deviner.

## Chat

- Bas droite, à partir de 1024 px. Bas par défaut (256 px avec son champ, 160 px au moins), **hauteur réglable** par la poignée du haut (glissée, ou flèches du clavier, Maj pour un grand pas), **repliable** (60 px de haut replié).
- Paramètres › Affichage : « Afficher le chat » le cache entièrement.
- **Fait** (`feature/p1-game-room-chat`) : **le fil de la table**, une seule table `chat_messages` (modèle `ChatMessage`) pour ce que la table lit dans son ordre : les **messages** tapés par chacun et les **événements** écrits par le serveur (pour l'instant « Le MJ a donné 3 × « Dague » à Aria. »). En arrivant, les **50 dernières lignes** ; ensuite, chaque ligne nouvelle arrive **en direct** chez tous (`GameTableChannel`). Ses propres messages ont le pseudo en doré ; l'heure est celle de l'appareil du lecteur. Un message : 1000 caractères au plus, écrit seulement par quelqu'un d'accepté à la table. Le fil ne se lit et ne s'écrit que par `ChatMessage.feed_of`, `.post` et `.record_event`.
- **Un nouvel événement** : sa clé dans `ChatMessage::EVENT_KEYS`, son texte dans `GameRoomChatHelper::CHAT_EVENT_TEXTS` et `game_rooms.chat.events` (fr et en), et un `ChatMessage.record_event(table, :clé, valeurs)` là où l'action est faite. Un événement garde ses valeurs, pas son texte : chacun le lit dans sa langue en arrivant. **Limite connue** : une ligne reçue en direct est écrite dans la langue de celui qui a agi (rechargée, elle passe dans la sienne).
- **À brancher** : les jets de dés et les actions de chacun (tour suivant, PV, états) comme événements. L'IA (commande /action, réponses) écrira aussi dans ce fil ; la vie technique d'un appel (statut, demande, JSON brut, vérification) ira dans une table à part, `ai_requests`, reliée à ses lignes du fil. Le MJ pourra **annuler une action** depuis le fil (un « Tour suivant » de trop, un jet, des PV changés...) : chaque action devra être enregistrée avec ce qu'elle a changé.

## Paramètres de la partie (fenêtre)

Rubriques : Participants (et lien d'invitation pour le MJ), Règles de la partie (MJ, si le modèle en a), Visio et son, Affichage (thème, déplier la barre au survol, afficher le chat, langue).

## Réglages gardés dans le navigateur

| Clé `localStorage` | Rôle |
|---|---|
| `game_room_toolbar_hover` | `off` : la barre ne se déplie plus au survol |
| `game_room_chat_height`, `game_room_chat_folded`, `game_room_chat_hidden` | Hauteur, repli, chat caché |
| `game_room_video_size`, `game_room_video_folded`, `game_room_video_hidden`, `game_room_video_stage` | Taille, repli, caméras cachées, visio au centre |

`sessionStorage` : `game_room_panel:<adresse>` (le panneau ouvert, par onglet).

## Accessibilité (à garder en branchant)

- Chaque bouton à icône seule a son nom (`aria-label`) ; les portraits se nomment « Elowen, initiative 13 ».
- Fenêtres natives (`<dialog>`) : focus pris par la fenêtre, rendu au bouton à la fermeture, Échap et clic à côté ferment.
- Tout ce qui se fait à la souris se fait au clavier : barre dépliée au focus, réordonner par Alt + flèche, poignée du chat aux flèches.
- Pas d'animation si l'appareil en demande moins.

## Captures

Dans `docs/prototypes/salle-de-jeu/`, 1440 × 900, chacune en sombre (`-dark`) et en clair (`-light`), prises sur la table « Les Terres de Valdoria » du seed local (MJ : othna ; joueur : Brannoc) :

| Fichier | État |
|---|---|
| `01-mj-hors-tour-par-tour` | La salle du MJ au repos : îlots du haut, caméras, barre d'outils repliée, barre des combattants (joueurs seuls), chat |
| `02-mj-barre-depliee` | La barre d'outils dépliée au survol |
| `03-mj-panneau-cartes-carte-posee` | Panneau Cartes, une carte posée sur le plateau (« Retirer ») |
| `04-mj-placer-un-ennemi` | Panneau PNJ et ennemis, une créature en main (bulle de placement), un jeton posé |
| `05-mj-fenetre-tour-par-tour` | La question « Demander un jet d'initiative à toute la table ? » |
| `06-mj-preparation` | La préparation avec jet : un joueur en attente, créatures dans la barre, « Prêt » |
| `07-mj-tours-fiche-rapide` | Les tours : contour doré, fiche rapide d'Elowen (CA, PV, état, emplacement coché) |
| `08-mj-fenetre-des-etats` | La fenêtre « Ajouter un état » |
| `09-mj-donner-un-objet` | Panneau Objets et fenêtre « Donner » |
| `10-mj-visio-au-centre` | La visio au centre, pendant les tours |
| `11-mj-parametres-de-la-partie` | La fenêtre des paramètres de la partie |
| `12-joueur-salle` | La salle d'un joueur (Fiche, Dés ; sa place « Vous ») |
| `13-joueur-sa-fiche-rapide` | Sa propre fiche rapide |

Elles se refont par un script hors du dépôt (Selenium, Chrome sans fenêtre, sur le serveur local) ; à refaire quand la salle change.
