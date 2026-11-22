require "test_helper"

class CharacterSheetCalculatorTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "experience", "type" => "experience" },
    { "key" => "strength", "type" => "number", "has_modifier" => true },
    { "key" => "dexterity", "type" => "number", "has_modifier" => true },
    { "key" => "proficiency_bonus", "type" => "computed", "rule" => "proficiency_by_level" },
    { "key" => "athletics", "type" => "bonus", "based_on" => "strength", "proficiency" => "proficiency_bonus" },
    { "key" => "stealth", "type" => "bonus", "based_on" => "dexterity", "proficiency" => "proficiency_bonus" }
  ].freeze
  LEVEL_THRESHOLDS = [
    { "level" => 5, "experience" => 6500, "proficiency_bonus" => 3 },
    { "level" => 1, "experience" => 0, "proficiency_bonus" => 2 },
    { "level" => 2, "experience" => 300, "proficiency_bonus" => 2 }
  ].freeze

  test "the modifier of an ability is half of the score above 10, rounded down" do
    assert_equal 2, CharacterSheetCalculator.modifier(14)
    assert_equal 0, CharacterSheetCalculator.modifier(11)
    assert_equal(-1, CharacterSheetCalculator.modifier(9))
    assert_nil CharacterSheetCalculator.modifier(nil)
  end

  test "the level and its proficiency bonus follow the experience, whatever the order of the thresholds" do
    assert_equal({ level: 1, proficiency: 2 }, level_and_proficiency({}))
    assert_equal({ level: 2, proficiency: 2 }, level_and_proficiency("experience" => 300))
    assert_equal({ level: 5, proficiency: 3 }, level_and_proficiency("experience" => 7000))
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

  test "without level thresholds, there is no level and no proficiency" do
    result = CharacterSheetCalculator.new(fields: FIELDS, sheet: { "strength" => 14, "athletics" => true },
                                          level_thresholds: []).call

    assert_nil result[:level]
    assert_equal 2, result[:values]["athletics"]
  end

  private

  def calculate(sheet)
    CharacterSheetCalculator.new(fields: FIELDS, sheet: sheet, level_thresholds: LEVEL_THRESHOLDS).call
  end

  def level_and_proficiency(sheet)
    result = calculate(sheet)
    { level: result[:level], proficiency: result[:values]["proficiency_bonus"] }
  end
end
