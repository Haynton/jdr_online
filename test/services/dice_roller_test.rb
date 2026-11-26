require "test_helper"

class DiceRollerTest < ActiveSupport::TestCase
  ADVANTAGE = { "key" => "advantage", "dice" => 2, "keep" => "highest" }.freeze
  DISADVANTAGE = { "key" => "disadvantage", "dice" => 2, "keep" => "lowest" }.freeze

  test "every die counts, plus the bonus" do
    result = DiceRoller.new(count: 3, sides: 6, bonus: 2, random: Random.new(42)).call

    assert_equal 3, result.dice.size
    assert(result.dice.all? { |die| die.between?(1, 6) })
    assert_equal result.dice, result.kept
    assert_equal result.dice.sum + 2, result.total
    assert_nil result.mode_key
  end

  test "a negative bonus lowers the total" do
    result = DiceRoller.new(count: 1, sides: 20, bonus: -1, random: Random.new(3)).call

    assert_equal result.dice.first - 1, result.total
  end

  test "advantage rolls two dice and keeps the highest" do
    result = DiceRoller.new(count: 1, sides: 20, bonus: 5, mode: ADVANTAGE, random: Random.new(9)).call

    assert_equal 2, result.dice.size
    assert_equal [result.dice.max], result.kept
    assert_equal result.dice.max + 5, result.total
    assert_equal "advantage", result.mode_key
  end

  test "disadvantage keeps the lowest" do
    result = DiceRoller.new(count: 1, sides: 20, mode: DISADVANTAGE, random: Random.new(9)).call

    assert_equal [result.dice.min], result.kept
  end

  test "a die, a count or a bonus that the panel does not offer is refused" do
    assert_raises(DiceRoller::InvalidRoll) { DiceRoller.new(count: 1, sides: 7).call }
    assert_raises(DiceRoller::InvalidRoll) { DiceRoller.new(count: 0, sides: 6).call }
    assert_raises(DiceRoller::InvalidRoll) { DiceRoller.new(count: 21, sides: 6).call }
    assert_raises(DiceRoller::InvalidRoll) { DiceRoller.new(count: 1, sides: 6, bonus: 51).call }
  end

  test "the notation of a roll is the same in every language" do
    assert_equal "3d6", DiceRoller.new(count: 3, sides: 6).call.notation
    assert_equal "1d20+5", DiceRoller.new(count: 1, sides: 20, bonus: 5).call.notation
    assert_equal "1d8-1", DiceRoller.new(count: 1, sides: 8, bonus: -1).call.notation
  end

  test "a mode is refused on more than one die" do
    assert_raises(DiceRoller::InvalidRoll) { DiceRoller.new(count: 2, sides: 20, mode: ADVANTAGE).call }
  end
end
