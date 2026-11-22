require "test_helper"

class AbilityScoreRollerTest < ActiveSupport::TestCase
  FOUR_D_SIX_KEEP_THREE = { "dice" => 4, "sides" => 6, "keep_highest" => 3 }.freeze

  test "each score keeps the best dice and adds them up" do
    results = CharacterSheets::AbilityScoreRoller.new(method: FOUR_D_SIX_KEEP_THREE, count: 6, random: Random.new(42)).call

    assert_equal 6, results.size
    results.each do |result|
      assert_equal 4, result.dice.size
      assert(result.dice.all? { |die| die.between?(1, 6) })
      assert_equal result.dice.max(3).sort, result.kept.sort
      assert_equal result.kept.sum, result.total
    end
  end

  test "the best result comes first" do
    totals = CharacterSheets::AbilityScoreRoller.new(method: FOUR_D_SIX_KEEP_THREE, count: 6, random: Random.new(7)).call.map(&:total)

    assert_equal totals.sort.reverse, totals
  end

  test "without keep_highest, every die counts" do
    result = CharacterSheets::AbilityScoreRoller.new(method: { "dice" => 3, "sides" => 6 }, count: 1, random: Random.new(1)).call.first

    assert_equal result.dice.sum, result.total
  end
end
