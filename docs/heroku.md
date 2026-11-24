# Fumble Quest sur Heroku

Ce qu'il faut savoir pour mettre l'application en ligne et l'entretenir. Toute commande `heroku` se valide avant d'être lancée (règle de `CLAUDE.md`).

## L'application

| | |
|---|---|
| Adresse du site | https://www.fumblequest.com |
| Adresse Heroku | https://fumble-quest-66f12d3412f1.herokuapp.com (Heroku ajoute un suffixe au nom) |
| Nom de l'application | `fumble-quest`, région Europe |
| Base de données | `heroku-postgresql:essential-0` (5 $ par mois au plus), une seule base : Solid Cable, Solid Queue et Solid Cache y ont leurs tables |
| Remote git | `heroku` (`https://git.heroku.com/fumble-quest.git`) |
| Ruby | celui de `.ruby-version` (3.3.5), lu par Heroku dans `Gemfile.lock` |

## Variables d'environnement

| Variable | Rôle | Posée par |
|---|---|---|
| `RAILS_MASTER_KEY` | Ouvre les secrets chiffrés de Rails (`config/credentials.yml.enc`). Sans elle, l'application ne démarre pas | Anthony, sortie jetée (voir plus bas) |
| `APP_HOST` | L'adresse du site dans les liens des e-mails, sans `https://` : `www.fumblequest.com` | `heroku config:set` |
| `BREVO_SMTP_LOGIN` | L'identifiant SMTP de Brevo, **complet** : `…@smtp-brevo.com` (Brevo › SMTP & API › SMTP, champ « Connexion »), pas l'adresse du compte | Anthony |
| `BREVO_SMTP_KEY` | La clé SMTP de Brevo, qui commence par `xsmtpsib-` (une clé API `xkeysib-` ne marche pas en SMTP) | Anthony, sortie jetée |
| `CLOUDINARY_URL` | Le compte Cloudinary qui stocke les images des cartes : `cloudinary://<API Key>:<API Secret>@<Cloud name>` (voir « Images (Cloudinary) ») | Anthony, sortie jetée |
| `DATABASE_URL` | L'adresse de la base | Heroku, toute seule |

**Attention : `heroku config:set` réécrit toujours la valeur qu'il vient de poser.** Pour un secret, toujours jeter sa sortie avec `> /dev/null`, sinon le secret s'affiche dans le terminal :

```bash
heroku config:set RAILS_MASTER_KEY="$(cat config/master.key)" -a fumble-quest > /dev/null
```

Pour une valeur qu'on colle à la main (la clé de Brevo), la demander sans l'afficher ni la garder dans l'historique :

```bash
read -s "BREVO_KEY?Clé SMTP Brevo : " && heroku config:set BREVO_SMTP_KEY="$BREVO_KEY" -a fumble-quest > /dev/null; unset BREVO_KEY
```

(Laisser `$BREVO_KEY` tel quel : on colle la clé seulement quand la question apparaît.)

## Déployer

Toujours depuis `main` à jour, une fois la Pull Request fusionnée :

```bash
git switch main
git pull
git push heroku main
```

Les migrations passent toutes seules à chaque déploiement (`release` du `Procfile`), avant que la nouvelle version reçoive du trafic. Si elles échouent, l'ancienne version reste en ligne.

À savoir : la commande `release` tourne aussi **à chaque changement de variable**, avec le code déjà en ligne. Si elle échoue, Heroku **annule** le changement de variable (« release command failed » dans `heroku releases`).

## Charger ou recharger les modèles fournis

Après le premier déploiement, puis après chaque modification d'un fichier de `db/seeds/sheet_templates` ou `db/seeds/catalogs` (une fois déployée) :

```bash
heroku run bin/rails sheet_templates:load -a fumble-quest
```

La tâche crée ou met à jour les modèles fournis et leurs catalogues, sans rien supprimer. Une table déjà créée garde sa copie du modèle : seules les tables créées ensuite ont la nouvelle version.

**Jamais `db:seed` en production** : le seed vide d'abord toute la base (comptes et tables compris).

## Domaine (OVH)

- `www.fumblequest.com` : un enregistrement **CNAME** chez OVH (Zone DNS), sous-domaine `www`, vers la cible donnée par Heroku (`heroku domains -a fumble-quest`), avec le point final. Aucun autre enregistrement ne doit exister pour `www` (OVH crée par défaut un A et un TXT `3|welcome` : à supprimer, sinon le CNAME est refusé).
- `fumblequest.com` sans www : redirection web d'OVH (onglet Redirection) vers `https://www.fumblequest.com`. Il n'est pas déclaré sur Heroku : OVH n'a pas d'enregistrement ALIAS pour un domaine nu.
- Certificat HTTPS : automatique (`heroku certs:auto -a fumble-quest` pour voir son état). Après un changement de DNS, compter jusqu'à une heure (durée du cache de l'ancien enregistrement), puis `heroku certs:auto:refresh -a fumble-quest` si besoin.

## E-mails (Brevo)

- Le domaine est authentifié chez Brevo par 4 enregistrements DNS chez OVH : `brevo-code` (TXT sur `fumblequest.com`), `brevo1._domainkey` et `brevo2._domainkey` (CNAME, signature DKIM), `_dmarc` (TXT). Le SPF d'OVH (`v=spf1 include:mx.ovh.com -all`) reste tel quel : il ne doit jamais y en avoir deux.
- Expéditeur : `noreply@fumblequest.com`.
- **Blocage des IP inconnues désactivé** dans Brevo (Sécurité › IP autorisées) : les adresses de Heroku changent à chaque redémarrage. Sinon, erreur `525 Unauthorized IP address`.
- Si « Mot de passe oublié » répond « L'e-mail n'a pas pu être envoyé » : `heroku logs -n 300 -a fumble-quest`, chercher `SMTP`. `535 Authentication failed` : identifiant ou clé faux. `525 Unauthorized IP address` : le blocage des IP.

## Images (Cloudinary)

Les images des cartes vont chez Cloudinary en production (Active Storage, service `cloudinary` de `config/storage.yml`, dossier `fumble_quest_production`) ; en développement et en test, elles restent sur le disque (`storage/`).

- La valeur de `CLOUDINARY_URL` est **une seule adresse** : `cloudinary://<API Key>:<API Secret>@<Cloud name>`. Les trois sont dans Cloudinary › Settings › API Keys (le Cloud name en haut de la page, la clé et le secret dans le tableau, le secret montré par l'œil).
- **Piège** : la ligne toute prête de cette page (« API environment variable ») cache le secret sous le texte `<your_api_secret>`, et commence par `CLOUDINARY_URL=`. Dans Heroku, la valeur commence par `cloudinary://` (le nom va dans l'autre case), et `<your_api_secret>`, chevrons compris, est remplacé par le vrai secret.
- **Une valeur mal formée fait planter le site au démarrage** (« Application error ») : la gem `cloudinary` lit la variable dès que Rails démarre. Le 24 novembre, le site est tombé ainsi juste après le déploiement de l'étape Cartes ; il est revenu en corrigeant la valeur dans Settings › Config Vars (Heroku relance l'application seul). Pour vérifier le début de la valeur sans afficher le secret :

```bash
heroku config:get CLOUDINARY_URL -a fumble-quest | cut -c1-15
```

## Changer la clé de Rails

Si `config/master.key` a été vue par quelqu'un d'autre (affichée, envoyée par erreur), elle est brûlée : on la remplace. Poser la nouvelle clé avant ou après le déploiement échoue (voir « Déployer » : la commande `release` tourne avec le code en ligne, et Heroku annule ce qui échoue). L'ordre qui marche, une commande à la fois, en vérifiant chaque version avec `heroku releases -a fumble-quest -n 1` :

1. En local, dans une branche : supprimer `config/credentials.yml.enc` et `config/master.key`, puis `EDITOR=true bin/rails credentials:edit > /dev/null` (sans `> /dev/null`, Rails affiche la nouvelle clé). Recopier dans les nouveaux credentials ce que contenaient les anciens (aujourd'hui, seulement `secret_key_base`, recréé tout seul). Commiter `credentials.yml.enc`, Pull Request, fusion.
2. Donner à Heroku un secret provisoire et vider la clé :
   `heroku config:set SECRET_KEY_BASE="$(bin/rails secret)" RAILS_MASTER_KEY="" -a fumble-quest > /dev/null`
3. Déployer : `git push heroku main`
4. Poser la nouvelle clé : `heroku config:set RAILS_MASTER_KEY="$(cat config/master.key)" -a fumble-quest > /dev/null`
5. Retirer le secret provisoire (sinon il passe avant celui des credentials) : `heroku config:unset SECRET_KEY_BASE -a fumble-quest`
6. Envoyer la nouvelle `config/master.key` aux autres membres de l'équipe par un canal privé.

Chacun devra se reconnecter une fois (nouveau `secret_key_base`).

## Vérifier

```bash
heroku releases -a fumble-quest -n 3
heroku ps -a fumble-quest
heroku logs --tail -a fumble-quest
```

- `https://www.fumblequest.com/up` répond 200 quand l'application tourne.
- `http://…` répond 301 vers `https://` (`force_ssl`).

## Autres commandes utiles

```bash
heroku open -a fumble-quest
heroku run bin/rails console -a fumble-quest
heroku domains -a fumble-quest
```

## Reste à faire

- Quand une tâche de fond arrivera (IA) : `SOLID_QUEUE_IN_PUMA=true`, pour faire tourner Solid Queue dans Puma sans second dyno.
- Plus tard, en même temps que la CI : la pile Heroku-26 et la dernière version corrective de Ruby 3.3.
