require "test_helper"

class CharacterSheetCalculatorTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "level", "type" => "number", "min" => 1, "max" => 20 },
    { "key" => "strength", "type" => "ability", "modifier" => "half_above_ten" },
    { "key" => "dexterity", "type" => "ability", "modifier" => "half_above_ten" },
    { "key" => "proficiency_bonus", "type" => "computed", "rule" => "proficiency_by_level", "level_from" => "level" },
    { "key" => "initiative", "type" => "computed", "rule" => "ability_modifier", "based_on" => "dexterity" },
    { "key" => "athletics", "type" => "bonus", "based_on" => "strength", "proficiency" => "proficiency_bonus" },
    { "key" => "stealth", "type" => "bonus", "based_on" => "dexterity", "proficiency" => "proficiency_bonus" }
  ].freeze
  LEVEL_THRESHOLDS = [
    { "level" => 5, "proficiency_bonus" => 3 },
    { "level" => 1, "proficiency_bonus" => 2 },
    { "level" => 9, "proficiency_bonus" => 4 }
  ].freeze

  test "the modifier of an ability is half of the score above 10, rounded down" do
    assert_equal 2, ModifierRules.modifier(14, "half_above_ten")
    assert_equal 0, ModifierRules.modifier(11, "half_above_ten")
    assert_equal(-1, ModifierRules.modifier(9, "half_above_ten"))
    assert_nil ModifierRules.modifier(nil, "half_above_ten")
    assert_nil ModifierRules.modifier(14, "unknown_rule")
  end

  test "the proficiency bonus follows the level typed, whatever the order of the thresholds" do
    assert_equal 2, proficiency_at({})
    assert_equal 2, proficiency_at("level" => 4)
    assert_equal 3, proficiency_at("level" => 5)
    assert_equal 4, proficiency_at("level" => 12)
  end

  test "the initiative is the modifier of the ability it is based on" do
    assert_equal 2, calculate("dexterity" => 15)[:values]["initiative"]
    assert_nil calculate({})[:values]["initiative"]
  end

  test "the hit dice are one die per level, its sides the hit die of the class chosen" do
    class_effects = { "Clerc" => { "hit_die" => 8 }, "Magicien" => { "hit_die" => 6 } }
    fields = FIELDS + [{ "key" => "class", "type" => "choice", "effects" => class_effects },
                       { "key" => "hit_dice", "type" => "computed", "rule" => "hit_dice_by_class",
                         "class_from" => "class", "level_from" => "level" }]
    hit_dice = lambda do |sheet|
      CharacterSheets::Calculator.new(fields: fields, sheet: sheet, level_thresholds: []).call[:values]["hit_dice"]
    end

    assert_equal "3d8", hit_dice.call("class" => "Clerc", "level" => 3)
    assert_equal "1d6", hit_dice.call("class" => "Magicien")
    assert_nil hit_dice.call({})
  end

  test "the spells of a class use its spellcasting ability and the proficiency" do
    class_effects = { "Magicien" => { "hit_die" => 6, "spellcasting" => { "ability" => "strength" } },
                      "Guerrier" => { "hit_die" => 10 } }
    fields = FIELDS + [{ "key" => "class", "type" => "choice", "effects" => class_effects }] +
             %w[spell_save_dc spell_attack_bonus].map do |rule|
               { "key" => rule, "type" => "computed", "rule" => rule, "class_from" => "class",
                 "proficiency" => "proficiency_bonus" }
             end
    spells = lambda do |sheet|
      values = CharacterSheets::Calculator.new(fields: fields, sheet: sheet, level_thresholds: LEVEL_THRESHOLDS)
                                       .call[:values]
      values.values_at("spell_save_dc", "spell_attack_bonus")
    end

    assert_equal ["13", 5], spells.call("class" => "Magicien", "strength" => 16, "level" => 1)
    assert_equal [nil, nil], spells.call("class" => "Guerrier", "strength" => 16)
    assert_equal [nil, nil], spells.call("class" => "Magicien")
  end

  test "the hit points take the highest die at level 1, then its average at each level, Constitution each time" do
    class_effects = { "Magicien" => { "hit_die" => 6 } }
    fields = FIELDS + [{ "key" => "class", "type" => "choice", "effects" => class_effects },
                       { "key" => "max_hp", "type" => "computed", "rule" => "hit_points_by_level",
                         "class_from" => "class", "level_from" => "level", "based_on" => "strength" }]
    hit_points = lambda do |sheet|
      CharacterSheets::Calculator.new(fields: fields, sheet: sheet, level_thresholds: []).call[:values]["max_hp"]
    end

    assert_equal "8", hit_points.call("class" => "Magicien", "strength" => 14)
    assert_equal "20", hit_points.call("class" => "Magicien", "strength" => 14, "level" => 3)
    assert_nil hit_points.call("strength" => 14)
  end

  test "rolled hit dice replace the average, each with Constitution, at least 1 a level; nothing while due" do
    fields = FIELDS + [{ "key" => "class", "type" => "choice", "effects" => { "Magicien" => { "hit_die" => 6 } } },
                       { "key" => "max_hp", "type" => "computed", "rule" => "hit_points_by_level",
                         "class_from" => "class", "level_from" => "level", "based_on" => "strength" }]
    sheet = { "class" => "Magicien", "strength" => 6, "level" => 3 }
    hit_points = lambda do |rolls|
      play_state = CharacterSheets::PlayState.new(hit_point_rolls: rolls)
      CharacterSheets::Calculator.new(fields: fields, sheet: sheet, level_thresholds: [], play_state: play_state)
                                 .call[:values]["max_hp"]
    end

    assert_equal "9", hit_points.call([6, 1])
    assert_nil hit_points.call(HitPointMethods::Roll::NOT_ROLLED)
  end

  test "the armour class without armour is 10 and Dexterity, plus the ability of the unarmored defense" do
    class_effects = { "Moine" => { "hit_die" => 8, "unarmored_defense" => "strength" }, "Magicien" => { "hit_die" => 6 } }
    fields = FIELDS + [{ "key" => "class", "type" => "choice", "effects" => class_effects },
                       { "key" => "base_armor_class", "type" => "computed", "rule" => "unarmored_armor_class",
                         "class_from" => "class", "based_on" => "dexterity" }]
    armor_class = lambda do |sheet|
      CharacterSheets::Calculator.new(fields: fields, sheet: sheet, level_thresholds: []).call[:values]["base_armor_class"]
    end

    assert_equal "12", armor_class.call("class" => "Magicien", "dexterity" => 14, "strength" => 16)
    assert_equal "15", armor_class.call("class" => "Moine", "dexterity" => 14, "strength" => 16)
    assert_nil armor_class.call("class" => "Moine")
  end

  test "the armour class of the equipment: the armour, Dexterity within its cap, the shield, the bonus of the game master" do
    class_effects = { "Moine" => { "hit_die" => 8, "unarmored_defense" => "strength",
                                   "unarmored_defense_without_shield" => true },
                      "Barbare" => { "hit_die" => 12, "unarmored_defense" => "strength" }, "Guerrier" => { "hit_die" => 10 } }
    fields = FIELDS + [{ "key" => "class", "type" => "choice", "effects" => class_effects },
                       { "key" => "armor_class_bonus", "type" => "number" },
                       { "key" => "armor_class", "type" => "computed", "rule" => "worn_armor_class",
                         "class_from" => "class", "based_on" => "dexterity", "bonus_from" => "armor_class_bonus" }]
    fighter = { "class" => "Guerrier", "dexterity" => 16, "strength" => 14 }
    leather = { "armor_base" => 11 }
    chain_shirt = { "armor_base" => 13, "armor_dexterity_cap" => 2 }
    chain_mail = { "armor_base" => 16, "armor_dexterity_cap" => 0 }
    shield = { "armor_bonus" => 2 }
    armor_class = lambda do |sheet, equipped_items, style_effects = {}|
      play_state = CharacterSheets::PlayState.new(equipped_items: equipped_items, fighting_style_effects: style_effects)
      CharacterSheets::Calculator.new(fields: fields, sheet: sheet, level_thresholds: [], play_state: play_state)
                                 .call[:values]["armor_class"]
    end

    assert_equal "13", armor_class.call(fighter, [])
    assert_equal "14", armor_class.call(fighter, [leather])
    assert_equal "15", armor_class.call(fighter, [chain_shirt])
    assert_equal "18", armor_class.call(fighter, [chain_mail, shield])
    assert_equal "19", armor_class.call(fighter.merge("armor_class_bonus" => 1), [chain_mail, shield])
    # Defense: +1 while armoured, nothing without armour
    defense = { "armored_armor_class_bonus" => 1 }
    assert_equal "17", armor_class.call(fighter, [chain_mail], defense)
    assert_equal "13", armor_class.call(fighter, [], defense)
    # Dexterity +3 and Strength +4: the monk loses its unarmored defense with a shield, the barbarian keeps it
    strong = fighter.merge("strength" => 18)
    assert_equal "17", armor_class.call(strong.merge("class" => "Moine"), [])
    assert_equal "15", armor_class.call(strong.merge("class" => "Moine"), [shield])
    assert_equal "19", armor_class.call(strong.merge("class" => "Barbare"), [shield])
    assert_nil armor_class.call({ "class" => "Guerrier" }, [chain_mail])
  end

  test "the effects of a subclass add to those of its class: hit points per level, unarmored defense" do
    class_effects = { "Ensorceleur" => { "hit_die" => 6 } }
    subclass_effects = { "Sorcellerie draconique" => { "hit_points_per_level" => 1, "unarmored_defense" => "strength" } }
    fields = FIELDS + [{ "key" => "class", "type" => "choice", "effects" => class_effects },
                       { "key" => "subclass", "type" => "choice", "options_from" => "class", "effects" => subclass_effects },
                       { "key" => "max_hp", "type" => "computed", "rule" => "hit_points_by_level", "based_on" => "dexterity",
                         "level_from" => "level", "class_from" => "class" },
                       { "key" => "base_armor_class", "type" => "computed", "rule" => "unarmored_armor_class",
                         "class_from" => "class", "based_on" => "dexterity" }]
    sorcerer = { "class" => "Ensorceleur", "level" => 3, "dexterity" => 14, "strength" => 16 }
    values = lambda do |sheet|
      CharacterSheets::Calculator.new(fields: fields, sheet: sheet, level_thresholds: []).call[:values]
    end

    # 6 + 2, then 2 levels of 4 + 2, then 3 points of the draconic resilience
    assert_equal "23", values.call(sorcerer.merge("subclass" => "Sorcellerie draconique"))["max_hp"]
    assert_equal "20", values.call(sorcerer)["max_hp"]
    assert_equal "15", values.call(sorcerer.merge("subclass" => "Sorcellerie draconique"))["base_armor_class"]
    assert_equal "12", values.call(sorcerer)["base_armor_class"]
  end

  test "the bonus of the background raises the score, and the modifier follows the score raised" do
    fields = FIELDS + [{ "key" => "ability_bonuses", "type" => "ability_bonuses", "from" => "background" }]
    computed = CharacterSheets::Calculator.new(fields: fields, sheet: { "strength" => 13, "dexterity" => 14,
                                                                     "ability_bonuses" => { "strength" => 2 } },
                                            level_thresholds: []).call

    assert_equal({ "strength" => 15, "dexterity" => 14 }, computed[:scores])
    assert_equal({ "strength" => 2, "dexterity" => 2 }, computed[:modifiers])
  end

  test "a bonus is the modifier of its ability, plus the proficiency when ticked" do
    values = calculate("strength" => 14, "dexterity" => 9, "athletics" => true, "stealth" => false)[:values]

    assert_equal 4, values["athletics"]
    assert_equal(-1, values["stealth"])
  end

  test "without a score, the modifier and the bonuses based on it cannot be worked out" do
    result = calculate("athletics" => true)

    assert_nil result[:modifiers]["strength"]
    assert_nil result[:values]["athletics"]
  end

  test "without level thresholds, there is no proficiency" do
    result = CharacterSheets::Calculator.new(fields: FIELDS, sheet: { "strength" => 14, "athletics" => true },
                                          level_thresholds: []).call

    assert_nil result[:values]["proficiency_bonus"]
    assert_equal 2, result[:values]["athletics"]
  end

  private

  def calculate(sheet)
    CharacterSheets::Calculator.new(fields: FIELDS, sheet: sheet, level_thresholds: LEVEL_THRESHOLDS).call
  end

  def proficiency_at(sheet)
    calculate(sheet)[:values]["proficiency_bonus"]
  end
end
