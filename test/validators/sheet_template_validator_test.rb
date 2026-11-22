require "test_helper"

# A small template that follows every rule, then one change per test that breaks one of them
class SheetTemplateValidatorTest < ActiveSupport::TestCase
  DEFAULT_STEPS = [
    { "key" => "identity", "label" => "Personnage", "sections" => ["Identité"], "asks_name" => true },
    { "key" => "abilities", "label" => "Caractéristiques", "sections" => %w[Caractéristiques Combat] }
  ].freeze

  test "a template that follows the rules is valid" do
    assert_predicate build_template, :valid?
  end

  test "a template without fields is valid" do
    assert_predicate SheetTemplate.new(name: "Vide", locale: "fr"), :valid?
  end

  test "a key used twice is refused" do
    template = build_template { |fields| fields << { "key" => "strength", "label" => "Force bis", "type" => "text" } }

    assert_error template, :duplicate_key, "Fiche du personnage\u00A0: la clé « strength » est utilisée par deux champs"
  end

  test "a type the registry does not know is refused" do
    template = build_template { |fields| fields << { "key" => "luck", "label" => "Chance", "type" => "luck" } }

    assert_error template, :unknown_type
  end

  test "a setting the type does not declare is refused, a typo too" do
    template = build_template { |fields| field(fields, "level")["maxx"] = 20 }

    assert_error template, :unknown_parameter
  end

  test "a setting the type needs is asked" do
    template = build_template { |fields| field(fields, "class").delete("options") }

    assert_error template, :missing_parameter
  end

  test "a setting that names a field names one of the right type" do
    template = build_template { |fields| field(fields, "athletics")["based_on"] = "level" }

    assert_error template, :wrong_reference
  end

  test "an unknown rule or modifier is refused" do
    template = build_template do |fields|
      field(fields, "proficiency_bonus")["rule"] = "luck"
      field(fields, "strength")["modifier"] = "double"
    end

    assert_error template, :unknown_rule
    assert_error template, :unknown_modifier
  end

  test "every class gives its hit die to the rules that read it" do
    template = build_template { |fields| field(fields, "class")["effects"]["Guerrier"].delete("hit_die") }

    assert_error template, :missing_hit_die
  end

  test "descriptions and effects are given for options of the list" do
    template = build_template { |fields| field(fields, "class")["descriptions"] = { "Barde" => "Musicien" } }

    assert_error template, :unknown_option
  end

  test "a single field receives the damage" do
    template = build_template do |fields|
      fields << { "key" => "shield", "label" => "Bouclier", "type" => "resource", "receives_damage" => true,
                  "section" => "Combat" }
    end

    assert_error template, :several_damage_fields
  end

  test "an unknown effect is refused" do
    template = build_template { |fields| class_effects(fields)["flight"] = true }

    assert_error template, :unknown_effect
  end

  test "an effect names fields of the right type, and fields that exist" do
    template = build_template do |fields|
      class_effects(fields)["proficient"] = ["strength"]
      class_effects(fields)["set"] = { "wings" => 2 }
    end

    assert_error template, :wrong_effect_target
    assert_error template, :unknown_effect_target
  end

  test "a spellcasting gives a number per level and a known change of spells" do
    template = build_template do |fields|
      spellcasting = class_effects(fields)["spellcasting"]
      spellcasting["cantrips"] = [2, 2, 3]
      spellcasting["prepared_changes"] = "every_morning"
    end

    assert_error template, :invalid_level_table
    assert_error template, :unknown_effect_value
  end

  test "the starting equipment has one letter per option, each line an item or a known group" do
    template = build_template do |fields|
      class_effects(fields)["starting_equipment"]["options"] = [
        { "key" => "a", "items" => [{ "key" => "dagger", "choose" => ["weapon"] }] },
        { "key" => "a", "items" => [{ "choose" => ["vehicle"] }] }
      ]
    end

    assert_error template, :duplicate_equipment_option
    assert_error template, :invalid_equipment_line
    assert_error template, :unknown_item_group
  end

  test "a step names sections that exist, known settings and a known effect" do
    template = build_template(steps: [
                                { "key" => "identity", "label" => "Personnage", "sections" => %w[Identité Combats],
                                  "asks_name" => true, "only_with_effect" => "flight", "color" => "red" },
                                { "key" => "identity", "label" => "Encore", "sections" => %w[Caractéristiques Combat] }
                              ])

    assert_error template, :unknown_section, "L'étape « Personnage » cite une section qui n'existe pas\u00A0: Combats"
    assert_error template, :unknown_step_parameter
    assert_error template, :unknown_step_effect
    assert_error template, :duplicate_step
  end

  test "every field asked at creation is in a step, and one step asks the name" do
    template = build_template(steps: [{ "key" => "identity", "label" => "Personnage", "sections" => ["Identité"] }])

    assert_error template, :field_without_step
    assert_error template, :name_step_count
  end

  test "the ready-made items only fill fields of the item sheet" do
    template = build_template
    template.preset_items = [{ "name" => "Dague", "properties" => { "sharpness" => 3 } }]

    assert_error template, :unknown_item_property
  end

  # The labels are the words of the template, only the rest of the message follows the page
  test "the messages are in the language of the page" do
    template = build_template { |fields| field(fields, "proficiency_bonus")["rule"] = "luck" }

    I18n.with_locale(:en) do
      template.validate
      assert_includes template.errors.full_messages,
                      "Character sheet › Bonus de maîtrise: the computing rule “luck” is unknown"
    end
  end

  private

  # The template given to the block (its character fields) can be changed before it is built
  def build_template(steps: DEFAULT_STEPS)
    fields = character_fields
    yield fields if block_given?
    SheetTemplate.new(
      name: "Petit jeu", locale: "fr",
      character_fields: { "fields" => fields, "creation_steps" => steps.map(&:dup) },
      item_fields: { "fields" => [{ "key" => "group", "label" => "Groupe", "type" => "choice",
                                    "options" => ["weapon"] }] }
    )
  end

  def character_fields
    [
      { "key" => "class", "label" => "Classe", "type" => "choice", "section" => "Identité", "options" => ["Guerrier"],
        "effects" => { "Guerrier" => guerrier_effects } },
      { "key" => "strength", "label" => "Force", "type" => "ability", "modifier" => "half_above_ten",
        "section" => "Caractéristiques" },
      { "key" => "level", "label" => "Niveau", "type" => "number", "min" => 1, "max" => 20,
        "from_table" => "starting_level", "section" => "Combat" },
      { "key" => "proficiency_bonus", "label" => "Bonus de maîtrise", "type" => "computed",
        "rule" => "proficiency_by_level", "level_from" => "level", "section" => "Combat" },
      { "key" => "hit_dice", "label" => "Dés de vie", "type" => "computed", "rule" => "hit_dice_by_class",
        "level_from" => "level", "class_from" => "class", "section" => "Combat" },
      { "key" => "athletics", "label" => "Athlétisme", "type" => "bonus", "based_on" => "strength",
        "proficiency" => "proficiency_bonus", "section" => "Caractéristiques" },
      { "key" => "hp", "label" => "Points de vie", "type" => "resource", "receives_damage" => true,
        "section" => "Combat" }
    ]
  end

  def guerrier_effects
    { "hit_die" => 10, "proficient" => ["athletics"],
      "spellcasting" => { "ability" => "strength", "cantrips" => [0] * 20, "prepared" => [0] * 20,
                          "max_spell_level" => [0] * 20, "prepared_changes" => "long_rest" },
      "starting_equipment" => { "options" => [{ "key" => "a", "items" => [{ "choose" => ["weapon"] }] },
                                              { "key" => "b", "gold" => 50 }] } }
  end

  def field(fields, key)
    fields.find { |candidate| candidate["key"] == key }
  end

  def class_effects(fields)
    field(fields, "class")["effects"]["Guerrier"]
  end

  # The error is there, under its type; and its message in French, when one is given
  def assert_error(template, error_type, message = nil)
    I18n.with_locale(:fr) do
      template.validate
      assert template.errors.of_kind?(:base, error_type), "#{error_type} expected, got #{template.errors.details}"
      assert_includes template.errors.full_messages, message if message
    end
  end
end
