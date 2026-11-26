require "test_helper"

# What changes on a character during the game, read in the fields the template declares: the hit points (the field
# that receives the damage), the temporary ones that take it first, a switch granted in play, a long rest
class CharacterVitalsTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "hp", "label" => "Points de vie", "type" => "resource", "receives_damage" => true,
      "on_rest" => "reset_to_max", "at_creation" => false },
    { "key" => "temp_hp", "label" => "PV temporaires", "type" => "resource", "absorbs_damage_for" => "hp",
      "at_creation" => false },
    { "key" => "inspiration", "label" => "Inspiration", "type" => "boolean", "at_creation" => false,
      "on_rest" => "turn_off" },
    { "key" => "notes", "label" => "Notes", "type" => "text" }
  ].freeze

  setup do
    @character = Character.new(kind: :pc, name: "Aria", sheet: { "hp" => { "current" => 10, "max" => 12 } })
    @character.define_singleton_method(:sheet_fields) { FIELDS }
  end

  test "hit points stay between 0 and their maximum" do
    @character.change_hit_points(5)
    assert_equal 12, @character.hit_points["current"]

    @character.change_hit_points(-20)
    assert_equal 0, @character.hit_points["current"]
  end

  test "a loss takes the temporary hit points first" do
    @character.give_temporary_hit_points(3)
    @character.change_hit_points(-5)

    assert_equal 0, @character.temporary_hit_points
    assert_not @character.sheet.key?("temp_hp")
    assert_equal 8, @character.hit_points["current"]
  end

  test "only a switch granted in play is switched, and a long rest does what the template says" do
    @character.switch("inspiration", true)
    @character.switch("notes", true)
    assert @character.switched_on?(FIELDS[2])
    assert_nil @character.sheet["notes"]

    @character.change_hit_points(-4)
    @character.take_long_rest
    assert_equal 12, @character.hit_points["current"]
    assert_not @character.switched_on?(FIELDS[2])
  end
end
