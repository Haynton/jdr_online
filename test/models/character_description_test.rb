require "test_helper"

# Who the character is (CharacterDescription): the fields its player may still change once it is complete, decided by
# their types (FieldTypes::Base#describes_character?)
class CharacterDescriptionTest < ActiveSupport::TestCase
  test "a text, the picks and a list without effects describe the character; a list with effects does not" do
    assert FieldTypes.find("text").describes_character?({})
    assert FieldTypes.find("picks").describes_character?({})
    assert FieldTypes.find("choice").describes_character?({ "options" => %w[Loyal Chaotique] })
    assert_not FieldTypes.find("choice").describes_character?({ "effects" => { "Mage" => { "hit_die" => 6 } } })
    assert_not FieldTypes.find("ability").describes_character?({})
  end
end
