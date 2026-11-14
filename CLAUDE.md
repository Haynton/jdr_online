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

### Couleurs et thème

- L'application propose trois thèmes : clair, sombre et système (suit le réglage de l'appareil)
- Utiliser les **couleurs nommées** du projet (`bg-page`, `bg-surface`, `text-ink`, `border-line`...), définies dans `app/assets/tailwind/application.css`. Elles changent toutes seules en mode sombre : pas besoin d'écrire `dark:` à chaque élément
- Pas de couleur brute (`bg-gray-800`, `#1f2937`) dans les vues, sauf cas isolé justifié. S'il manque une couleur, l'ajouter aux couleurs nommées
- `dark:` reste possible pour un ajustement ponctuel (une ombre, une image)
- Référence visuelle du mode sombre : les wireframes du projet (police Inter, vert principal `#2E7D6B`)

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

## État du projet

Fait, sur `main`, avant le premier envoi sur GitHub :

- Application générée avec le template Devise de Le Wagon (Rails 8.1)
- Bootstrap, Font Awesome et les feuilles de style Le Wagon retirés. Les vues Devise copiées dans `app/views/devise` ont été supprimées : Devise utilise ses vues intégrées
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

À savoir :

- Si `bin/dev` répond `foreman: not found` : lancer `rbenv rehash`
- Lancé en tâche de fond par Claude Code, le processus `css` de `bin/dev` s'arrête faute de terminal. Contournement : `tail -f /dev/null | bin/dev`. Ne pas modifier `Procfile.dev` pour ça
- `config.mailer_sender` dans `config/initializers/devise.rb` vaut encore l'adresse d'exemple : à changer avant de tester le mot de passe oublié en production
- Les contrôleurs Devise déclarent leurs vérifications avec `prepend_before_action` : elles passent avant le concern `Locale`, donc dans la langue par défaut. Un message Devise resté en anglais vient en général de là

## Prochaines tâches

Dans cet ordre. Chaque tâche a sa branche et sa Pull Request.

### Langue dans Mon compte : `feature/p1-account-locale`

Suite de `chore/p1-i18n-setup`, depuis `main` une fois cette PR fusionnée.

- Vues d'inscription et de modification du compte générées avec `rails g devise:i18n:views`, limité aux registrations. Vérifier qu'elles ne contiennent aucune classe Bootstrap
- Sélecteur de langue (`fr`, `en`, ou « langue du navigateur » pour revenir à `nil`) dans la page Mon compte, avec `devise_parameter_sanitizer.permit(:account_update, keys: [:locale])`
- Nom de l'attribut traduit : `activerecord.attributes.user.locale` dans `fr.yml` et `en.yml`
- Message « You are already signed in. » encore en anglais : `require_no_authentication` de Devise passe avant le concern `Locale` et ne passe pas par la failure app (cas d'un utilisateur connecté qui ouvre `/users/sign_in`)
- Pas de langue dans l'URL (`/fr/...`) : ça complique toutes les routes, Devise compris

### Thème clair, sombre ou système : `chore/p1-theme`

- Dans `app/assets/tailwind/application.css`, après `@import "tailwindcss";` :
  - `@custom-variant dark (&:where(.dark, .dark *));` pour que `dark:` dépende d'une classe `.dark` sur `<html>` et plus seulement du réglage de l'appareil
  - les couleurs nommées dans un bloc `@theme`, avec leurs valeurs claires, puis leurs valeurs sombres redéfinies dans un bloc `.dark { ... }`
- Couleurs du mode sombre, reprises des wireframes :

| Couleur nommée | Rôle | Sombre (wireframes) | Clair, parchemin léger |
|---|---|---|---|
| `page` | Fond de page | `#0f1520` | `#faf6ee` |
| `surface` | Cartes, panneaux, barre de navigation | `#1f2937` | `#fffdf9` |
| `field` | Fond des champs | `#111827` | `#ffffff` |
| `line` | Bordures | `#374151` | `#ebe3d3` |
| `ink` | Texte principal | `#f9fafb` | `#27211a` |
| `muted` | Texte secondaire | `#9ca3af` | `#7b7062` |
| `primary` | Bouton principal (texte blanc) | `#2E7D6B` | `#2E7D6B` |
| `link` | Liens | `#7fd1bd` | `#2E7D6B` |
| `danger` | Bouton de suppression | `#b91c1c` | `#b91c1c` |
| `success-bg` / `success-line` / `success-ink` | Message de succès (`notice`) | `#12302a` / `#2E7D6B` / `#a7e3d4` | `#e9f1e5` / `#c3d8b8` / `#2f5d3a` |
| `error-bg` / `error-line` / `error-ink` | Message d'erreur (`alert`) | `#3b1d1d` / `#7f2d2d` / `#f87171` | `#fbe9e4` / `#eec3b8` / `#9b2c1f` |

- Palette décidée : vert `#2E7D6B` comme couleur principale dans les deux thèmes, parchemin léger pour le thème clair (fond légèrement chaud, texte brun très foncé plutôt que noir)
- Le vert des boutons et le vert des messages de succès sont deux couleurs nommées distinctes : ne pas utiliser `primary` pour un message de succès
- Contraste minimum visé : 4,5 pour le texte (critère WCAG AA). Le texte blanc sur `primary` est à environ 4,9 : ne pas éclaircir ce vert
- Police Inter, comme dans les wireframes
- Choix du thème (décidé) : enregistré dans `localStorage`, donc propre à chaque navigateur (méthode de la documentation Tailwind). Petit script dans le `<head>` du layout, avant l'affichage, pour poser la classe `.dark` sans flash blanc au chargement. Contrôleur Stimulus `theme_controller.js` pour le sélecteur clair, sombre, système
- Remplacer les couleurs brutes de la navbar, des flashes et du layout par les couleurs nommées

### Production Heroku : `chore/p1-heroku-setup`

- Redis pour Action Cable en production (`config/cable.yml`), à la place de Solid Cable
- `mailer_sender` réel et service d'envoi d'e-mails
- Voir la checklist de déploiement du projet

### Plus tard

- Fermeture des messages flash : contrôleur Stimulus, branche dédiée
- RuboCop, branche `chore/p1-rubocop-config` : le `.rubocop.yml` de Le Wagon ignore la gem `rubocop-rails-omakase` (installée par Rails) et exclut `config/**` et `test/**` de l'analyse. Choisir un seul style et décider quels dossiers analyser. En attendant, lancer RuboCop fichier par fichier sur les fichiers de `config` et `test` modifiés
- `config/initializers/devise.rb` contient, en commentaire, deux valeurs aléatoires générées à l'installation (`config.secret_key` et `config.pepper`). Elles ne servent pas (Devise utilise `secret_key_base`), mais le dépôt est public : les supprimer, et ne jamais les décommenter telles quelles
- Créer `.github/pull_request_template.md` avec le modèle de PR du document Versionnage-git (Quoi, Pourquoi, Comment tester, Captures, Checklist), pour que GitHub le propose à chaque nouvelle PR
- Ajouter une intégration continue GitHub Actions qui lance les tests et RuboCop sur chaque PR (`.github/workflows/` est vide : aucune vérification automatique pour l'instant)
- Quand Julien rejoint le dépôt : l'ajouter comme collaborateur et passer la protection de `main` à une approbation obligatoire

À ne pas toucher sans le demander : Kamal, `Dockerfile`, `config/deploy.yml`, Solid Cache et Solid Queue.

## Documentation du projet

Les documents de conception (MVP, user stories, base de données, planning, versionnage Git, hébergement) sont tenus hors du dépôt, dans le projet Claude et dans Obsidian. Si une décision de conception manque ici, la demander plutôt que de l'inventer.
