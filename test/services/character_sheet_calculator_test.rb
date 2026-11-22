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
    assert_equal 2, CharacterSheetCalculator.modifier(14, "half_above_ten")
    assert_equal 0, CharacterSheetCalculator.modifier(11, "half_above_ten")
    assert_equal(-1, CharacterSheetCalculator.modifier(9, "half_above_ten"))
    assert_nil CharacterSheetCalculator.modifier(nil, "half_above_ten")
    assert_nil CharacterSheetCalculator.modifier(14, "unknown_rule")
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
      CharacterSheetCalculator.new(fields: fields, sheet: sheet, level_thresholds: []).call[:values]["hit_dice"]
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
      values = CharacterSheetCalculator.new(fields: fields, sheet: sheet, level_thresholds: LEVEL_THRESHOLDS)
                                       .call[:values]
      values.values_at("spell_save_dc", "spell_attack_bonus")
    end

    assert_equal ["13", 5], spells.call("class" => "Magicien", "strength" => 16, "level" => 1)
    assert_equal [nil, nil], spells.call("class" => "Guerrier", "strength" => 16)
    assert_equal [nil, nil], spells.call("class" => "Magicien")
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
    result = CharacterSheetCalculator.new(fields: FIELDS, sheet: { "strength" => 14, "athletics" => true },
                                          level_thresholds: []).call

    assert_nil result[:values]["proficiency_bonus"]
    assert_equal 2, result[:values]["athletics"]
  end

  private

  def calculate(sheet)
    CharacterSheetCalculator.new(fields: FIELDS, sheet: sheet, level_thresholds: LEVEL_THRESHOLDS).call
  end

  def proficiency_at(sheet)
    calculate(sheet)[:values]["proficiency_bonus"]
  end
end
