# CLAUDE.md

Contexte et règles pour Claude Code sur le projet JDR en ligne (projet de fin de formation Le Wagon).

## Le projet

Application web pour jouer à des jeux de rôle entre amis, en ligne ou en suivant une partie en cours autour d'une table : comptes, tables de jeu, fiches de personnage, lancer de dés, chat et fil de jeu en temps réel, plateau interactif, éditeur de carte, fonctions IA (résumé de séance, mémoire de campagne, fiche en langage naturel, commande /action), visio Jitsi.

Projet réalisé en deux semaines, en équipe de deux ou trois personnes. Les membres de l'équipe sont en formation : le code doit pouvoir être relu, compris et expliqué par la personne qui ouvre la Pull Request.

## Comment travailler avec moi

- Répondre toujours en français. Le code, les noms de branches et les messages de commit restent en anglais
- Avant de modifier des fichiers, annoncer brièvement ce qui va être fait et pourquoi
- Après chaque modification, expliquer ce qui a changé, fichier par fichier, avec des mots simples
- Avancer par petites étapes vérifiables plutôt qu'en un seul gros changement
- En cas de doute sur un choix (structure de données, nom, gem à ajouter), poser la question au lieu de deviner
- Quand une erreur apparaît, expliquer sa cause avant de la corriger
- Ne jamais présenter une commande comme réussie sans avoir lu sa sortie

## Stack

- Ruby 3.3.5, Rails 8.1
- PostgreSQL 15 en local, Heroku Postgres en production
- Pipeline d'assets : Sprockets (`sprockets-rails`), JavaScript par importmap
- Authentification : Devise (avec `:recoverable` pour le mot de passe oublié)
- Formulaires : Simple Form (sans configuration Bootstrap)
- CSS : Tailwind v4 via `tailwindcss-rails`. **Pas de Bootstrap, pas de Font Awesome**
- JavaScript : Stimulus et Turbo. Pas de jQuery
- Temps réel : Action Cable et Turbo Streams. En production : Redis (Heroku Key-Value Store), pas Solid Cable
- Images : Active Storage avec Cloudinary
- Variables d'environnement : `dotenv-rails` en développement, variables Heroku en production
- Hébergement : Heroku. Kamal et le Dockerfile générés par Rails ne sont pas utilisés
- Langues : I18n de Rails, français et anglais. Langue choisie par le compte, sinon par le navigateur, sinon l'anglais. Gems `rails-i18n` et `devise-i18n` (à installer, voir Prochaines tâches)
- Thème : clair, sombre ou système, avec la variante `dark` de Tailwind pilotée par une classe `.dark` sur `<html>` et des couleurs nommées (voir Couleurs et thème)

## Commandes

- Lancer l'application : `bin/dev` (serveur et reconstruction du CSS Tailwind). Une fois Tailwind installé, ne pas utiliser `rails s` seul : les classes Tailwind ne seraient pas reconstruites
- Base de données : `rails db:migrate`, `rails db:seed`
- Style Ruby : `bin/rubocop`
- Tests : `bin/rails test` (sans les tests système), `bin/rails test:system` (navigateur Chrome invisible), `bin/rails test:all` (tout)
- Console : `rails c`

## Règles de code

### Lisibilité avant tout

- Le code doit se lire comme une phrase. S'il faut un commentaire pour comprendre ce que fait une ligne, renommer ou découper plutôt que commenter
- Les commentaires expliquent le **pourquoi**, jamais le **quoi**

### Nommage

- Des noms complets et explicites, qui disent ce que contient la variable ou ce que fait la méthode
- **Interdits** : les noms d'une lettre (`i`, `x`, `e`, `t`, `u`), les abréviations obscures (`tmp`, `obj`, `val`, `res`, `arr`, `data`), les noms vagues (`stuff`, `thing`, `info`, `manager`)
- Y compris dans les blocs et les boucles : `players.each { |player| ... }`, pas `players.each { |p| ... }`
- Y compris pour les erreurs : `rescue ActiveRecord::RecordNotFound => error`, pas `=> e`
- Les booléens se lisent comme une question : `game_master?`, `visible_to_players?`, `isBlocked`, `hasMoved`
- Les méthodes commencent par un verbe quand elles agissent : `roll_dice`, `move_token`, `broadcast_event`
- Ruby : `snake_case` pour les variables et méthodes, `CamelCase` pour les classes
- JavaScript : `camelCase` pour les variables et fonctions, `PascalCase` pour les classes

Exemple :

```ruby
# À éviter
def calc(t, x)
  t.each { |i| x += i.v }
  x
end

# À préférer
def total_damage(dice_results, bonus)
  dice_results.sum(&:value) + bonus
end
```

### Limiter l'imbrication

- Deux niveaux d'indentation au maximum dans une méthode. Au-delà, découper
- Utiliser des clauses de garde (retour anticipé) plutôt que des `if` imbriqués
- Pas de `if` dans un `if` dans une boucle : extraire une méthode avec un nom clair
- Une méthode fait une seule chose. Viser une dizaine de lignes au maximum

Exemple :

```ruby
# À éviter
def move_token
  if current_user
    if @table.session_in_progress?
      if @token.owner == current_user
        @token.update(position_params)
      end
    end
  end
end

# À préférer
def move_token
  return head :forbidden unless @table.session_in_progress?
  return head :forbidden unless @token.owner == current_user

  @token.update(position_params)
end
```

### Ruby et Rails

- Indentation de deux espaces
- Contrôleurs minces : la logique métier va dans les modèles ou dans des services (`app/services/`)
- Un service = une classe = une action, avec une méthode `call` (ex. `DiceRoller`, `SessionSummarizer`)
- Pas de logique dans les vues ERB : la préparer dans le contrôleur, un helper ou le modèle
- Utiliser les conventions Rails (noms de tables, associations, routes `resources`) plutôt que des solutions maison
- Pas de requête en base dans une boucle (problème N+1) : utiliser `includes`
- Valider les données dans le modèle, pas seulement dans le formulaire
- Respecter `.rubocop.yml`

### JavaScript

- Toujours `const` par défaut, `let` seulement si la valeur change. **Jamais `var`**
- Syntaxe moderne : fonctions fléchées, déstructuration, gabarits de chaînes, `async` et `await`
- Le JavaScript vit dans des contrôleurs Stimulus (`app/javascript/controllers/`), pas dans des balises `<script>` dans les vues
- Un contrôleur Stimulus par comportement, avec des `targets` et des `values` nommés clairement
- Pas de `console.log` laissé dans le code commité

### Tailwind et vues

- Écrire les classes Tailwind en toutes lettres. **Jamais de classe construite par interpolation** (`col-start-#{x}`, `` `bg-${color}` ``) : Tailwind ne la générera pas. Pour une position calculée (jetons du plateau), utiliser un style en ligne
- Quand un groupe de classes se répète, en faire un partiel ou un helper
- Le conteneur Jitsi garde `data-turbo-permanent` et un `id` fixe : il ne doit jamais être retiré ni rechargé de la page

### Textes et traductions

- **Aucun texte affiché à l'utilisateur écrit en dur** dans une vue, un contrôleur, un modèle ou un e-mail. Toujours passer par `t(...)` et les fichiers `config/locales/fr.yml` et `config/locales/en.yml`
- Dans les vues, utiliser les clés courtes (« lazy lookup ») : `t(".title")` dans `app/views/tables/show.html.erb` cherche `fr.tables.show.title`
- Toute nouvelle clé est ajoutée **dans les deux langues** en même temps
- Les messages de validation et les noms d'attributs passent par `activerecord.attributes` et `activerecord.errors` dans les fichiers de traduction
- Dates et nombres affichés avec `l(...)` (ex. `l(session.started_at, format: :short)`), jamais avec `strftime` en dur
- Le code, les clés de traduction, les noms de variables et les commits restent en anglais
- Seule exception : la galerie de composants `/dev/components` (développement et test seulement, jamais servie en production). Outil de l'équipe, jamais vu par les joueurs : ses textes restent en anglais, écrits en dur, avec un commentaire en tête de la vue

### Couleurs et thème

- L'application propose trois thèmes : clair, sombre et système (suit le réglage de l'appareil)
- Utiliser les **couleurs nommées** du projet (`bg-page`, `bg-surface`, `text-ink`, `border-line`...), définies dans `app/assets/tailwind/application.css`. Elles changent toutes seules en mode sombre : pas besoin d'écrire `dark:` à chaque élément
- Pas de couleur brute (`bg-gray-800`, `#1f2937`) dans les vues, sauf cas isolé justifié. S'il manque une couleur, l'ajouter aux couleurs nommées
- `dark:` reste possible pour un ajustement ponctuel (une ombre, une image)
- Référence visuelle du mode sombre : les wireframes du projet (police Inter, vert principal `#2E7D6B`)
- Couleurs nommées (valeurs dans `app/assets/tailwind/application.css`, bloc `@theme` pour le clair, bloc `.dark` pour le sombre) :

| Couleur nommée | Rôle | Sombre (wireframes) | Clair, parchemin léger |
|---|---|---|---|
| `page` | Fond de page | `#0f1520` | `#faf6ee` |
| `surface` | Cartes, panneaux, barre de navigation | `#1f2937` | `#fffdf9` |
| `field` | Fond des champs | `#111827` | `#ffffff` |
| `line` | Bordures | `#374151` | `#ebe3d3` |
| `field-line` | Bordure des champs, case à cocher, piste d'interrupteur éteint | `#6b7280` | `#8f8270` |
| `focus-ring` | Focus clavier des champs et des boutons | `#7fd1bd` | `#1d574a` |
| `ink` | Texte principal | `#f9fafb` | `#27211a` |
| `muted` | Texte secondaire | `#9ca3af` | `#796e60` |
| `primary` | Bouton principal (texte blanc) | `#2E7D6B` | `#2E7D6B` |
| `primary-hover` | Bouton principal au survol (texte blanc) | `#276a5b` | `#276a5b` |
| `link` | Liens | `#7fd1bd` | `#2E7D6B` |
| `primary-soft` | Fond du lien de navigation actif, carte « brouillon », badge « MJ » | `#183a33` | `#e4efe9` |
| `primary-soft-ink` | Texte posé sur `primary-soft` | `#7fd1bd` | `#1d574a` |
| `surface-raised` | Élément actif d'un menu, survol des boutons secondaires et discrets | `#374151` | `#ebe3d3` |
| `logo-bg` | Carré du logo d20 (texte blanc) | `#1f1b18` | `#1f1b18` |
| `danger` | Bouton de suppression (texte blanc) | `#b91c1c` | `#b91c1c` |
| `danger-hover` | Bouton de suppression au survol (texte blanc) | `#9d1818` | `#9d1818` |
| `success-bg` / `success-line` / `success-ink` | Message de succès (`notice`) | `#12302a` / `#2E7D6B` / `#a7e3d4` | `#e9f1e5` / `#c3d8b8` / `#2f5d3a` |
| `error-bg` / `error-line` / `error-ink` | Message d'erreur (`alert`) | `#3b1d1d` / `#7f2d2d` / `#f87171` | `#fbe9e4` / `#eec3b8` / `#9b2c1f` |

- Palette décidée : vert `#2E7D6B` comme couleur principale dans les deux thèmes, parchemin léger pour le thème clair (fond légèrement chaud, texte brun très foncé plutôt que noir)
- Le vert des boutons et le vert des messages de succès sont deux couleurs nommées distinctes : ne pas utiliser `primary` pour un message de succès
- Contraste minimum visé : 4,5 pour le texte (critère WCAG AA). Le texte blanc sur `primary` est à 4,93 : ne pas éclaircir ce vert. Au survol, on assombrit (`primary-hover`, 6,37), on n'éclaircit pas. `muted` clair a été assombri de `#7b7062` à `#796e60` pour passer de 4,49 à 4,62 sur `page`. Toute nouvelle couleur de texte est vérifiée contre les fonds où elle s'affiche
- Contraste de forme : la bordure ou le fond d'un composant (bouton, badge, champ) doit se distinguer de son support avec un contraste d'au moins 3 (critère WCAG 1.4.11). Vérifier les deux, le texte **et** la forme
- Sur `primary-soft`, seulement `ink` ou `primary-soft-ink` : `muted` (4,23) et `link` (4,18) y passent sous 4,5 en clair
- Sur `surface-raised`, seulement `ink` : `muted` y passe sous 4,5 (3,91 en clair, 4,06 en sombre)
- Le vert plein (`primary`) et le rouge plein (`danger`) sont réservés aux boutons : un badge ou une étiquette n'utilise jamais un fond plein, pour ne pas ressembler à un bouton
- Police Inter, hébergée dans `public/fonts/` (aucune requête vers un service de polices)

### Composants

Construits une fois, réutilisés partout. On les voit tous, dans les deux thèmes, sur la galerie `/dev/components` (développement et test seulement).

- Boutons : `button_classes(variant, size: :normal, full_width: false)` (`app/helpers/buttons_helper.rb`), variantes `:primary`, `:secondary`, `:quiet`, `:danger` (rouge plein, texte blanc), tailles `:normal` (44 px) et `:compact` (36 px), `full_width: true` pour toute la largeur (`w-full`). Une variante ou une taille inconnue lève une erreur. Ne jamais répéter les séries de classes d'un bouton dans une vue. La bordure `line` du bouton secondaire reste discrète (décision) : plus marquée, il ressemblerait à un champ
- Badges : `badge_classes(:game_master | :player)` (`app/helpers/badges_helper.rb`) : pilule, 11 px, majuscules, couleurs tonales et contour intérieur de la couleur du texte à 50 % (sans lui, le badge disparaît sur une carte en sombre)
- Icônes : partiels `app/views/shared/icons/_nom.html.erb` (tracés Lucide 1.69.0, licence ISC et MIT Feather dans `LUCIDE-LICENSE.txt`), `aria-hidden="true"`, `stroke="currentColor"`, taille par `css_class` (`size-4` par défaut). Pour une nouvelle icône : reprendre le SVG du dépôt `lucide-icons/lucide` à une version déjà publiée depuis quelques jours, et vérifier qu'il ne contient que des tracés
- Logo : partiel `shared/_logo` (d20 des wireframes sur `logo-bg`, traits blancs en `currentColor`, nom traduit « JDR en ligne » / « JDR Online »). `compact_on_phone: true` : le d20 seul sur téléphone, le nom reste pour les lecteurs d'écran
- Avatar : partiel `shared/_avatar` (cercle de 32 px, initiales `User#initials`, tirées du pseudo), caché aux lecteurs d'écran
- Menu déroulant : contrôleur générique `dropdown_controller.js` (cibles `button` et `menu`), modèle « bouton qui montre une liste de liens » (`aria-expanded`, `aria-controls`, pas de `role="menu"`). Se ferme sur Échap (le focus revient au bouton), sur un clic ailleurs, quand le focus clavier part ailleurs, et avant la mise en cache de Turbo. Un focus « vers nulle part » est ignoré : Safari ne donne pas le focus à un lien cliqué
- Lignes d'un menu : `nav_link_to(label, path, icon:, current:)` et `nav_item_classes` pour un bouton (`app/helpers/navigation_helper.rb`), icône de 20 px, texte 15 px `ink`, survol `surface-raised`. La page en cours n'a **pas** de couleur à elle (décision : le vert ressemblait à une option choisie), seulement `aria-current="page"`
- Sélecteur de thème : partiel `shared/_theme_selector` (et `shared/_theme_choice`), le même partout : trois choix Clair / Sombre / Système avec icône (soleil, lune, écran Lucide `monitor`), contrôle segmenté, `aria-pressed` sur le choix actif, contrôleur `theme_controller.js`. `compact: true` (barre des visiteurs, pages de connexion) : icônes seules, texte gardé pour les lecteurs d'écran et montré au survol (`title`). `labelled_by:` (ligne de réglage) : nommé par le libellé visible, sinon par « Thème ». Pas de contrôle de thème dans la barre des utilisateurs connectés : le thème se règle dans Paramètres › Affichage
- Focus clavier : `focus-ring` partout, par une règle de base dans `application.css` (`:focus-visible`, contour de 2 px décalé de 2 px) qui remplace le contour bleu du navigateur sur tout élément sans classes de focus à lui (logo, liens texte...). Champs et boutons : contour de 2 px en `focus-ring`, décalé de 2 px (`outline-2 outline-offset-2`), la bordure du champ garde sa couleur (décision : pas de bordure verte au focus). L'ancien halo de 3 px à 30 % était trop pâle seul (1,66 en clair, 2,0 en sombre), le contour atteint 8,22. Sur un champ en erreur, contour `error-ink`. La case à cocher garde pour l'instant bordure `focus-ring` et halo
- Champs : définis une seule fois dans `config/initializers/simple_form.rb` (module `SimpleFormFieldClasses`, wrappers `:default`, `:boolean` et `:setting` pour un champ placé dans une ligne de réglage, sans libellé ni marge). Ne jamais styler un champ dans une vue. États : repos `field-line`, survol `muted`, focus contour `focus-ring`, erreur (bordure et `ring-1` `error-ink`, fond `error-bg`, message `error-ink` sous le champ), désactivé (opacité 50 %). L'erreur suit `aria-invalid`, que Simple Form pose sur les champs invalides : les variantes `aria-invalid:` passent après `focus:` et `hover:`, le rouge l'emporte toujours. Hauteur fixe de 44 px **avec** `py-2.5` : sans marge verticale, Safari étirait son indicateur de majuscules dans le champ mot de passe
- Aide sous un champ (`hint`) : cachée dès que le champ est invalide, le message d'erreur la remplace (`group-has-aria-invalid:hidden`, chaque bloc de champ porte `group` via `FIELD_BLOCK`)
- Champ mot de passe : `app/inputs/password_input.rb` (Simple Form cherche ce nom exact) ajoute à **chaque** champ mot de passe un bouton œil (`shared/_password_visibility_button`, contrôleur `password_visibility_controller.js`) : 36 px dans le champ à droite, libellé fixe « Afficher le mot de passe » et `aria-pressed`, un bouton par champ. Rendu `hidden`, affiché par le contrôleur (sans JavaScript, pas de bouton inutile). Le mot de passe est remasqué à chaque envoi de formulaire, pour que le navigateur ne le range pas dans l'historique des champs texte
- Message d'erreur sous un champ : première lettre en majuscule (`first-letter:uppercase`), car Simple Form l'écrit sans le nom du champ (« doit être rempli(e) »)
- Champ obligatoire : astérisque discret (`text-muted`) **après** le libellé (`config.label_text`), caché aux lecteurs d'écran (`aria-hidden`), qui annoncent déjà l'attribut `required` du champ. Texte dans la clé `simple_form.required.html`
- Case à cocher : dessinée par nous (`appearance-none`, 18 px, coins de 3 px, coche blanche `@utility bg-checkmark` sur `primary`), à côté de son libellé (`boolean_style = :inline`)
- Liste déroulante : `app/inputs/collection_select_input.rb` (Simple Form cherche ce nom exact pour remplacer son champ `select`). Vrai `<select>` : champ fermé stylé et chevron, **liste ouverte du système** (décision, voir À savoir)
- Messages : partiel `shared/_message`, rendu en gabarit (`render layout: "shared/message", locals: { variant: :error } do … end`), variantes `:error` (`role="alert"`, icône `x`) et `:success` (`role="status"`, icône `check`), bordure de 1 px dans la couleur du texte à 70 %. Utilisé par les messages flash, `devise/shared/_error_messages` et `form_error_notification(f)`, qui remplace `f.error_notification` dans les formulaires. Décision : à l'écran, le champ rouge et son message suffisent, l'en-tête de `form_error_notification` est donc en `sr-only` (son `role="alert"` prévient les lecteurs d'écran). Même principe pour « Connecté(e). », qui ne fait que répéter ce que la page montre : `Users::SessionsController` le range dans `flash[:screen_reader_notice]`, que `shared/_flashes` affiche en `sr-only`. Dans les Paramètres, les messages s'affichent dans la carte de la rubrique, sous son titre (`settings/_section`)
- Carte des pages visiteurs : helper `auth_card(title:, subtitle: nil) do … end` (`app/helpers/auth_cards_helper.rb`), qui rend `shared/_auth_card` (titre `h1`, sous-titre facultatif). Passer par le helper, pas par `render layout:` (voir À savoir, clés courtes)
- En-tête de page : helper `page_header(title:, subtitle: nil) do … end` (`app/helpers/page_headers_helper.rb`), qui rend `shared/_page_header` : titre `h1` de 32 px (800), sous-titre `muted`, boutons du bloc à droite (dessous sur téléphone), 32 px avant le contenu. Même principe que `auth_card` pour les clés courtes
- Paramètres : layout imbriqué `layouts/settings` (il remplit `layouts/application` par `content_for :full_width_page`) et contrôleur parent `Settings::BaseController`. Centré dans 1120 px : menu des rubriques à gauche sur le fond de la page (240 px, à partir de 768 px), rubrique dans une carte à droite (trait sous son titre, de bord à bord). Rubrique en cours surlignée sur grand écran seulement (`surface-raised`, `ink`, `aria-current`). **Sur téléphone, modèle « liste puis rubrique »** : `/settings` montre seulement la liste des rubriques (une ligne par rubrique, chevron `›`), une page de rubrique seulement sa carte, avec « ‹ Paramètres » pour revenir (`sections_list_page?`, helpers `settings_menu_visibility_classes` et `settings_section_visibility_classes`). Sur grand écran, `/settings` montre la rubrique Affichage. Les messages (« Langue enregistrée. ») s'affichent dans la carte, sous le titre
- Rubrique : helpers `settings_section(title:)`, `settings_group(title:)` et `setting_row(label:, label_id:, description:)` (`app/helpers/settings_helper.rb`), tous avec un bloc lu avant le rendu du partiel (`settings/_section`, `_group`, `_row`). Chaque ligne de réglage a un trait `line` sous elle, la dernière d'un groupe comprise, sauf le tout dernier élément de la rubrique (le bord de la carte suffit). Un formulaire dans un groupe se place comme une ligne (`border-b border-line py-4`). Le contrôle d'une ligne se nomme par `aria-labelledby="<label_id>"`. Une nouvelle rubrique : un contrôleur qui hérite de `Settings::BaseController`, sa ligne dans `settings/_sections_menu` et ses contrôleurs dans `SETTINGS_SECTION_CONTROLLERS` (`current_settings_section?`, pour que la rubrique reste en cours quand son formulaire revient avec une erreur)
- Envoi automatique d'un formulaire : contrôleur générique `auto_submit_controller.js` (`change->auto-submit#submit` sur le formulaire). Toujours prévenir dans la description de la ligne (« Enregistrée dès que vous la changez. », critère WCAG 3.2.2)
- Séparateur : partiel `shared/_divider` (`text:`), un trait de chaque côté d'un texte court (« Nouveau ici ? »)
- Liens dans un texte ou sous un formulaire : `font-medium text-link hover:underline`
- Interrupteur : partiel `shared/_switch` (`<button role="switch">`, `aria-checked`, `aria-labelledby` vers le texte visible, 44 × 24 px, rond blanc de 20 px, transition coupée par `motion-reduce:`) et contrôleur générique `switch_controller.js`, qui bascule `aria-checked` et émet `switch:change`. Ce qui est commandé (thème, réglage) écoute cet événement

### Sécurité et permissions

- Toute permission est vérifiée **côté serveur** (rôle MJ ou joueur, séance en cours, visibilité réservée au MJ), jamais seulement en masquant un bouton dans la vue
- Le lancer de dés est calculé par le serveur, jamais par le navigateur
- Les réponses de l'IA (JSON) sont validées par le serveur avant toute action
- Les clés d'API ne sont jamais envoyées au navigateur

## Base de données

- Ne jamais modifier une migration déjà présente sur `main` : créer une nouvelle migration
- Toujours commiter `db/schema.rb` avec la migration qui le modifie
- Conflit sur `db/schema.rb` : prendre la version de `main`, puis relancer `rails db:migrate`
- Ne jamais lancer `rails db:drop`, `db:reset` ou `db:schema:load` sans le demander d'abord

## Git

- Modèle GitHub Flow : `main` est protégée et toujours déployable
- Une branche par tâche, nommée `type/palier-description-courte` (ex. `feature/p2-dice-roll`, `chore/p1-heroku-setup`)
- Types : `feature`, `fix`, `refactor`, `chore`, `style`, `docs`, `hotfix`
- Commits au format Conventional Commits : `type(portée): description` à l'impératif, en anglais, moins de 70 caractères (ex. `feat(board): snap token to nearest cell on release`)
- Types de commit : `feat`, `fix`, `refactor`, `chore`, `style`, `docs`, `test`
- Petits commits cohérents. Pas de `wip`, `update` ou `fix bug`
- `git add` fichier par fichier, jamais `git add .` sans avoir vérifié `git status`
- **Interdits** : commit ou push direct sur `main`, `git push --force`, `git reset --hard`, réécriture d'un historique déjà poussé
- Toujours demander avant de commiter ou de pousser

## Fichiers sensibles

- **Ne jamais lire, afficher, modifier ni commiter** `config/master.key` et `.env`
- Toute nouvelle variable d'environnement est ajoutée, sans valeur, dans `.env.example`
- Ne jamais écrire de clé, de mot de passe ou de jeton dans le code
- Un secret publié sur GitHub (dépôt public) est considéré comme brûlé : on ne réécrit pas l'historique pour l'effacer, on ne l'utilise plus. Il faut en générer un nouveau (`bin/rails secret`) et le ranger dans les credentials chiffrés (`bin/rails credentials:edit`) ou dans une variable d'environnement. Exemple : les valeurs `config.secret_key` et `config.pepper` retirées de `config/initializers/devise.rb` restent visibles dans l'historique, sans risque car elles n'ont jamais servi
- Ne pas commiter `app/assets/builds/*` (CSS reconstruit automatiquement)

## Commandes à faire valider avant de les lancer

- Suppression de fichiers ou de dossiers (`rm`, `rm -rf`)
- Ajout ou retrait d'une gem
- Toute commande Heroku (`heroku ...`, `git push heroku`)
- Toute commande qui touche à la base autrement que `db:migrate`

## État du projet

Fait, sur `main`, avant le premier envoi sur GitHub :

- Application générée avec le template Devise de Le Wagon (Rails 8.1)
- Bootstrap, Font Awesome et les feuilles de style Le Wagon retirés. Les vues Devise copiées dans `app/views/devise` par le template ont été supprimées (voir plus bas les vues regénérées avec `devise-i18n`)
- Tailwind v4 installé (`tailwindcss-rails` 4.7, `tailwindcss-ruby` 4.3)
- Barre de navigation et messages flash réécrits en Tailwind
- Dépôt public `github.com/Haynton/jdr_online`. `main` protégée : Pull Request obligatoire, sans approbation requise pour l'instant, règles appliquées aussi à l'administrateur (`enforce_admins`), push forcé et suppression interdits, branches supprimées automatiquement après fusion. Testé : un push direct sur `main` est refusé
- Plus aucun commit direct sur `main` : tout passe par une branche et une Pull Request

Fait dans `chore/p1-i18n-setup` :

- `rails-i18n` et `devise-i18n` installés. `default_locale = :en`, `available_locales = [:fr, :en]`. Traduction manquante = erreur en développement et en test (`raise_on_missing_translations`)
- Colonne `users.locale` (vide = pas de choix), validée contre `I18n.available_locales`
- Choix de la langue de chaque requête par le concern `Locale` : compte, puis navigateur, puis anglais. Lecture de l'en-tête `Accept-Language` par les services `AcceptLanguageParser` (variantes régionales, ordre des `q`) et `BrowserLocaleDetector` (première langue disponible)
- Langue du navigateur enregistrée à l'inscription (`Users::RegistrationsController`)
- Message « Vous devez vous connecter » traduit par une failure app Devise (`Users::FailureApp`)
- Barre de navigation, titre et page d'accueil traduits. Un test vérifie que `fr.yml` et `en.yml` ont les mêmes clés

Fait dans `chore/p1-dependabot-config` :

- Dependabot (`.github/dependabot.yml`, créé par Rails) ne propose plus de version majeure pour les gems (`ignore` avec `dependency-name: "*"` et `version-update:semver-major`, section `bundler` seulement). Les mises à jour mineures et correctives continuent. Une version majeure se fait volontairement, dans une branche, après l'avoir testée
- La PR Dependabot #1 (`image_processing` 2.2.0) a été fermée sans fusion : on reste en 1.x, la version 2 n'est pas testée avec Active Storage

Fait dans `feature/p1-account-locale` :

- Vues d'inscription et de modification du compte générées avec `rails g devise:i18n:views -v registrations`, dans `app/views/devise/` (sans `scoped_views`), sans classe Bootstrap. Les pages de connexion et de mot de passe oublié ont été générées à leur tour dans `style/p1-auth-pages`
- Sélecteur de langue dans Mon compte : « Langue du navigateur » (enregistre `nil`), « Français », « English ». Les langues sont nommées dans leur propre langue (`locale_names`), la liste vient du helper `locale_options`. Le mot de passe actuel reste obligatoire pour changer de langue, comme pour toute modification du compte
- Titre « Mon compte » / « My account » (surcharge de `devise.registrations.edit.title`) et attribut `locale` traduit (`activerecord.attributes.user.locale`)
- Après un changement de langue, le message de confirmation est dans la nouvelle langue. Après la connexion, le message est dans la langue du compte. Après la déconnexion, il suit le navigateur, comme la page qui l'affiche
- Concern `DeviseLocale` (`prepend_around_action :switch_locale`) inclus dans `Users::SessionsController`, `Users::RegistrationsController` et `Users::PasswordsController` (ajouté dans `fix/p1-password-page-locale`) : le choix de la langue passe avant les vérifications de Devise, et « Vous êtes déjà connecté(e). » est traduit

Fait dans `chore/p1-theme` :

- Couleurs nommées et variante `dark` pilotée par la classe `.dark` sur `<html>` (`@custom-variant dark`), dans `app/assets/tailwind/application.css`. Plus aucune couleur brute dans les vues
- Police Inter 4.1 (`InterVariable-4.1.woff2` et sa licence OFL `Inter-LICENSE.txt`) dans `public/fonts/`, déclarée par un `@font-face`
- `app/javascript/theme_preload.js`, chargé de façon bloquante dans le `<head>` avant les feuilles de style : pose la classe `.dark` avant l'affichage, sans flash clair
- Sélecteur Clair / Sombre / Système dans la barre de navigation (partiels `shared/_theme_selector` et `shared/_theme_choice`, `aria-pressed` sur le choix actif), contrôleur Stimulus `theme_controller.js`. Le choix est enregistré dans `localStorage` (clé `theme`, « Système » = pas de valeur) ; en mode Système, la page suit en direct le réglage de l'appareil
- Tests système mis en place (`test/application_system_test_case.rb`, Chrome invisible) : choix du thème sombre gardé après rechargement, nouveau visiteur en mode Système

Fait dans `style/p1-ui-components` (première moitié des composants de la fiche Maquettes) :

- Couleurs `primary-soft`, `primary-soft-ink`, `surface-raised`, `logo-bg` et `danger-hover`
- Icônes Lucide, logo d20 (dans la barre de navigation), helpers de boutons et de badges (voir Composants)
- Galerie de composants `/dev/components`, routée seulement si `Rails.env.local?`, avec un test qui vérifie son absence en production
- Écarts volontaires avec la fiche Maquettes : badge « MJ » en vert tonal et en pilule (et non vert plein), bouton danger rouge plein (et non fond `surface` avec bordure `error-line`, trop pâle en clair : 1,57)

Fait dans `style/p1-form-components` (seconde moitié des composants de la fiche Maquettes) :

- Couleurs `field-line` et `focus-ring`
- Champs, case à cocher, liste déroulante, messages et interrupteur (voir Composants). Les formulaires d'inscription et de Mon compte en profitent déjà, avec leurs boutons (`button_classes`) et le bouton danger « Supprimer mon compte »
- En-tête d'erreur des formulaires traduit en français (la clé `simple_form.error_notification.default_message` manquait : il s'affichait en anglais)
- Écarts volontaires avec la fiche Maquettes : bordure des champs et piste d'interrupteur éteint en `field-line` (et non `line` : 1,18 à 1,77), case à cocher dessinée (et non `accent-color`), messages avec une bordure fine dans la couleur du texte (et non `*-line`, trop pâle). Une barre épaisse à gauche des messages a été essayée et refusée

Fait dans `style/p1-auth-pages` :

- Layout `auth` (`layouts/auth.html.erb`) : logo (lien vers l'accueil), sélecteur de thème, carte centrée de 420 px, sans barre de navigation. `<head>` partagé avec `application` dans `layouts/_head`. Choix par `ApplicationController#layout_for_page` : pages Devise des visiteurs en `auth`, Mon compte (`registrations` `edit`, `update`, `destroy`, `cancel`) en `application`
- Sélecteur de thème sorti de la barre de navigation (`shared/_theme_selector`) pour servir aux deux layouts. Messages flash sans marge horizontale : chaque layout les place
- Vues `sessions` et `passwords` générées par `devise-i18n` (avec `--skip`, pour garder nos vues `shared`), puis réécrites avec Simple Form, `auth_card`, `form_error_notification` et `button_classes`. Les quatre pages : Connexion, Créer un compte, Recevoir un lien, Nouveau mot de passe. Un lien de réinitialisation expiré est signalé en haut du formulaire, avec un lien « Recevoir un nouveau lien »
- `devise/shared/_links` n'est plus rendu par nos vues, et `devise/shared/_error_messages` non plus : gardés pour les pages Devise intégrées (confirmation par e-mail, déblocage) si ces modules sont activés un jour
- Clé `devise-i18n` surchargée : `devise.passwords.new.send_me_reset_password_instructions` (« Envoyer le lien »), le texte d'origine était trop long pour un bouton

Fait dans `feature/p1-password-rules` :

- Mot de passe de 12 caractères minimum (`config.password_length = 12..128` dans `config/initializers/devise.rb`). Aide « 12 caractères minimum » / « 12 characters minimum » (surcharge de `devise.shared.minimum_password_length`). Les comptes créés avant gardent leur mot de passe : Devise ne vérifie la longueur que quand on en choisit un
- Bouton œil sur tous les champs mot de passe, aide cachée sur un champ en erreur, correctif de l'indicateur de majuscules de Safari (voir Composants)

Fait dans `feature/p1-app-navbar` :

- Barre connectée de 64 px : logo (mène à l'accueil, futur « Mes tables »), interrupteur de thème, avatar et e-mail (avatar seul sur téléphone) qui ouvrent le menu du compte : « Mes tables », « Paramètres » (page du compte en attendant la page Paramètres), « Se déconnecter ». Barre des visiteurs : sélecteur à trois choix, « Se connecter », « S'inscrire »
- `account_page?` utilisable dans les vues (`helper_method`) : « Paramètres » reste la page en cours quand le formulaire du compte revient avec une erreur (adresse `/users`)
- Le choix « Système » n'existe plus pour un utilisateur connecté jusqu'à la page Paramètres (rubrique Affichage) : toucher l'interrupteur quitte le mode Système
- Écarts volontaires avec la fiche Maquettes : pas de liens « Mes tables » ni « Mon compte » dans la barre (dans le menu de l'avatar, demandé par l'équipe ; des liens reviendront dans la barre quand il y aura une deuxième destination, comme « Mes modèles de cartes »), déconnexion dans le menu (et aussi dans Paramètres, plus tard), interrupteur sans bordure avec une piste beige en clair. **Écart à la règle de contraste de forme** : piste sur la barre 1,37 (clair) et 1,21 (sombre), rond sur la piste 1,4 et 2,35. Un rond blanc ne peut pas atteindre 3 sur une piste claire, et les bordures ont été refusées. Les icônes identifient l'interrupteur et son état (toutes au-dessus de 3), ce qui reste conforme à WCAG 1.4.11

Fait dans `feature/p1-dashboard` :

- Page « Mes tables » (`TablesController#index`, `/tables`) : en-tête avec le bouton « Créer une table », grille de cartes (1 colonne sur téléphone, 2 à partir de 768 px, 3 à partir de 1024 px, 24 px d'écart) et carte vide en pointillés (`tables/_empty_state`), affichée seulement si `@tables` est vide. `@tables` vaut `[]` en attendant le modèle `Table`
- « Créer une table » mène à une page provisoire (`TablesController#new`, `/tables/new`) qui annonce la création à venir
- Arrivée sur « Mes tables » après la connexion, l'inscription et la modification du compte : `signed_in_root_path` renvoie `game_tables_path` (`ApplicationController`). Une page demandée avant la connexion passe en premier. Un utilisateur connecté qui ouvre l'accueil y est redirigé ; le logo et le lien du menu y mènent (`logo_path`)
- Zone principale du layout `application` : 1120 px au maximum, marges de 32 px (16 px sur téléphone), 40 px en haut et en bas
- Écarts volontaires avec la fiche Maquettes : bouton « Créer une table » visible dès maintenant (page provisoire) ; pointillés de la carte vide en `line` gardés, même s'ils se voient peu en clair (1,2)
- **Question ouverte** : le mot « table » (jargon de rôliste) est-il assez clair ? Pistes : « Mes campagnes », « Mes parties ». À trancher avec Julien. Si le terme change, seul le texte affiché change a priori : `tables` reste dans le code et la base

Fait dans `feature/p1-account-settings` :

- Page Paramètres : `/settings` (`Settings::SectionsController`, liste des rubriques sur téléphone) et `/settings/display` (`Settings::DisplaysController`). Disposition essayée puis écartée : panneau encadré en deux colonnes (fiche Maquettes), puis écran coupé par un seul trait vertical ; retenue : menu sur la page et rubrique en carte. Menu des rubriques : « Affichage », et « Compte » qui mène encore à l'ancienne page `/users/edit` en attendant `feature/p1-account-security`. « Paramètres » du menu de l'avatar y mène, et reste la page en cours sur l'ancienne page du compte (`settings_page?`)
- Rubrique Affichage : thème à trois choix (contrôle segmenté, `settings/_theme_choices`) et langue de l'interface, enregistrée dès le changement de la liste et **sans mot de passe** (`Settings::LocalesController#update`, seule la langue est acceptée), confirmation dans la nouvelle langue
- Plusieurs contrôles de thème sur une page (interrupteur de la barre, choix d'Affichage) : `theme_controller.js` prévient les autres par l'événement `theme:changed` sur `window`
- Limite connue : sous Windows, dans Chrome, les flèches du clavier sur la liste fermée changent la valeur tout de suite, donc enregistrent la langue à chaque appui. La description de la ligne prévient l'utilisateur

Fait dans `feature/p1-account-security` :

- Rubrique Compte (`/settings/account`) : changement d'e-mail avec le mot de passe actuel (`Settings::EmailsController`), ligne « Se déconnecter », zone sensible « Supprimer mon compte » (bouton danger, `turbo_confirm`, action `destroy` de Devise)
- Rubrique Sécurité (`/settings/security`) : changement de mot de passe (`Settings::PasswordsController`), aide « 12 caractères minimum », l'utilisateur reste connecté (`bypass_sign_in`)
- Fin de l'ancienne page « Mon compte » : `/users/edit` et `PATCH /users` redirigent vers la rubrique Compte sans rien modifier (`Users::RegistrationsController`). Supprimés : la vue `devise/registrations/edit.html.erb`, `test/integration/account_locale_test.rb` (couvert par `settings_language_test.rb`), `account_page?`, la langue dans le formulaire Devise et ses traductions. Toutes les pages Devise prennent le layout `auth`

Fait dans `style/p1-ui-polish` (demandes de l'équipe) :

- Message « Connecté(e). » réservé aux lecteurs d'écran ; focus clavier aux couleurs du thème partout ; icône parchemin (Lucide `scroll-text`) pour « Mes tables » dans le menu de l'avatar ; messages des Paramètres dans la carte
- Thème : l'interrupteur de la barre est retiré (fichiers, couleurs `switch-*`, action `toggle`), l'écart de contraste qui le concernait n'a plus d'objet. Un seul sélecteur à trois choix avec icônes, pour les visiteurs (accueil, pages de connexion) et dans Paramètres (décision : « Système » reste accessible ; l'interrupteur seul sur l'accueil a été écarté)

Fait dans `chore/p1-github-ci` :

- Modèle de PR `.github/pull_request_template.md` (Quoi, Pourquoi, Comment tester, Captures, Checklist), proposé par GitHub à chaque nouvelle PR
- Intégration continue `.github/workflows/ci.yml`, sur chaque PR et chaque push sur `main` : job `lint` (`bin/rubocop -f github`) et job `test` (PostgreSQL 15, `bin/rails db:test:prepare test test:system`, captures des tests système en échec gardées comme artefact)
- Corrections pour que le lint passe : espaces retirés dans les `%i[ ]` du `Gemfile`, `vendor/**/*` ajouté à `Exclude` dans `.rubocop.yml` (voir À savoir)

Fait dans `feature/p1-username` :

- Pseudo (`users.username`), obligatoire et unique sans tenir compte des majuscules (index sur `lower(username)`), de 3 à 20 caractères : lettres (accents compris), chiffres, `-` et `_`, espaces autour retirés (`normalizes`). Il sert à s'afficher ; la connexion reste par e-mail (décision)
- Les comptes existants ont reçu par la migration un pseudo tiré de leur e-mail (un numéro ajouté en cas de doublon)
- Demandé en premier à l'inscription (`permit_username` dans `Users::RegistrationsController`, `autocomplete="nickname"` pour que les gestionnaires de mots de passe ne le prennent pas pour l'identifiant). Aide sous le champ par `simple_form.hints.user.username`, lue par Simple Form dans tous les formulaires
- Modifiable dans Paramètres › Compte, **sans mot de passe** (`Settings::UsernamesController`). Chaque formulaire de la rubrique a son propre objet (`@user_for_username`, `@user_for_email`) et son `id` : une erreur dans l'un ne s'affiche pas dans l'autre
- Le menu du compte affiche le pseudo à la place de l'e-mail

À savoir :

- Si `bin/dev` répond `foreman: not found` : lancer `rbenv rehash`
- Lancé en tâche de fond par Claude Code, le processus `css` de `bin/dev` s'arrête faute de terminal. Contournement : `tail -f /dev/null | bin/dev`. Ne pas modifier `Procfile.dev` pour ça
- `config.mailer_sender` dans `config/initializers/devise.rb` vaut encore l'adresse d'exemple : à changer avant de tester le mot de passe oublié en production
- Les contrôleurs Devise déclarent leurs vérifications avec `prepend_before_action` : elles passent avant le concern `Locale`, donc dans la langue par défaut. Un message Devise resté en anglais vient en général de là. Correction : un sous-contrôleur dans `app/controllers/users/` qui inclut `DeviseLocale`, et sa ligne dans `devise_for` (`config/routes.rb`)
- `flash.delete(:notice)` renvoie le flash entier, pas le message (contrairement à un `Hash`) : lire le message d'abord, puis le supprimer. Ranger le flash dans lui-même faisait planter la session (« stack level too deep »)
- `update_with_password` (Devise), deux pièges : avec un mauvais mot de passe, il met quand même les nouvelles valeurs sur l'objet sans les enregistrer (si c'est `current_user`, la barre affiche l'e-mail refusé : travailler sur `User.find(current_user.id)`) ; et un nouveau mot de passe **vide** veut dire « ne rien changer », compté comme un succès (le refuser avant, voir `Settings::PasswordsController`). Après un changement de mot de passe, Devise déconnecte : `bypass_sign_in`
- Pas de langue dans l'URL (`/fr/...`), décision prise : ça compliquerait toutes les routes, Devise compris
- `theme_preload.js` et `controllers/theme_controller.js` lisent le même choix : même clé `theme`, mêmes valeurs (`light`, `dark`, rien pour Système). Modifier l'un, c'est modifier l'autre
- Les fichiers de `public/` sont gardés un an par les navigateurs (`cache-control` de `config/environments/production.rb`). Une police ou une image qui y est placée porte sa version dans son nom (`InterVariable-4.1.woff2`) : une nouvelle version change de nom, sinon les visiteurs gardent l'ancienne
- Tests système : au premier lancement, `selenium-webdriver` télécharge `chromedriver` tout seul dans `~/.cache/selenium`. Entre deux tests, Capybara vide les cookies et `localStorage` : inutile de les nettoyer dans un `setup`. Le Chrome des tests n'envoie pas forcément l'anglais comme langue : viser un bouton par sélecteur (`find("input[type=submit]")`), pas par son texte
- Tests système et `plausible.io` : Selenium Manager (programme de `selenium-webdriver` qui trouve `chromedriver`) envoie des statistiques d'usage à `plausible.io` à chaque lancement. Coupé par `ENV["SE_AVOID_STATS"] = "true"` en tête de `test/application_system_test_case.rb` (vérifié avec ses journaux en mode debug). Ne pas retirer cette ligne
- Test d'une erreur de validation : `errors.added?(:username, :invalid)` échoue pour une erreur de format, car Rails y range la valeur refusée (`value:`) et `added?` compare tous les détails. Utiliser `errors.of_kind?(:username, :invalid)`. Et lancer la validation avant de lire `errors` (`user.tap(&:validate).errors`)
- Capybara : `visible: false` veut dire « visible ou non », **pas** « caché ». Pour vérifier qu'un élément est caché : `assert_selector "#user-menu", visible: :hidden`. Un test avec `visible: false` passe toujours
- Tests système, taille téléphone : Chrome refuse une fenêtre de moins de 500 px. Pour 390 px, passer par `execute_cdp("Emulation.setDeviceMetricsOverride", ...)`. Un réglage d'émulation (`Emulation.setEmulatedMedia` pour un appareil en sombre) reste actif pour le test suivant : Capybara garde le même Chrome. Le remettre à zéro dans un `teardown` (voir `test/system/theme_switch_test.rb`)
- Test d'un helper qui rend un partiel (`ActionView::TestCase`) : l'appeler par `view.` (`view.nav_link_to(...)`). Appelé sur le test lui-même, le `render` écrit dans la sortie du test au lieu de renvoyer le HTML
- Dans les tests, le mot de passe des comptes est la constante `TEST_PASSWORD` (`test/test_helper.rb`), assez longue pour la règle des 12 caractères. Ne pas réécrire un mot de passe en dur
- Safari n'a pas pu être piloté par les tests (`safaridriver --enable` fait, « Autoriser l'automatisation à distance » coché, mais la session expire). Les vérifications propres à Safari se font à la main
- Au-delà de 50 tests, Rails les lance en parallèle (un processus par cœur) et crée une base de test par processus (`jdr_online_test_0`, `_1`...). C'est normal, on les garde
- Minitest 6 n'inclut plus `minitest/mock` (gem à part, non installée) : pas de `stub`. Pour simuler la production dans un test, `Rails.env = "production"`, puis remettre l'environnement d'origine dans un `ensure` (voir `test/integration/component_gallery_test.rb`)
- Une classe Tailwind avec opacité sur une couleur nommée (`ring-primary-soft-ink/50`) suit bien le thème : Tailwind écrit une valeur claire figée pour les vieux navigateurs, puis la vraie règle avec `color-mix()` et la variable
- Un fichier de `config/initializers/` (Simple Form, Devise...) n'est lu qu'au démarrage : **relancer `bin/dev`** après l'avoir modifié, sinon le serveur garde l'ancienne configuration (par exemple les anciennes classes des champs). Même chose pour un nouveau dossier dans `app/`, comme `app/inputs/`
- Simple Form, case à cocher : avec `boolean_style = :nested`, seul le composant `:label_input` écrit le texte du libellé. Un wrapper qui n'utilise que `:input` affiche une case sans libellé. D'où `:inline` et le wrapper `:boolean`
- Liste ouverte des `<select>` : une version stylée (`appearance: base-select`) a été essayée puis retirée. Chrome ne déplace pas le focus quand la souris bouge : après les flèches, le survol ne suivait plus la souris sans JavaScript en plus. Il fallait aussi du CSS hors des couches Tailwind, et Firefox ne la gère pas. Ne pas la remettre sans revoir ces points
- RuboCop signale `Metrics/BlockLength` (36/25) sur le bloc `SimpleForm.setup`, et `Layout/EmptyLineAfterMagicComment` en tête du fichier (ligne générée par Simple Form) : accepté, `config/**` étant exclu de l'analyse, à trancher dans `chore/p1-rubocop-config`
- La liste `Exclude` de `.rubocop.yml` **remplace** celle de RuboCop au lieu de la compléter : un dossier ignoré par défaut doit y être écrit. `vendor/**/*` doit y rester : sur GitHub Actions, `bundler-cache` installe les gems dans `vendor/bundle`, et sans cette ligne RuboCop analyse toutes les gems (plus d'un million d'erreurs, job de 6 minutes). En local, les gems sont ailleurs : l'erreur ne se voit qu'en CI
- Clés courtes et `render layout:` : dans un bloc `render layout: "shared/message" do … end`, `t(".submit")` est cherché sous le partiel (`shared.message.submit`), pas sous la page, et lève « Translation missing ». Pour la carte des pages visiteurs, le helper `auth_card` règle ça (il lit le bloc avec `capture` avant de rendre le partiel). Ailleurs, dans un cas isolé, écrire la clé complète avec un commentaire (voir `devise/passwords/edit`)

## Prochaines tâches

Dans cet ordre. Chaque tâche a sa branche et sa Pull Request.

### Interface : fiche Maquettes terminée

Tout ce que prévoyait la fiche `Maquettes-pages-compte.md` (Obsidian) est fait : pages de connexion, barre de navigation, « Mes tables » et Paramètres, avec les écarts décidés par l'équipe et notés dans État du projet.

### Production Heroku : `chore/p1-heroku-setup`

- Redis pour Action Cable en production (`config/cable.yml`), à la place de Solid Cable
- `mailer_sender` réel et service d'envoi d'e-mails
- Voir la checklist de déploiement du projet

### Plus tard

- Fermeture des messages flash : contrôleur Stimulus, branche dédiée
- Branche du modèle `Table` : `@tables = current_user.tables` dans `TablesController#index` (avec `includes` pour éviter le N+1), cartes de table dans la grille, test « dès la première table, la carte vide disparaît », vrai formulaire à la place de la page provisoire `tables/new`
- Bonus, non prioritaire : vérifier un champ dès qu'on le quitte (blur), avec un contrôleur Stimulus, le serveur restant seul juge. Poser `aria-invalid` sur le champ suffit pour le style d'erreur et pour cacher l'aide
- RuboCop, branche `chore/p1-rubocop-config` : le `.rubocop.yml` de Le Wagon ignore la gem `rubocop-rails-omakase` (installée par Rails) et exclut `config/**` et `test/**` de l'analyse. Choisir un seul style et décider quels dossiers analyser. En attendant, lancer RuboCop fichier par fichier sur les fichiers de `config` et `test` modifiés
- Quand Julien rejoint le dépôt : l'ajouter comme collaborateur et passer la protection de `main` à une approbation obligatoire

À ne pas toucher sans le demander : Kamal, `Dockerfile`, `config/deploy.yml`, Solid Cache et Solid Queue.

## Documentation du projet

Les documents de conception (MVP, user stories, base de données, planning, versionnage Git, hébergement) sont tenus hors du dépôt, dans le projet Claude et dans Obsidian. Si une décision de conception manque ici, la demander plutôt que de l'inventer.
