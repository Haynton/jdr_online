require "test_helper"

# The "+1" tokens of the bonus of the background: one per point of the rule of its field (total)
module CharacterSheets
  class AbilityCardsHelperTest < ActionView::TestCase
    include CharacterSheets::AbilityCardsHelper

    test "the bonus of the heroic fantasy gives three +1" do
      assert_equal 3, ability_bonus_token_count({ "total" => 3, "max_per_ability" => 2 })
    end

    test "a bonus without a rule gives no token" do
      assert_equal 0, ability_bonus_token_count({})
    end
  end
end
