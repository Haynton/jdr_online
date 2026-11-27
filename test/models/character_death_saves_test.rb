require "test_helper"

# The death saving throws, as the template declares them: at 0 hit points, a roll each turn; a hit at 0 is a failure,
# a heal clears them
class CharacterDeathSavesTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "hp", "label" => "Points de vie", "type" => "resource", "receives_damage" => true, "at_creation" => false },
    { "key" => "successes", "label" => "Réussites", "type" => "number", "at_creation" => false, "internal" => true },
    { "key" => "failures", "label" => "Échecs", "type" => "number", "at_creation" => false, "internal" => true }
  ].freeze
  DEATH_SAVES = { "label" => "Jets contre la mort", "sides" => 20, "success_from" => 10, "needed" => 3,
                  "critical_failure" => 1, "critical_success" => 20, "massive_damage" => true,
                  "successes_from" => "successes", "failures_from" => "failures" }.freeze

  setup do
    game_table = GameTable.new(name: "La Crypte", template_snapshot: {
                                 "character_fields" => { "fields" => FIELDS, "death_saves" => DEATH_SAVES }
                               })
    @character = Character.new(kind: :pc, name: "Aria", game_table: game_table,
                               sheet: { "hp" => { "current" => 4, "max" => 10 } })
  end

  test "a character at 0 hit points is dying, and each roll is a success, a failure or two" do
    @character.change_hit_points(-4)
    assert_predicate @character, :dying?

    assert_equal :success, @character.take_death_save(10)
    assert_equal :failure, @character.take_death_save(9)
    assert_equal :critical_failure, @character.take_death_save(1)

    assert_equal [1, 3], [@character.death_save_successes, @character.death_save_failures]
    assert_predicate @character, :dead?
  end

  test "three successes make it stable, a 20 gives back 1 hit point and clears them" do
    @character.change_hit_points(-4)
    3.times { @character.take_death_save(15) }
    assert_predicate @character, :stable?

    @character.sheet = @character.sheet.merge("successes" => 1)
    assert_equal :revived, @character.take_death_save(20)
    assert_equal 1, @character.hit_points["current"]
    assert_equal 0, @character.death_save_successes
  end

  test "a hit at 0 hit points is a failure, and a hit past the maximum kills at once" do
    @character.change_hit_points(-4)
    @character.change_hit_points(-2)
    assert_equal 1, @character.death_save_failures

    @character.sheet = { "hp" => { "current" => 4, "max" => 10 } }
    @character.change_hit_points(-14)
    assert_predicate @character, :dead?
  end

  test "hit points above 0 again clear the successes and the failures when saved" do
    @character.change_hit_points(-4)
    @character.take_death_save(5)
    @character.change_hit_points(3)

    @character.send(:clear_death_saves) if @character.send(:death_saves_to_clear?)
    assert_equal [0, 0], [@character.death_save_successes, @character.death_save_failures]
  end
end
