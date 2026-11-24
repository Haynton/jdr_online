require "test_helper"

class UnofferedValuesRemoverTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "class", "type" => "choice", "options" => %w[Guerrier Roublard] },
    { "key" => "level", "type" => "number" },
    { "key" => "subclass", "type" => "choice", "options" => %w[Champion Voleur], "options_from" => "class",
      "options_by" => { "Guerrier" => ["Champion"], "Roublard" => ["Voleur"] }, "from_level" => 3,
      "level_from" => "level" }
  ].freeze

  test "a subclass stays with its class from level 3, and goes when the class or the level no longer offer it" do
    remover = CharacterSheets::UnofferedValuesRemover.new(fields: FIELDS)
    warrior = { "class" => "Guerrier", "level" => 3, "subclass" => "Champion" }

    assert_equal warrior, remover.call(warrior)
    assert_equal({ "class" => "Roublard", "level" => 3 }, remover.call(warrior.merge("class" => "Roublard")))
    assert_equal({ "class" => "Guerrier", "level" => 2 }, remover.call(warrior.merge("level" => 2)))
  end

  test "a value of a list that depends on nothing stays, even out of its options: the check refuses it" do
    remover = CharacterSheets::UnofferedValuesRemover.new(fields: FIELDS)

    assert_equal({ "class" => "Barde" }, remover.call({ "class" => "Barde" }))
  end
end
