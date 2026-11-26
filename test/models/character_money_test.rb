require "test_helper"

# The money of a character: the coins its template declares (currency: true), never below 0 nor above their max
class CharacterMoneyTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "gold", "label" => "Pièces d'or", "type" => "number", "min" => 0, "max" => 50, "at_creation" => false,
      "currency" => true },
    { "key" => "level", "label" => "Niveau", "type" => "number" }
  ].freeze

  setup do
    @character = Character.new(kind: :pc, name: "Aria", sheet: { "gold" => 10 })
    @character.define_singleton_method(:sheet_fields) { FIELDS }
    @gold = @character.currency_field("gold")
  end

  test "only the fields marked as a coin are money" do
    assert_equal ["gold"], @character.currency_fields.pluck("key")
    assert_nil @character.currency_field("level")
  end

  test "coins are added and taken out, never below 0 nor above the max of the coin" do
    assert_nil @character.change_money(@gold, 15)
    assert_equal 25, @character.coins_of(@gold)

    assert_equal :not_enough, @character.change_money(@gold, -30)
    assert_equal :too_much, @character.change_money(@gold, 30)
    assert_equal 25, @character.coins_of(@gold)
  end
end
