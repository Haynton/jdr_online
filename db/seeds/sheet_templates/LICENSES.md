# Sources et licences des modèles prédéfinis

Les modèles de ce dossier sont chargés par `db/seeds.rb`. Leurs règles viennent de deux documents publiés sous licence libre. Les textes (descriptions des créatures et des objets, aides) sont rédigés par l'équipe. Aucun nom de jeu existant n'est utilisé : ce sont des marques.

Ces mentions doivent aussi apparaître dans les mentions légales de l'application (tâche « Mentions légales et politique de confidentialité »).

## Fantasy héroïque (`heroic_fantasy.*.json`)

La fiche du personnage suit les règles de 2024 : classes, historiques, espèces, sorts par niveau, d'après le System Reference Document 5.2, sous licence Creative Commons Attribution 4.0. Les données ont été relevées sur l'API ouverte dnd5eapi.co (`/api/2024`), qui publie le SRD 5.2, et ne sont jamais appelées par l'application. Mention d'attribution, telle que donnée par l'éditeur (à revérifier sur https://www.dndbeyond.com/srd avant une mise en ligne publique) :

> This work includes material from the System Reference Document 5.2 ("SRD 5.2") by Wizards of the Coast LLC, available at https://www.dndbeyond.com/srd. The SRD 5.2 is licensed under the Creative Commons Attribution 4.0 International License, available at https://creativecommons.org/licenses/by/4.0/legalcode.

Les sorts du catalogue (`db/seeds/catalogs/heroic_fantasy_spells.*.json`, sorts mineurs et niveaux 1 et 2 pour l'instant) viennent aussi du SRD 5.2, relevés sur la même API. Le texte anglais est celui du SRD, corrigé là où la source était mal extraite (paragraphes, tableau d'Augure, statistiques du destrier) ; le texte français est notre traduction du SRD, jamais celle d'un livre publié, avec les distances en mètres (1,50 mètre pour 5 pieds). Même mention d'attribution que ci-dessus.

Les PNJ, les monstres et les objets prêts à l'emploi viennent encore du System Reference Document 5.1, sous la même licence. Mention d'attribution, telle que demandée par l'éditeur :

> This work includes material taken from the System Reference Document 5.1 ("SRD 5.1") by Wizards of the Coast LLC and available at https://dnd.wizards.com/resources/systems-reference-document. The SRD 5.1 is licensed under the Creative Commons Attribution 4.0 International License available at https://creativecommons.org/licenses/by/4.0/legalcode.

Modifications : sélection des règles, traduction en français, textes réécrits.

## Horreur cosmique (`cosmic_horror.*.json`)

D'après le moteur Basic Roleplaying de Chaosium, sous licence ORC. Mention, telle que donnée par Chaosium sur https://www.chaosium.com/orclicense/ :

> This product is licensed under the ORC License held in the Library of Congress at TX 9-307-067 and available online at various locations including www.chaosium.com/orclicense, www.azoralaw.com/orclicense, www.gencon.com/orclicense and others. All warranties are disclaimed as set forth therein.
>
> This product is based on the following Licensed Material: "Basic Roleplaying: Universal Game Engine," copyright © 2024 Chaosium Inc., by Jason Durall and Steve Perrin.

Choix faits pour rester dans la licence :

- Les marques de Chaosium ne sont jamais utilisées
- La santé mentale est une simple ressource qui baisse face à l'horreur, sans crises ni folies graduées
- Les créatures (goule, profond, mi-go) viennent des récits de H. P. Lovecraft, dans le domaine public en Europe. Leurs valeurs et leurs descriptions sont les nôtres

À vérifier avant une mise en ligne publique : le texte complet de la licence ORC (https://www.chaosium.com/content/orclicense/ORC_License_FINAL.pdf) et l'usage du logo « Powered by BRP » demandé par Chaosium.
