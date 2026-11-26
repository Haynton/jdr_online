# A small template with weapon masteries and fighting styles, shared by the tests of the masteries: a fighter, a
# barbarian (melee only), a wizard (none), three weapons of the catalog of the table
module WeaponMasteryTemplate
  ITEM_FIELDS = [
    { "key" => "training", "label" => "Maîtrise", "type" => "choice", "options" => %w[simple-weapons martial-weapons] },
    { "key" => "damage_dice", "label" => "Dés", "type" => "text" },
    { "key" => "ranged", "label" => "À distance", "type" => "boolean" },
    { "key" => "weapon_kind", "label" => "Sorte", "type" => "choice", "options" => %w[longswords longbows daggers],
      "labels" => ["Épées longues", "Arcs longs", "Dagues"] },
    { "key" => "mastery", "label" => "Propriété", "type" => "choice", "options" => %w[sap slow nick],
      "labels" => %w[Sape Ralentissement Double], "descriptions" => { "sap" => "Désavantage.", "slow" => "-3 m.",
                                                                      "nick" => "Une de plus." } }
  ].freeze
  STYLES = [{ "key" => "archery", "label" => "Archerie", "help" => "+2 à distance.",
              "effects" => { "ranged_attack_bonus" => 2 } },
            { "key" => "defense", "label" => "Défense", "help" => "+1 CA." }].freeze
  CLASS_EFFECTS = {
    "Guerrier" => { "training" => %w[simple-weapons martial-weapons], "weapon_mastery" => { "counts" => [2] * 20 },
                    "fighting_style" => { "level" => 1, "options" => %w[archery defense] } },
    "Barbare" => { "training" => %w[simple-weapons martial-weapons],
                   "weapon_mastery" => { "counts" => [1] * 20, "melee_only" => true } },
    "Magicien" => { "training" => %w[simple-weapons] }
  }.freeze
  FIELDS = [
    { "key" => "class", "label" => "Classe", "type" => "choice", "options" => CLASS_EFFECTS.keys, "effects" => CLASS_EFFECTS },
    { "key" => "level", "label" => "Niveau", "type" => "number", "from_table" => "starting_level" },
    { "key" => "strength", "label" => "Force", "type" => "ability", "modifier" => "half_above_ten" },
    { "key" => "dexterity", "label" => "Dextérité", "type" => "ability", "modifier" => "half_above_ten" }
  ].freeze
  WEAPONS = {
    "longsword" => { "training" => "martial-weapons", "damage_dice" => "1d8", "weapon_kind" => "longswords", "mastery" => "sap" },
    "longbow" => { "training" => "martial-weapons", "damage_dice" => "1d8", "weapon_kind" => "longbows", "mastery" => "slow",
                   "ranged" => true },
    "dagger" => { "training" => "simple-weapons", "damage_dice" => "1d4", "weapon_kind" => "daggers", "mastery" => "nick" }
  }.freeze

  def self.snapshot
    { "character_fields" => { "fields" => FIELDS, "fighting_styles" => STYLES,
                              "weapon_attacks" => { "melee_ability" => "strength", "ranged_ability" => "dexterity",
                                                    "training_from" => "class" } },
      "item_fields" => { "fields" => ITEM_FIELDS } }
  end

  def self.add_weapons(game_table)
    WEAPONS.each do |key, properties|
      game_table.catalog_entries.create!(kind: "item", key: key, name: key.capitalize, properties: properties)
    end
  end
end
