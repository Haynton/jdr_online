require "test_helper"

# A small template that follows every rule, then one change per test that breaks one of them
class SheetTemplateValidatorTest < ActiveSupport::TestCase
  DEFAULT_STEPS = [
    { "key" => "identity", "label" => "Personnage", "sections" => ["Identité"], "asks_name" => true },
    { "key" => "abilities", "label" => "Caractéristiques", "sections" => %w[Caractéristiques Combat] }
  ].freeze
  DICE_ROLLS = {
    "modes" => [{ "key" => "advantage", "label" => "Avantage", "help" => "Deux d20, le meilleur.", "dice" => 2,
                  "keep" => "highest" }],
    "initiative" => { "label" => "Initiative", "sides" => 20, "modifier_from" => "proficiency_bonus",
                      "npc_modifier_from" => "dexterity" }
  }.freeze

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

  test "a key is in snake_case: lower case letters, digits and _, a letter first" do
    ["Points de vie", "1st_level", "vitalité", "hp<script>", ""].each do |key|
      template = build_template { |fields| field(fields, "level")["key"] = key }

      assert_error template, :invalid_key
    end
  end

  test "a label is filled in, on one line, and not too long; any other text is fine" do
    ["", "   ", "Points\nde vie", "Points\tde vie", "x" * 61].each do |label|
      template = build_template { |fields| field(fields, "level")["label"] = label }

      assert_error template, :invalid_label
    end
    template = build_template { |fields| field(fields, "level")["label"] = "Niveau <b>d'âme</b> & « esprit »" }
    assert_predicate template, :valid?
  end

  test "a step has a key in snake_case and a label" do
    steps = DEFAULT_STEPS.map(&:dup)
    steps.first["key"] = "Personnage"
    steps.last.delete("label")
    template = build_template(steps: steps)

    assert_error template, :invalid_step_key
    assert_error template, :invalid_step_label
  end

  test "a step may say what it is for in a sentence of one line, 200 characters at most" do
    [[nil, true], ["Donnez-lui un nom.", true], ["Une ligne\npuis une autre", false], ["a" * 201, false],
     ["  ", false]].each do |intro, valid|
      steps = DEFAULT_STEPS.map(&:dup)
      steps.first["intro"] = intro unless intro.nil?
      template = build_template(steps: steps)

      if valid
        assert_predicate template, :valid?, intro.inspect
      else
        assert_error template, :invalid_step_intro
      end
    end
  end

  test "a list draws its options as cards with an icon of the app for each of its options" do
    assert_predicate build_template { |fields| field(fields, "class")["icons"] = { "Guerrier" => "swords" } }, :valid?
    assert_error build_template { |fields| field(fields, "class")["icons"] = { "Guerrier" => "dragon" } },
                 :unknown_icon
    assert_error build_template { |fields| field(fields, "class")["icons"] = { "Mage" => "swords" } },
                 :unknown_option
  end

  test "each setting holds a value of its kind, of its list, and a minimum under its maximum" do
    template = build_template do |fields|
      field(fields, "level")["max"] = "vingt"
      field(fields, "level")["min"] = 25
      field(fields, "hp")["on_rest"] = "sleep"
    end

    assert_error template, :invalid_parameter_value,
                 "Fiche du personnage › Niveau\u00A0: le réglage «\u00A0max\u00A0» doit être un nombre entier"
    assert_error template, :unknown_parameter_value
    template = build_template do |fields|
      field(fields, "level")["min"] = 25
    end
    assert_error template, :min_above_max
  end

  test "a type the registry does not know is refused" do
    template = build_template { |fields| fields << { "key" => "luck", "label" => "Chance", "type" => "luck" } }

    assert_error template, :unknown_type
  end

  test "a setting the type does not declare is refused, a typo too" do
    template = build_template { |fields| field(fields, "level")["maxx"] = 20 }

    assert_error template, :unknown_parameter
  end

  test "the weapon attacks name an ability, the proficiency bonus and the list of the class of the character sheet" do
    attacks = { "melee_ability" => "strength", "ranged_ability" => "strength", "proficiency" => "proficiency_bonus",
                "training_from" => "class", "two_handed_label" => "à deux mains" }
    assert_predicate template_with_weapon_attacks(attacks), :valid?

    assert_error template_with_weapon_attacks(attacks.merge("ranged_ability" => "class")), :invalid_weapon_attacks_field
    assert_error template_with_weapon_attacks(attacks.merge("reach" => 2)), :unknown_weapon_attacks_parameter
    assert_error template_with_weapon_attacks(attacks.except("melee_ability")), :missing_weapon_attacks_parameter
    assert_error template_with_weapon_attacks(attacks.merge("two_handed_label" => "")), :invalid_weapon_attacks_label
  end

  test "a list with labels gives a name to each of its options" do
    named_list = { "key" => "rank", "label" => "Rang", "type" => "choice", "options" => %w[low high],
                   "labels" => %w[Bas Haut], "section" => "Identité" }
    assert_predicate build_template { |fields| fields << named_list }, :valid?

    assert_error build_template { |fields| fields << named_list.merge("labels" => ["Bas"]) },
                 :labels_not_matching_options
  end

  test "a field shown only with some values names a list of the same part, and some of its options" do
    shown_with = { "field" => "class", "values" => ["Guerrier"] }
    field = { "key" => "rage", "label" => "Rage", "type" => "text", "section" => "Identité",
              "shown_with" => shown_with }
    assert_predicate build_template { |fields| fields << field }, :valid?

    [{ "field" => "level", "values" => ["Guerrier"] }, { "field" => "class", "values" => ["Mage"] },
     { "field" => "class", "values" => [] }, { "field" => "class" }, "class"].each do |wrong|
      assert_error build_template { |fields| fields << field.merge("shown_with" => wrong) }, :invalid_shown_with
    end
  end

  test "a list that depends on another names its options, for options of that list" do
    template = build_template { |fields| fields << subclass_field }
    assert_predicate template, :valid?

    template = build_template do |fields|
      fields << subclass_field.merge("options_by" => { "Barde" => ["Champion"], "Guerrier" => ["Voleur"] })
    end
    assert_error template, :unknown_parent_option,
                 "Fiche du personnage › Sous-classe\u00A0: «\u00A0options_by\u00A0» cite une option qui n'existe pas " \
                 "dans «\u00A0Classe\u00A0» (Barde)"
    assert_error template, :unknown_option
  end

  test "the settings of a list that depends on another go together, and name fields of the right type" do
    assert_error build_template { |fields| fields << subclass_field.except("options_from") }, :missing_parameter
    assert_error build_template { |fields| fields << subclass_field.except("level_from") }, :missing_parameter
    assert_error build_template { |fields| fields << subclass_field.merge("options_from" => "strength") },
                 :wrong_reference
  end

  test "a subclass may give hit points per level, always prepared spells and named features" do
    effects = { "hit_points_per_level" => 1, "always_prepared_spells" => { "3" => ["bless"] },
                "features_by_level" => { "3" => [{ "key" => "improved-critical", "name" => "Critique amélioré" }] } }
    template = build_template { |fields| fields << subclass_field.merge("effects" => { "Champion" => effects }) }
    assert_predicate template, :valid?

    effects = { "always_prepared_spells" => { "30" => ["bless"] }, "hit_points_per_level" => "un" }
    template = build_template { |fields| fields << subclass_field.merge("effects" => { "Champion" => effects }) }
    assert_error template, :invalid_level_entries
    assert_error template, :unknown_effect_value
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

  test "a computing rule gets the settings it reads" do
    template = build_template { |fields| field(fields, "hit_dice").delete("class_from") }

    assert_error template, :missing_parameter,
                 "Fiche du personnage › Dés de vie\u00A0: le réglage « class_from » est obligatoire"
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

  test "the unarmored defense names an ability" do
    template = build_template { |fields| class_effects(fields)["unarmored_defense"] = "athletics" }

    assert_error template, :wrong_effect_target
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

  test "a group of spells has a key in snake_case, a label, its count, its levels and known settings" do
    groups = [
      { "key" => "Mineurs", "label" => "", "min_level" => 0, "color" => "red", "changes" => "every_morning" },
      { "key" => "Mineurs", "label" => "Encore", "min_level" => 0, "max_level" => 0, "count_from" => "cantrips" }
    ]
    template = build_template(spell_groups: groups)

    assert_error template, :invalid_spell_group_key
    assert_error template, :invalid_spell_group_label
    assert_error template, :unknown_spell_group_parameter
    assert_error template, :missing_spell_group_parameter
    assert_error template, :unknown_spell_group_changes
    assert_error template, :duplicate_spell_group
  end

  test "every class that casts spells has the tables its groups read" do
    template = build_template { |fields| class_effects(fields)["spellcasting"].delete("max_spell_level") }

    assert_error template, :missing_spell_table,
                 "Fiche du personnage › Classe › Guerrier\u00A0: la table «\u00A0max_spell_level\u00A0» des sorts " \
                 "manque, le groupe «\u00A0Sorts préparés\u00A0» la lit"
  end

  test "a spell slot table gives a list of whole numbers for each of the 20 levels" do
    template = build_template { |fields| class_effects(fields)["spellcasting"]["slots"] = [[2], [3, -1]] }

    assert_error template, :invalid_slot_table
  end

  test "the spell slots have a label, their table and known settings" do
    template = build_template(spell_slots: { "label" => "", "color" => "red" })

    assert_error template, :invalid_spell_slots_label
    assert_error template, :unknown_spell_slots_parameter
    assert_error template, :missing_spell_slots_parameter
  end

  test "every class that casts spells has the slot table, and a label of one line of its own" do
    template = build_template do |fields|
      spellcasting = class_effects(fields)["spellcasting"]
      spellcasting.delete("slots")
      spellcasting["slots_label"] = "Faveurs\ndu dieu"
    end

    assert_error template, :missing_slot_table,
                 "Fiche du personnage › Classe › Guerrier\u00A0: la table «\u00A0slots\u00A0» des emplacements " \
                 "de sorts manque"
    assert_error template, :invalid_class_slots_label
  end

  test "a template without spell slots needs no slot table" do
    template = build_template(spell_slots: nil) { |fields| class_effects(fields)["spellcasting"].delete("slots") }

    assert_predicate template, :valid?
  end

  test "a template without groups of spells needs no spell table" do
    assert_predicate build_template(spell_groups: []), :valid?
  end

  test "the conditions have a unique key, a label, a short text and a number of levels, nothing else" do
    template = with_conditions([
                                 { "key" => "poisoned", "label" => "Empoisonné", "description" => "Désavantage." },
                                 { "key" => "poisoned", "label" => "Empoisonné bis" },
                                 { "key" => "À terre", "label" => "À terre" },
                                 { "key" => "dazed", "label" => "", "color" => "green" },
                                 { "key" => "tired", "label" => "Fatigué", "levels" => 1, "description" => "x" * 501 }
                               ])

    assert_error template, :duplicate_condition, "L'état « poisoned » est déclaré deux fois"
    assert_error template, :invalid_condition_key
    assert_error template, :invalid_condition_label
    assert_error template, :unknown_condition_parameter
    assert_error template, :invalid_condition_levels,
                 "L'état « Fatigué » : le nombre de niveaux doit être un nombre entier de 2 à 20"
    assert_error template, :invalid_condition_description
  end

  test "the conditions are a list of conditions; a template may have none" do
    assert_error with_conditions({ "poisoned" => "Empoisonné" }), :invalid_conditions
    assert_predicate with_conditions([{ "key" => "exhaustion", "label" => "Épuisement", "levels" => 6 }]), :valid?
    assert_predicate build_template, :valid?
  end

  test "the price lists have a unique key, a label and lines with a label, a price and a short note" do
    inn = { "key" => "inn", "label" => "Auberge", "lines" => [{ "label" => "Modeste", "price" => "5 pa" }] }
    assert_predicate with_price_lists([inn]), :valid?

    template = with_price_lists([inn, inn.merge("label" => "Auberge bis"),
                                 { "key" => "Repas", "label" => "Repas", "lines" => [], "color" => "green" },
                                 { "key" => "meals", "label" => "Repas", "lines" => [{ "label" => "Riche" }] }])
    assert_error template, :duplicate_price_list
    assert_error template, :invalid_price_list_key
    assert_error template, :unknown_price_list_parameter
    assert_error template, :invalid_price_lines, "La liste de prix « Repas » : il faut des lignes, chacune avec un " \
                                                 "libellé, un prix et, au besoin, une note courte"
    assert_error with_price_lists({ "inn" => "5 pa" }), :invalid_price_lists
  end

  test "the dice declare their modes, the die they apply to and their initiative" do
    assert_predicate with_dice_rolls(DICE_ROLLS), :valid?
    assert_predicate with_dice_rolls({ "initiative" => { "label" => "Initiative", "sides" => 20 } }), :valid?
  end

  test "a dice mode has a key, a label, a short help, 2 to 5 dice and keeps the highest or the lowest" do
    modes = [
      { "key" => "advantage", "label" => "Avantage", "dice" => 2, "keep" => "highest" },
      { "key" => "advantage", "label" => "Encore", "dice" => 2, "keep" => "highest" },
      { "key" => "Lucky", "label" => "", "help" => "x" * 201, "dice" => 1, "keep" => "best", "bonus" => 1 }
    ]
    template = with_dice_rolls(DICE_ROLLS.merge("modes" => modes))

    assert_error template, :duplicate_dice_roll_mode, "Le mode de dés « advantage » est déclaré deux fois"
    assert_error template, :invalid_dice_roll_mode_key
    assert_error template, :invalid_dice_roll_mode_label
    assert_error template, :invalid_dice_roll_mode_help
    assert_error template, :unknown_dice_roll_mode_parameter
    assert_error template, :invalid_dice_roll_mode,
                 "Le mode de dés « Lucky » : il lance de 2 à 5 dés et garde le meilleur (highest) ou le pire (lowest)"
  end

  test "the initiative rolls a die the roller knows" do
    template = with_dice_rolls(DICE_ROLLS.merge("initiative" => DICE_ROLLS["initiative"].merge("sides" => "d20")))

    assert_error template, :invalid_initiative_sides
  end

  test "the initiative adds a field that gives a number, on the sheet and on the sheet of an NPC" do
    template = with_dice_rolls(DICE_ROLLS.merge("initiative" => DICE_ROLLS["initiative"].merge(
      "modifier_from" => "hp", "npc_modifier_from" => "speed", "dice" => 1
    )))

    assert_error template, :invalid_initiative_field,
                 "L'initiative : Fiche du personnage n'a pas de champ « hp » qui donne un nombre " \
                 "(nombre, valeur calculée ou caractéristique)"
    assert_error template, :unknown_initiative_parameter
  end

  test "the dice refuse an unknown setting and a value of the wrong shape" do
    assert_error with_dice_rolls(DICE_ROLLS.merge("critical" => 20)), :unknown_dice_rolls_parameter
    assert_error with_dice_rolls([]), :invalid_dice_rolls
    assert_error with_dice_rolls(DICE_ROLLS.merge("modes" => "advantage")), :invalid_dice_roll_modes
    assert_error with_dice_rolls(DICE_ROLLS.merge("initiative" => "d20")), :invalid_initiative_roll
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

  test "the ways to get the scores are of a known type, used once, with their settings" do
    roll = { "type" => "roll", "label" => "Lancer de dés", "dice" => 4, "sides" => 6, "keep_highest" => 3 }
    array = { "type" => "standard_array", "label" => "Tableau standard", "values" => [15] }
    point_buy = { "type" => "point_buy", "label" => "Achat de points", "points" => 27, "costs" => { "8" => 0 } }
    assert_predicate with_ability_methods([roll, array, point_buy]), :valid?

    assert_error with_ability_methods([roll.merge("type" => "rolls")]), :unknown_rule_method
    assert_error with_ability_methods([roll, roll]), :duplicate_rule_method
    assert_error with_ability_methods([roll.merge("label" => "")]), :invalid_rule_method_label
    assert_error with_ability_methods([roll.merge("faces" => 6)]), :unknown_rule_method_parameter
    assert_error with_ability_methods([roll.except("sides")]), :missing_rule_method_parameter
    assert_error with_ability_methods([roll.merge("keep_highest" => 5)]), :invalid_ability_method_dice
    assert_error with_ability_methods([array.merge("values" => [15, 14])]), :invalid_standard_array,
                 "La méthode « Tableau standard » : il faut une valeur par caractéristique (1 en tout), des nombres entiers positifs"
    assert_error with_ability_methods([point_buy.merge("costs" => { "huit" => 0 })]), :invalid_point_buy
  end

  private

  # The template given to the block (its character fields) can be changed before it is built
  def with_ability_methods(methods)
    build_template.tap { |template| template.character_fields["ability_methods"] = methods }
  end

  def with_price_lists(lists)
    build_template.tap { |template| template.character_fields["price_lists"] = lists }
  end

  def with_conditions(conditions)
    build_template.tap { |template| template.character_fields["conditions"] = conditions }
  end

  # The NPCs have a Dexterity, the initiative of their rolls
  def with_dice_rolls(dice_rolls)
    build_template.tap do |template|
      template.character_fields["dice_rolls"] = dice_rolls
      template.npc_fields = { "fields" => [{ "key" => "dexterity", "label" => "Dextérité", "type" => "ability",
                                             "modifier" => "half_above_ten" },
                                           { "key" => "speed", "label" => "Vitesse", "type" => "text" }] }
    end
  end

  def build_template(steps: DEFAULT_STEPS, spell_groups: EquipmentSpellsTemplateBuilder::SPELL_GROUPS,
                     spell_slots: EquipmentSpellsTemplateBuilder::SPELL_SLOTS)
    fields = character_fields
    yield fields if block_given?
    SheetTemplate.new(
      name: "Petit jeu", locale: "fr",
      character_fields: { "fields" => fields, "creation_steps" => steps.map(&:dup),
                          "spell_groups" => spell_groups.map(&:dup),
                          "spell_slots" => spell_slots&.dup }.compact,
      item_fields: { "fields" => [{ "key" => "group", "label" => "Groupe", "type" => "choice",
                                    "options" => ["weapon"] }] }
    )
  end

  def template_with_weapon_attacks(attacks)
    build_template.tap { |template| template.character_fields["weapon_attacks"] = attacks }
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
                          "max_spell_level" => [0] * 20, "prepared_changes" => "long_rest",
                          "slots" => [[]] * 20 },
      "starting_equipment" => { "options" => [{ "key" => "a", "items" => [{ "choose" => ["weapon"] }] },
                                              { "key" => "b", "gold" => 50 }] } }
  end

  def subclass_field
    { "key" => "subclass", "label" => "Sous-classe", "type" => "choice", "section" => "Identité",
      "options" => ["Champion"], "options_from" => "class", "options_by" => { "Guerrier" => ["Champion"] },
      "from_level" => 3, "level_from" => "level" }
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
