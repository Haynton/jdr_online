# A small template for the tests of the Equipment and Spells steps: a mage and a priest who cast spells (2 cantrips
# and 2 prepared spells at level 1, spells of level 2 from level 3), a warrior who casts none, their starting
# equipment (the mage: 2 daggers and a musical instrument of their choice and 5 gold, or 55 gold; the warrior: chain
# mail and 4 gold, or 60 gold), and a catalog of a few spells and items
module EquipmentSpellsTemplateBuilder
  # One number per level, from 1 to 20, as the validator of the template asks (SheetTemplateValidator)
  SPELLCASTING = { "ability" => "intelligence", "cantrips" => [2, 2, 3] + ([3] * 17),
                   "prepared" => [2, 3, 4] + ([4] * 17), "max_spell_level" => [1, 1, 2] + ([2] * 17),
                   "prepared_changes" => "long_rest" }.freeze
  SPELLS = [
    ["fire-bolt", "Trait de feu", 0, %w[Mage]], ["light", "Lumière", 0, %w[Mage Prêtre]],
    ["mage-hand", "Main du mage", 0, %w[Mage]], ["magic-missile", "Projectile magique", 1, %w[Mage]],
    ["shield", "Bouclier", 1, %w[Mage]], ["bless", "Bénédiction", 1, %w[Prêtre]], ["blur", "Flou", 2, %w[Mage]]
  ].freeze
  ITEMS = [
    ["dagger", "Dague", "Arme", nil], ["chain-mail", "Cotte de mailles", "Armure", nil],
    ["lute", "Luth", "Instrument de musique", "musical_instrument"],
    ["flute", "Flûte", "Instrument de musique", "musical_instrument"]
  ].freeze
  MAGE_EQUIPMENT = { "options" => [
    { "key" => "a", "items" => [{ "key" => "dagger", "count" => 2 }, { "choose" => ["musical_instrument"] }], "gold" => 5 },
    { "key" => "b", "gold" => 55 }
  ] }.freeze
  WARRIOR_EQUIPMENT = { "options" => [{ "key" => "a", "items" => [{ "key" => "chain-mail" }], "gold" => 4 },
                                      { "key" => "b", "gold" => 60 }] }.freeze

  module_function

  def create_template
    sheet_template = SheetTemplate.create!(name: "Fantasy", locale: "fr", character_fields: character_fields,
                                           spell_fields: spell_fields, item_fields: item_fields)
    SPELLS.each do |key, name, level, classes|
      sheet_template.catalog_entries.create!(kind: "spell", key: key, name: name, description: "Un sort.",
                                             properties: { "level" => level, "school" => "Évocation",
                                                           "classes" => classes })
    end
    ITEMS.each do |key, name, category, group|
      sheet_template.catalog_entries.create!(kind: "item", key: key, name: name,
                                             properties: { "category" => category, "group" => group }.compact)
    end
    sheet_template
  end

  def character_fields
    { "creation_steps" => creation_steps, "fields" => fields }
  end

  def creation_steps
    [{ "key" => "class", "label" => "Classe", "sections" => ["Classe"] },
     { "key" => "equipment", "label" => "Équipement", "sections" => ["Équipement"], "chooses_equipment" => true },
     { "key" => "spells", "label" => "Sorts", "sections" => [], "only_with_effect" => "spellcasting",
       "chooses_spells" => true },
     { "key" => "description", "label" => "Description", "sections" => ["Notes"], "asks_name" => true }]
  end

  def fields
    class_effects = { "Mage" => { "spellcasting" => SPELLCASTING, "starting_equipment" => MAGE_EQUIPMENT },
                      "Prêtre" => { "spellcasting" => SPELLCASTING }, "Guerrier" => { "starting_equipment" => WARRIOR_EQUIPMENT } }
    [{ "key" => "class", "label" => "Classe", "type" => "choice", "section" => "Classe",
       "options" => %w[Mage Prêtre Guerrier], "effects" => class_effects },
     { "key" => "class_equipment", "label" => "Équipement de la classe", "type" => "equipment_option", "from" => "class",
       "section" => "Équipement" },
     { "key" => "starting_gold", "internal" => true, "label" => "Or de départ", "type" => "computed",
       "rule" => "starting_gold", "section" => "Équipement" },
     { "key" => "gold", "label" => "Pièces d'or", "type" => "number", "min" => 0, "at_creation" => false,
       "initial_from" => "starting_gold", "section" => "Équipement" },
     # The ability of the spells, not asked at creation in this small template
     { "key" => "intelligence", "label" => "Intelligence", "type" => "ability", "modifier" => "half_above_ten",
       "at_creation" => false, "section" => "Notes" },
     { "key" => "level", "label" => "Niveau", "type" => "number", "from_table" => "starting_level", "section" => "Notes" },
     { "key" => "notes", "label" => "Notes", "type" => "text", "section" => "Notes" }]
  end

  def spell_fields
    { "fields" => [
      { "key" => "level", "type" => "number", "min" => 0, "max" => 9, "required" => true },
      { "key" => "school", "type" => "choice", "options" => ["Évocation"] },
      { "key" => "classes", "type" => "picks", "options" => %w[Mage Prêtre Guerrier], "required" => true }
    ] }
  end

  def item_fields
    { "fields" => [
      { "key" => "category", "type" => "choice", "options" => ["Arme", "Armure", "Instrument de musique"] },
      { "key" => "group", "type" => "choice", "options" => ["musical_instrument"] }
    ] }
  end
end
