require "test_helper"

# The ways to get the scores of the abilities: what each one refuses in the scores typed
class AbilityMethodsTest < ActiveSupport::TestCase
  ARRAY = { "type" => "standard_array", "label" => "Tableau standard", "values" => [15, 14, 13, 12, 10, 8] }.freeze
  POINT_BUY = { "type" => "point_buy", "label" => "Achat de points", "points" => 27,
                "costs" => { "8" => 0, "9" => 1, "10" => 2, "11" => 3, "12" => 4, "13" => 5, "14" => 7, "15" => 9 } }.freeze

  test "the registry knows its ways, in order" do
    assert_equal %w[roll standard_array point_buy], AbilityMethods.keys
    assert_nil AbilityMethods.find("rolls")
  end

  test "a roll leaves the scores free" do
    assert_empty AbilityMethods.find("roll").score_errors({ "strength" => 3, "dexterity" => 18 }, {})
  end

  test "the standard array refuses a value it has not, and a value placed twice" do
    errors = AbilityMethods.find("standard_array").score_errors({ "strength" => 15, "dexterity" => 15,
                                                                   "constitution" => 9 }, ARRAY)

    assert_includes errors, [["constitution"], :not_in_standard_array, { values: "15, 14, 13, 12, 10, 8" }]
    assert_includes errors, [%w[strength dexterity], :standard_array_value_taken, { value: 15 }]
  end

  test "the standard array accepts its values placed once, some not placed yet" do
    assert_empty AbilityMethods.find("standard_array").score_errors({ "strength" => 15, "dexterity" => 8 }, ARRAY)
  end

  test "the point buy refuses a score outside its costs, and more points than it gives" do
    point_buy = AbilityMethods.find("point_buy")

    assert_equal [[["strength"], :outside_point_buy, { minimum: 8, maximum: 15 }]],
                 point_buy.score_errors({ "strength" => 16 }, POINT_BUY)
    assert_equal [[[], :too_many_points, { count: 7 }]],
                 point_buy.score_errors({ "strength" => 15, "dexterity" => 15, "constitution" => 15,
                                         "intelligence" => 14 }, POINT_BUY)
    assert_empty point_buy.score_errors({ "strength" => 15, "dexterity" => 15, "constitution" => 15 }, POINT_BUY)
  end

  test "each way says its guide, which exists" do
    AbilityMethods.all.each do |ability_method|
      partial = ability_method.guide_partial.sub(%r{/([^/]+)\z}, '/_\1.html.erb')
      assert Rails.root.join("app/views", partial).exist?, "#{ability_method.key}: #{partial}"
    end
  end
end
