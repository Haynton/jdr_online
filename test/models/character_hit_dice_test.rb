require "test_helper"

# The hit dice a character spends to heal: one per level, of the die of its class, plus the modifier its hit points
# read; a long rest gives them back
class CharacterHitDiceTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "class", "label" => "Classe", "type" => "choice", "options" => ["Guerrier"],
      "effects" => { "Guerrier" => { "hit_die" => 10 } } },
    { "key" => "level", "label" => "Niveau", "type" => "number", "from_table" => "starting_level" },
    { "key" => "constitution", "label" => "Constitution", "type" => "ability", "modifier" => "half_above_ten" },
    { "key" => "max_hp", "label" => "PV max", "type" => "computed", "rule" => "hit_points_by_level",
      "based_on" => "constitution", "level_from" => "level", "class_from" => "class" },
    { "key" => "hp", "label" => "Points de vie", "type" => "resource", "receives_damage" => true, "at_creation" => false }
  ].freeze

  setup do
    game_table = GameTable.new(name: "La Crypte", template_snapshot: { "character_fields" => { "fields" => FIELDS } })
    @character = Character.new(kind: :pc, name: "Brunhild", game_table: game_table,
                               sheet: { "class" => "Guerrier", "level" => 2, "constitution" => 14,
                                        "hp" => { "current" => 3, "max" => 20 } })
  end

  test "a hit die spent rolls the die of the class plus the modifier and gives back that many hit points" do
    assert_equal [10, 2, 2], [@character.hit_die_sides, @character.hit_dice_total, @character.hit_dice_left]

    spent = @character.spend_hit_die(random: Random.new(1))

    assert_equal 10, spent.sides
    assert_equal 2, spent.modifier
    assert_equal spent.roll + 2, spent.healed
    assert_equal 3 + spent.healed, @character.hit_points["current"]
    assert_equal 1, @character.hit_dice_left
  end

  test "none is spent when none is left, and a long rest gives them all back" do
    2.times { @character.spend_hit_die }
    assert_nil @character.spend_hit_die

    @character.take_long_rest
    assert_equal 2, @character.hit_dice_left
  end
end
