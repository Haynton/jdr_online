require "test_helper"

# The weapon masteries grouped by property, the groups shared between three columns of about the same height
module CharacterSheets
  class WeaponMasteryChoicesHelperTest < ActionView::TestCase
    include CharacterSheets::WeaponMasteryChoicesHelper

    Kind = CharacterSheets::WeaponMasteries::Kind

    test "each property is one group, its rule said once" do
      kinds = [Kind.new(key: "dagger", label: "Dagues", mastery: "Coup", rule: "Court."),
               Kind.new(key: "sickle", label: "Serpes", mastery: "Coup", rule: "Court.")]
      assert_equal [["Coup", "Court.", kinds]], weapon_kinds_by_mastery(kinds)
    end

    test "a long group gets a column of its own, the short ones share the others in their order" do
      long_rule = "Une longue règle. " * 20
      kinds = [Kind.new(key: "a", label: "Arcs", mastery: "Alpha", rule: "Court."),
               Kind.new(key: "b", label: "Bâtons", mastery: "Bravo", rule: long_rule),
               Kind.new(key: "c", label: "Cimeterres", mastery: "Charlie", rule: "Court."),
               Kind.new(key: "d", label: "Dagues", mastery: "Delta", rule: "Court.")]
      properties = weapon_kinds_by_mastery(kinds).map(&:first)

      assert_equal "Bravo", properties.first
      assert_equal %w[Alpha Charlie Delta], properties.drop(1).sort
      assert_equal kinds.size, properties.size
    end
  end
end
