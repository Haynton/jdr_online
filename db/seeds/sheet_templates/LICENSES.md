# Sources et licences des modèles prédéfinis

Les modèles de ce dossier sont chargés par `db/seeds.rb`. Leurs règles viennent de deux documents publiés sous licence libre. Les textes (descriptions des créatures et des objets, aides) sont rédigés par l'équipe. Aucun nom de jeu existant n'est utilisé : ce sont des marques.

Ces mentions sont aussi affichées par l'application, sur la page Mentions légales (`/legal`, textes dans `legal.show` de `config/locales`) : modifier l'une, c'est modifier l'autre.

## Fantasy héroïque (`heroic_fantasy.*.json`)

Tout le modèle suit le System Reference Document 5.2.1 (règles de 2024), publié par Wizards of the Coast le 1er mai 2025 sous licence Creative Commons Attribution 4.0 : la fiche du personnage (classes, sous-classes, historiques, espèces, sorts par niveau, emplacements), les objets prêts à l'emploi, et les catalogues (`db/seeds/catalogs/heroic_fantasy_*.json`) : les 339 sorts, les 95 objets de l'équipement de départ et les 329 créatures du bestiaire, de facteur de puissance 0 à 30. Les données ont été relevées sur l'API ouverte dnd5eapi.co (`/api/2024`), jamais appelée par l'application, puis **comparées le 25 novembre 2026 au PDF officiel du SRD 5.2.1** (https://www.dndbeyond.com/srd) : noms de tous les sorts, créatures, objets, classes, sous-classes, historiques et espèces ; niveau, école et classes de chaque sort ; CA, PV et FP de chaque créature ; sorts mineurs, sorts préparés et emplacements de chaque classe, niveau par niveau ; caractéristiques, don, compétences et outils de chaque historique ; poids et prix des objets. Corrigé ce jour-là d'après le PDF : le poids ou le prix de 15 objets (sac de couchage, clochette, couverture, sac de cambrioleur, chausse-trappes, chemise de mailles, vêtements de voyage, sac d'artiste, javeline, arc long, masse, parchemin, robe, lance, vielle), le rat-garou (une seule créature, et non trois formes), la corde et la torche des objets prêts à l'emploi. Le grimoire n'a pas de prix dans le SRD 5.2.1 (seulement dans la classe du magicien, 3 livres) : il garde 50 po.

Les 262 capacités, traits d'espèce et dons d'origine (`heroic_fantasy_features.*.json`, ajoutés le 26 novembre 2026) sont **des résumés écrits par l'équipe** (deux ou trois phrases, en français et en anglais, distances en mètres en français), d'après leurs textes du SRD 5.2.1 relevés sur la même API : ce sont des modifications du texte d'origine (CC BY 4.0, section 3(a)(1)(B)). Les noms anglais sont ceux du SRD, les noms français notre traduction. **À relire sur le PDF du SRD 5.2.1.**

Les 258 objets magiques (`heroic_fantasy_magic.*.json`, ajoutés le 27 novembre 2026) sont **des résumés écrits par l'équipe** (une ou deux phrases, en français et en anglais, distances en mètres et poids en kilos en français), d'après leur texte du SRD 5.2.1 relevé dans le PDF officiel colonne par colonne. Les noms français sont notre traduction. Séparés en plusieurs entrées : les armes, armures, boucliers et munitions +1 à +3, les potions de soins, les ceintures de force de géant et la baguette du mage de guerre ; les objets qui se posent sur une arme ou une armure (« Any Weapon », « Longsword ») sont des magies que le MJ ajoute à un objet du catalogue. Les bonus chiffrés (bonus magique, bonus de CA, caractéristique fixée) sont relevés dans le texte du SRD. **Les résumés sont à relire sur le PDF du SRD 5.2.1.** Ajoutés au même moment au catalogue des objets, d'après les tableaux du SRD 5.2.1 : les 23 armes, 8 armures et 4 munitions qui manquaient (dégâts, propriétés, maîtrise, poids, prix).

Les 154 créatures de facteur de puissance 3 à 30 (ajoutées le 27 novembre 2026) ont été relevées sur la même API, puis comparées au PDF du SRD 5.2.1 : l'introduction de leurs actions légendaires vient du PDF, et le loup-garou, le sanglier-garou, le tigre-garou, l'ours-garou et le vampire (plusieurs formes dans l'API, une seule créature dans le SRD) ont été recopiés du PDF. Corrigé là où l'API l'avait mal extrait : la ligne coupée de « Mind Jolt » du dragon de cuivre ancien (version de niveau 5). Le français est **notre traduction**, distances en mètres, noms de sorts de notre catalogue. **À relire sur le PDF du SRD 5.2.1.** Pour ne pas donner deux fois le même nom, le darkmantle (FP 1/2) s'appelle « Manteau noir » et le cloaker garde « Manteleur ».

**Mention d'attribution obligatoire**, recopiée de la page « Legal Information » du PDF, à reprendre telle quelle, en anglais :

> This work includes material from the System Reference Document 5.2.1 ("SRD 5.2.1") by Wizards of the Coast LLC, available at https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed under the Creative Commons Attribution 4.0 International License, available at https://creativecommons.org/licenses/by/4.0/legalcode.

Règles de la même page, à respecter :

- **Aucune autre mention** de Wizards of the Coast ou de ses filiales que celle-ci (« Please do not include any other attribution to Wizards… »)
- **Seules formules de compatibilité permises** : « compatible with fifth edition » ou « 5E compatible » (« Compatible 5e édition » dans la description du modèle). Pas de « 5.5 », ni d'autre nom d'édition
- Les marques ne sont pas couvertes par la licence (CC BY 4.0, section 2(b)(2)) : jamais « Dungeons & Dragons », « D&D », ni le nom d'un monde ou d'un personnage de Wizards. La licence ne permet pas non plus de laisser croire à un soutien de Wizards (section 2(a)(6))

Modifications (CC BY 4.0, section 3(a)(1)(B)) : sélection des règles et des entrées, traduction en français par l'équipe (jamais celle d'un livre publié), distances en mètres (1,50 mètre pour 5 pieds) et poids en kilos (0,5 kg pour une livre), données rangées par champs, descriptions courtes des objets et des options réécrites. Le texte anglais des sorts est celui du SRD, corrigé là où l'API l'avait mal extrait (paragraphes, tableaux aplatis ou incomplets, composantes glissées dans la portée, profils de créatures convoquées, virgules en trop dans des composantes matérielles).

## Horreur cosmique (`cosmic_horror.*.json`)

Ses quatre créatures (`db/seeds/catalogs/cosmic_horror_monsters.*.json`) sont écrites par l'équipe.

D'après le moteur Basic Roleplaying de Chaosium, sous licence ORC. Mention, telle que donnée par Chaosium sur https://www.chaosium.com/orclicense/ :

> This product is licensed under the ORC License held in the Library of Congress at TX 9-307-067 and available online at various locations including www.chaosium.com/orclicense, www.azoralaw.com/orclicense, www.gencon.com/orclicense and others. All warranties are disclaimed as set forth therein.
>
> This product is based on the following Licensed Material: "Basic Roleplaying: Universal Game Engine," copyright © 2024 Chaosium Inc., by Jason Durall and Steve Perrin.

Choix faits pour rester dans la licence :

- Les marques de Chaosium ne sont jamais utilisées
- La santé mentale est une simple ressource qui baisse face à l'horreur, sans crises ni folies graduées
- Les créatures (goule, profond, mi-go) viennent des récits de H. P. Lovecraft, dans le domaine public en Europe. Leurs valeurs et leurs descriptions sont les nôtres

À vérifier avant une mise en ligne publique : le texte complet de la licence ORC (https://www.chaosium.com/content/orclicense/ORC_License_FINAL.pdf) et l'usage du logo « Powered by BRP » demandé par Chaosium.
