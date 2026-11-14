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

## Commandes

- Lancer l'application : `bin/dev` (serveur et reconstruction du CSS Tailwind). Ne pas utiliser `rails s` seul une fois Tailwind installé
- Seule exception : l'étape 9 de la tâche en cours se teste avec `rails s`, car Tailwind n'est pas encore installé (à ce stade, `bin/dev` ne fait que lancer `rails server` ; c'est `tailwindcss:install` qui ajoute `Procfile.dev` et le watcher CSS)
- Base de données : `rails db:migrate`, `rails db:seed`
- Style Ruby : `bin/rubocop`
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
- Ne pas commiter `app/assets/builds/*` (CSS reconstruit automatiquement)

## Commandes à faire valider avant de les lancer

- Suppression de fichiers ou de dossiers (`rm`, `rm -rf`)
- Ajout ou retrait d'une gem
- Toute commande Heroku (`heroku ...`, `git push heroku`)
- Toute commande qui touche à la base autrement que `db:migrate`

## Tâche en cours : retirer Bootstrap et installer Tailwind

L'application vient d'être générée avec le template Devise de Le Wagon (Rails 8, branche `master` du template). Le template a installé Bootstrap, Font Awesome et les feuilles de style Le Wagon. Ce nettoyage est le seul travail fait directement sur `main`, avant le premier envoi sur GitHub.

Étapes, dans l'ordre, avec une vérification après chacune :

1. Gemfile : retirer `bootstrap`, `autoprefixer-rails`, `font-awesome-sass` et `sassc-rails`. Garder `sprockets-rails`, `devise`, `simple_form` (depuis GitHub) et `dotenv-rails`. Puis `bundle install`
2. Remplacer le dossier `app/assets/stylesheets` (SCSS Le Wagon) par un seul `application.css` vide
3. Retirer Bootstrap et Popper de `config/importmap.rb`, `app/javascript/application.js`, `config/initializers/assets.rb` et `app/assets/config/manifest.js`
4. Supprimer `config/initializers/simple_form_bootstrap.rb` (garder `simple_form.rb`)
5. Supprimer le dossier `app/views/devise` : Devise utilisera ses vues intégrées, sans Bootstrap
6. Supprimer `lib/templates/erb/scaffold/_form.html.erb` (modèle de formulaire Bootstrap)
7. Réécrire en Tailwind `app/views/shared/_navbar.html.erb` et `app/views/shared/_flashes.html.erb`, et retirer les classes Bootstrap du layout `app/views/layouts/application.html.erb`. Déconnexion avec `button_to ..., method: :delete`
8. Vérifier qu'il ne reste rien : `grep -rniE "bootstrap|popper|font-awesome|fontawesome|data-bs-" Gemfile app config lib`
9. Tester avec `rails s` (et non `bin/dev`, Tailwind n'étant pas encore installé) : connexion, inscription, déconnexion, aucune erreur dans le terminal ni dans la console du navigateur
10. Commit : `chore(setup): remove bootstrap, font awesome and le wagon stylesheets`
11. Installer Tailwind : `bundle add tailwindcss-rails`, puis `bin/rails tailwindcss:install`. Vérifier la version 4.x (`bundle list | grep tailwind`), la présence de `stylesheet_link_tag "tailwind"` dans le layout et de `//= link_tree ../builds` dans `manifest.js`
12. Tester avec `bin/dev` et une classe de test sur la page d'accueil
13. Commit : `chore(setup): install tailwindcss-rails v4`

À ne pas toucher pendant cette tâche :

- `config/cable.yml` : la production passera à Redis dans une branche dédiée (`chore/p1-heroku-setup`)
- Kamal, `Dockerfile`, `config/deploy.yml`, Solid Cache et Solid Queue
- Les migrations et `db/schema.rb`

## Documentation du projet

Les documents de conception (MVP, user stories, base de données, planning, versionnage Git, hébergement) sont tenus hors du dépôt, dans le projet Claude et dans Obsidian. Si une décision de conception manque ici, la demander plutôt que de l'inventer.
