# Fumble Quest sur Heroku

Ce qu'il faut savoir pour mettre l'application en ligne et l'entretenir. Toute commande `heroku` se valide avant d'être lancée (règle de `CLAUDE.md`).

## L'application

| | |
|---|---|
| Nom de l'application | `fumble-quest` |
| Adresse | https://fumble-quest-66f12d3412f1.herokuapp.com (Heroku ajoute un suffixe au nom) |
| Région | Europe |
| Base de données | `heroku-postgresql:essential-0` (5 $ par mois au plus), une seule base : Solid Cable, Solid Queue et Solid Cache y ont leurs tables |
| Remote git | `heroku` (`https://git.heroku.com/fumble-quest.git`) |
| Ruby | celui de `.ruby-version` (3.3.5), lu par Heroku dans `Gemfile.lock` |

## Variables d'environnement

| Variable | Rôle | Posée par |
|---|---|---|
| `RAILS_MASTER_KEY` | Ouvre les secrets chiffrés de Rails (`config/credentials.yml.enc`). Sans elle, l'application ne démarre pas | Anthony, depuis son terminal, sans jamais afficher la valeur |
| `APP_HOST` | L'adresse du site dans les liens des e-mails (mot de passe oublié), sans `https://` | Heroku, `heroku config:set` |
| `BREVO_SMTP_LOGIN` et `BREVO_SMTP_KEY` | L'identifiant et la clé SMTP de Brevo, qui envoie les e-mails (Brevo › SMTP & API › SMTP) | Anthony, depuis son terminal |
| `DATABASE_URL` | L'adresse de la base | Heroku, toute seule, à la création de la base |

Poser la clé (à lancer depuis le dossier du projet, la valeur n'apparaît pas) :

```bash
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key) -a fumble-quest
```

## Déployer

Toujours depuis `main` à jour, une fois la Pull Request fusionnée :

```bash
git switch main
git pull
git push heroku main
```

Les migrations passent toutes seules à chaque déploiement (`release` du `Procfile`), avant que la nouvelle version reçoive du trafic. Si elles échouent, l'ancienne version reste en ligne.

## Charger ou recharger les modèles fournis

Après le premier déploiement, puis après chaque modification d'un fichier de `db/seeds/sheet_templates` ou `db/seeds/catalogs` (une fois déployée) :

```bash
heroku run bin/rails sheet_templates:load -a fumble-quest
```

La tâche crée ou met à jour les modèles fournis et leurs catalogues, sans rien supprimer. Une table déjà créée garde sa copie du modèle : seules les tables créées ensuite ont la nouvelle version.

**Jamais `db:seed` en production** : le seed vide d'abord toute la base (comptes et tables compris).

## Vérifier

```bash
heroku releases -a fumble-quest -n 3
heroku ps -a fumble-quest
heroku logs --tail -a fumble-quest
```

- `https://…/up` répond 200 quand l'application tourne.
- `http://…` répond 301 vers `https://` (`force_ssl`).

## Autres commandes utiles

```bash
heroku open -a fumble-quest
heroku run bin/rails console -a fumble-quest
heroku config -a fumble-quest
```

## Reste à faire

- Quand une tâche de fond arrivera (IA) : `SOLID_QUEUE_IN_PUMA=true`, pour faire tourner Solid Queue dans Puma sans second dyno.
- Plus tard, en même temps que la CI : la pile Heroku-26 et la dernière version corrective de Ruby 3.3.
