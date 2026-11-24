# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# The account othna (test@test.com) sees every case known so far: tables as game master (draft at its first step,
# draft at its summary with pending invitations, ready with many players, ready and empty, made from a template of
# their own), tables as player (invitation to answer, character to make, character in progress, character complete,
# invitation to a draft that waits), and templates of their own (one used by a table, one that can be deleted).

# ==========================================
# Clean database before seeding
# ==========================================

# Delete existing records in dependency order
Participation.destroy_all
GameTable.destroy_all
SheetTemplate.destroy_all
User.destroy_all

# ==========================================
# Sheet templates
# ==========================================

# One JSON file per template and per language, then their catalogs (spells, items): the same loading as
# bin/rails sheet_templates:load, which fills the production database without emptying it.
# Sources and licenses: db/seeds/sheet_templates/LICENSES.md
SheetTemplates::PredefinedLoader.new.call

heroic_fantasy = SheetTemplate.find_by!(locale: "fr", name: "Fantasy héroïque")
cosmic_horror = SheetTemplate.find_by!(locale: "fr", name: "Horreur cosmique")

# ==========================================
# Users
# ==========================================

othna = User.create!(email: "test@test.com", password: "azertyuiopqsdfghjklm", username: "othna", locale: "fr")
luara = User.create!(email: "user@example.com", password: "password1234", username: "Luara", locale: "en")

# Other players, so that the tables show several avatars
brannoc, isolde, fennick, yrsa, oden = %w[Brannoc Isolde Fennick Yrsa Oden].map do |username|
  User.create!(email: "#{username.downcase}@example.com", password: "password1234", username: username, locale: "fr")
end

# ==========================================
# Templates of othna
# ==========================================

# Used by a table: its page lists that table, and it cannot be deleted
house_fantasy = SheetTemplates::Duplicator.new(original: heroic_fantasy, owner: othna).call
house_fantasy.update!(
  name: "Fantasy maison",
  description: "Nos règles maison : repos plus courts, potions plus rares et un peu plus d'or au départ.",
  icon: "castle",
  banner_color: "crimson"
)

# Used by no table, kept with its default name: it can be deleted. Copied in the language of othna, since the name of
# a copy is written in the language of the page ("(copie)"), and the seed runs in the default one
I18n.with_locale(othna.locale) do
  SheetTemplates::Duplicator.new(original: cosmic_horror, owner: othna).call
end

# ==========================================
# Helpers
# ==========================================

# A table with its game master, playing with its own copy of the template
def create_game_table(game_master:, sheet_template:, ready: true, **attributes)
  game_table = GameTable.new(attributes)
  game_table.use_sheet_template(sheet_template)
  game_table.save!
  game_table.participations.create!(user: game_master, role: "game_master")
  game_table.finish_creation! if ready
  game_table
end

def invite_player(game_table, user)
  game_table.participations.create!(user: user, role: "player", status: "pending")
end

def add_player(game_table, user)
  game_table.participations.create!(user: user, role: "player")
end

# The first choices of a fantasy character, with the effects of its options (saving throws, skills, speed)
def fantasy_sheet(game_table, class_name:, background:, species:, size: "Moyenne")
  chosen_values = { "class" => class_name, "background" => background, "species" => species, "size" => size }
  CharacterSheets::ChoiceEffectsApplier.new(fields: game_table.character_sheet_fields, previous_sheet: {})
                                       .call(game_table.character_values_from_table.merge(chosen_values))
end

ABILITY_SCORES = {
  "strength" => 10, "dexterity" => 14, "constitution" => 13,
  "intelligence" => 12, "wisdom" => 15, "charisma" => 8
}.freeze

# A player who finished their character: "Join the game". A spellcaster takes the spells given, copied as the step
# Spells copies them
def add_player_with_character(game_table, user, name:, spell_keys: [], **choices)
  participation = add_player(game_table, user)
  character = participation.build_character(game_table: game_table, name: name, status: "draft",
                                            sheet: fantasy_sheet(game_table, **choices).merge(ABILITY_SCORES))
  character.choose_spells(spell_keys)
  character.complete_creation
  character.save!
end

# A spell of the template changed for the table (its copy, same key), as the step "Spells and items" saves it
def customize_spell(game_table, key, **changed_properties)
  original = game_table.sheet_template.catalog_entries.find_by!(kind: "spell", key: key)
  game_table.catalog_entries.create!(kind: "spell", key: key, name: original.name, description: original.description,
                                     properties: original.properties.merge(changed_properties.stringify_keys))
end

# A player who stopped on a step of their character: "Resume my character"
def add_player_with_draft_character(game_table, user, name:, creation_step:, **choices)
  participation = add_player(game_table, user)
  participation.create_character!(game_table: game_table, name: name, status: "draft", creation_step: creation_step,
                                  sheet: fantasy_sheet(game_table, **choices))
end

# ==========================================
# Tables of othna, as game master
# ==========================================

# Draft stopped at its first step: "Resume the creation"
create_game_table(
  game_master: othna, sheet_template: heroic_fantasy, ready: false, creation_step: 1,
  name: "Les Royaumes Oubliés", cover_image: "citadelle",
  description: "Un monde ancien où les royaumes humains tentent de survivre face aux créatures des ténèbres. " \
               "D'anciennes ruines renferment des secrets capables de bouleverser l'équilibre du monde."
)

# Draft at its summary, with two players invited by their username who wait for the end of the creation
dragon_shadow = create_game_table(
  game_master: othna, sheet_template: heroic_fantasy, ready: false, creation_step: GameTable::CREATION_STEPS.size,
  name: "L'Ombre du Dragon", cover_image: "dragon",
  description: "Depuis le réveil d'un dragon ancestral, les terres sont plongées dans le chaos. Les villages " \
               "brûlent, les armées se préparent et une ancienne prophétie annonce le retour d'un héros oublié."
)
invite_player(dragon_shadow, brannoc)
invite_player(dragon_shadow, isolde)

# Ready, starting at level 3, with four players and a fifth one invited: a row of avatars
valdoria = create_game_table(
  game_master: othna, sheet_template: heroic_fantasy, starting_level: 3,
  name: "Les Terres de Valdoria", cover_image: "village",
  description: "Un vaste continent composé de royaumes rivaux, de forêts enchantées et de montagnes mystérieuses. " \
               "Les aventuriers devront naviguer entre intrigues politiques, magie ancienne et dangers oubliés."
)
add_player_with_character(valdoria, luara, name: "Elowen", class_name: "Druide", background: "Sage", species: "Elfe",
                                           spell_keys: %w[guidance druidcraft goodberry speak-with-animals])
add_player_with_character(valdoria, brannoc, name: "Grom", class_name: "Barbare", background: "Soldat",
                                             species: "Goliath")
add_player_with_character(valdoria, isolde, name: "Mirelle", class_name: "Clerc", background: "Acolyte",
                                            species: "Humain", spell_keys: %w[guidance sacred-flame light bless])
add_player_with_character(valdoria, fennick, name: "Pip", class_name: "Barde", background: "Criminel",
                                             species: "Halfelin", size: "Petite")
invite_player(valdoria, yrsa)
# Changed after Elowen and Mirelle chose it: the step "Spells and items" offers to apply it to their sheets
customize_spell(valdoria, "guidance", range: "9 mètres")

# Ready, nobody has joined yet
create_game_table(
  game_master: othna, sheet_template: heroic_fantasy,
  name: "Le Crépuscule des Elfes", cover_image: "wolf",
  description: "Les derniers royaumes elfiques disparaissent peu à peu sous l'influence d'une magie corrompue. " \
               "Au cœur des forêts millénaires, une force inconnue menace de dévorer toute forme de vie."
)

# Made from the template of othna, with one player done and one still making their character
ashes_crown = create_game_table(
  game_master: othna, sheet_template: house_fantasy,
  name: "La Couronne des Cendres", cover_image: "sentinelle",
  description: "Après la chute d'un empire puissant, plusieurs seigneurs se disputent les vestiges du trône. " \
               "Mercenaires, chevaliers et sorciers cherchent à imposer leur propre vision du futur."
)
add_player_with_character(ashes_crown, yrsa, name: "Sigrun", class_name: "Guerrier", background: "Soldat",
                                             species: "Nain")
add_player_with_draft_character(ashes_crown, oden, name: "Corvin", creation_step: "abilities",
                                                   class_name: "Magicien", background: "Sage", species: "Humain")

# ==========================================
# Tables of othna, as player
# ==========================================

# Invitation to a ready table, not answered yet: "Accept" or "Decline"
aetheria = create_game_table(
  game_master: luara, sheet_template: heroic_fantasy,
  name: "Les Chroniques d'Aetheria", cover_image: "citadelle",
  description: "Un monde où la magie imprègne chaque pierre et chaque être vivant. Des cités flottantes aux temples " \
               "oubliés, les aventuriers découvriront les traces d'une civilisation disparue."
)
add_player_with_character(aetheria, fennick, name: "Lorin", class_name: "Ensorceleur", background: "Sage",
                                             species: "Tieffelin")
invite_player(aetheria, othna)

# Joined, no character yet, on a template without steps (a single page): "Create my character"
moor_whispers = create_game_table(
  game_master: fennick, sheet_template: cosmic_horror,
  name: "Les Murmures de la Lande", cover_image: "lovecraft",
  description: "Une lettre d'un oncle disparu mène les enquêteurs dans un village de pêcheurs où personne ne parle " \
               "des lumières qui dansent la nuit sur la lande."
)
add_player(moor_whispers, othna)

# Character stopped at its abilities: "Resume my character"
drakemoor = create_game_table(
  game_master: luara, sheet_template: heroic_fantasy,
  name: "Les Légendes de Drakemoor", cover_image: "dragon",
  description: "Dans les terres sauvages de Drakemoor, les dragons sont considérés comme des dieux vivants. " \
               "Les clans humains, nains et orcs doivent s'unir face à une menace venue des profondeurs."
)
add_player_with_draft_character(drakemoor, othna, name: "Sylas", creation_step: "abilities",
                                                  class_name: "Rôdeur", background: "Criminel", species: "Elfe")
add_player_with_character(drakemoor, brannoc, name: "Durgan", class_name: "Paladin", background: "Acolyte",
                                              species: "Nain")

# Character complete, among four other players: "Join the game"
north_marches = create_game_table(
  game_master: isolde, sheet_template: heroic_fantasy,
  name: "Les Marches du Nord", cover_image: "wolf",
  description: "Aux frontières du monde connu, de petites forteresses protègent les dernières terres civilisées. " \
               "Au-delà des montagnes glacées, des tribus barbares et des monstres légendaires se rassemblent."
)
add_player_with_character(north_marches, othna, name: "Kaelen", class_name: "Moine", background: "Acolyte",
                                                species: "Humain")
add_player_with_character(north_marches, luara, name: "Aria", class_name: "Occultiste", background: "Criminel",
                                                species: "Tieffelin")
add_player_with_character(north_marches, brannoc, name: "Thrain", class_name: "Guerrier", background: "Soldat",
                                                  species: "Nain")
add_player_with_character(north_marches, yrsa, name: "Freya", class_name: "Rôdeur", background: "Soldat",
                                               species: "Orc")
add_player_with_character(north_marches, oden, name: "Nim", class_name: "Magicien", background: "Sage",
                                               species: "Gnome", size: "Petite")

# Invitation to a draft: it waits until Luara finishes the creation, nothing shows in "My tables" of othna
void_awakening = create_game_table(
  game_master: luara, sheet_template: heroic_fantasy, ready: false, creation_step: 1,
  name: "L'Éveil du Néant", cover_image: "gobelins",
  description: "Une mystérieuse énergie noire commence à corrompre les terres et à transformer les êtres vivants. " \
               "Les anciens grimoires évoquent une entité bannie depuis des millénaires qui chercherait à revenir."
)
invite_player(void_awakening, othna)

# ==========================================
# Seeds completed
# ==========================================

puts "Seeds completed:"
puts "- #{SheetTemplate.count} sheet templates created"
puts "- #{User.count} users created"
puts "- #{GameTable.count} game tables created"
puts "- #{Participation.count} participations created"
puts "- #{Character.count} characters created"
