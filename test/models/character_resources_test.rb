require "test_helper"

# The resources of a character: those its class and subclass give at its level, spent and given back by a rest as
# the template declares
class CharacterResourcesTest < ActiveSupport::TestCase
  CLASS_EFFECTS = {
    "Barde" => { "resources" => [{ "key" => "inspiration", "label" => "Inspiration", "uses_from" => "charisma",
                                   "recovery" => "long_rest", "short_rest_from_level" => 5 }] },
    "Guerrier" => { "resources" => [
      { "key" => "second_wind", "label" => "Second souffle", "uses" => [2] * 3 + [3] * 17, "recovery" => "short_rest_one" },
      { "key" => "action_surge", "label" => "Fougue", "uses" => [0] + [1] * 19, "recovery" => "short_rest" },
      { "key" => "pool", "label" => "Réserve", "uses" => (1..20).map { |level| 5 * level }, "recovery" => "long_rest",
        "pool" => true }
    ] }
  }.freeze
  FIELDS = [
    { "key" => "class", "label" => "Classe", "type" => "choice", "options" => %w[Barde Guerrier], "effects" => CLASS_EFFECTS },
    { "key" => "level", "label" => "Niveau", "type" => "number", "from_table" => "starting_level" },
    { "key" => "charisma", "label" => "Charisme", "type" => "ability", "modifier" => "half_above_ten" }
  ].freeze

  setup do
    game_table = GameTable.new(name: "La Crypte", template_snapshot: { "character_fields" => { "fields" => FIELDS } })
    @character = Character.new(kind: :pc, name: "Aria", game_table: game_table,
                               sheet: { "class" => "Guerrier", "level" => 1, "charisma" => 16 })
  end

  test "a resource counts from the level where its table gives some" do
    assert_equal [%w[second_wind 2], %w[pool 5]], @character.resources.map { |resource| [resource.key, resource.total.to_s] }

    @character.sheet = @character.sheet.merge("level" => 4)
    assert_equal({ "second_wind" => 3, "action_surge" => 1, "pool" => 20 },
                 @character.resources.to_h { |resource| [resource.key, resource.total] })
  end

  test "a resource is spent and given back, never above its total nor below nothing spent" do
    second_wind = @character.resource("second_wind")
    assert_nil @character.change_resource(second_wind, 2)
    assert_equal :not_enough, @character.change_resource(@character.resource("second_wind"), 1)
    assert_nil @character.change_resource(@character.resource("second_wind"), -1)
    assert_equal 1, @character.resource("second_wind").left
    assert_equal :nothing_spent, @character.change_resource(@character.resource("pool"), -1)
  end

  test "a short rest gives back one, all, or nothing, as each resource declares; a long rest gives back all" do
    @character.sheet = @character.sheet.merge("level" => 4)
    @character.resources_used = { "second_wind" => 3, "action_surge" => 1, "pool" => 10 }

    @character.take_short_rest
    assert_equal({ "second_wind" => 2, "action_surge" => 0, "pool" => 10 },
                 @character.resources.to_h { |resource| [resource.key, resource.used] })

    @character.give_back_resources
    assert(@character.resources.all? { |resource| resource.used.zero? })
  end

  test "the modifier of an ability gives the uses, at least 1, and a short rest gives them back from a level" do
    @character.sheet = @character.sheet.merge("class" => "Barde")
    assert_equal 3, @character.resource("inspiration").total

    @character.resources_used = { "inspiration" => 2 }
    @character.take_short_rest
    assert_equal 2, @character.resource("inspiration").used

    @character.sheet = @character.sheet.merge("level" => 5)
    @character.take_short_rest
    assert_equal 0, @character.resource("inspiration").used
  end
end
