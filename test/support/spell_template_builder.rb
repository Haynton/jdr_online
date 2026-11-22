# A small template with spells for the tests: a mage and a priest who cast spells (2 cantrips and 2 prepared spells
# at level 1, spells of level 2 from level 3), a warrior who casts none, and a catalog of a few spells
module SpellTemplateBuilder
  SPELLCASTING = { "cantrips" => [2, 2, 3], "prepared" => [2, 3, 4], "max_spell_level" => [1, 1, 2],
                   "prepared_changes" => "long_rest" }.freeze
  SPELLS = [
    ["fire-bolt", "Trait de feu", 0, %w[Mage]], ["light", "Lumière", 0, %w[Mage Prêtre]],
    ["mage-hand", "Main du mage", 0, %w[Mage]], ["magic-missile", "Projectile magique", 1, %w[Mage]],
    ["shield", "Bouclier", 1, %w[Mage]], ["bless", "Bénédiction", 1, %w[Prêtre]], ["blur", "Flou", 2, %w[Mage]]
  ].freeze

  module_function

  def create_template
    sheet_template = SheetTemplate.create!(name: "Fantasy", locale: "fr", character_fields: character_fields,
                                           spell_fields: spell_fields)
    SPELLS.each do |key, name, level, classes|
      sheet_template.catalog_entries.create!(kind: "spell", key: key, name: name, description: "Un sort.",
                                             properties: { "level" => level, "school" => "Évocation",
                                                           "classes" => classes })
    end
    sheet_template
  end

  def character_fields
    class_effects = { "Mage" => { "spellcasting" => SPELLCASTING }, "Prêtre" => { "spellcasting" => SPELLCASTING },
                      "Guerrier" => {} }
    steps = [{ "key" => "class", "label" => "Classe", "sections" => ["Classe"] },
             { "key" => "spells", "label" => "Sorts", "sections" => ["Sorts"], "only_with_effect" => "spellcasting",
               "chooses_spells" => true },
             { "key" => "description", "label" => "Description", "sections" => ["Notes"], "asks_name" => true }]
    fields = [
      { "key" => "class", "label" => "Classe", "type" => "choice", "section" => "Classe",
        "options" => %w[Mage Prêtre Guerrier], "effects" => class_effects },
      { "key" => "level", "label" => "Niveau", "type" => "number", "from_table" => "starting_level", "section" => "Notes" },
      { "key" => "notes", "label" => "Notes", "type" => "text", "section" => "Notes" }
    ]
    { "creation_steps" => steps, "fields" => fields }
  end

  def spell_fields
    { "fields" => [
      { "key" => "level", "type" => "number", "min" => 0, "max" => 9, "required" => true },
      { "key" => "school", "type" => "choice", "options" => ["Évocation"] },
      { "key" => "classes", "type" => "picks", "options" => %w[Mage Prêtre Guerrier], "required" => true }
    ] }
  end
end
