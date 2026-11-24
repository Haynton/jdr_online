require "test_helper"

# The lists beside the search of a catalog: one per field marked "filter", offering only the values the entries have
class CatalogFiltersHelperTest < ActionView::TestCase
  FIELDS = [
    { "key" => "level", "label" => "Niveau", "type" => "number", "min" => 0, "max" => 2, "filter" => true,
      "labels" => ["Sort mineur", "Niveau 1", "Niveau 2"] },
    { "key" => "school", "label" => "École", "type" => "choice", "filter" => true,
      "options" => %w[Abjuration Évocation Illusion] },
    { "key" => "range", "label" => "Portée", "type" => "text", "short" => true }
  ].freeze

  test "a list per field marked filter, with only the values the entries have, in the order of the field" do
    entries = [entry(0, "Évocation"), entry(2, "Abjuration"), entry(2, "Évocation")]
    filters = catalog_filters(FIELDS, entries)

    assert_equal %w[level school], filters.map(&:key)
    assert_equal [["Sort mineur", 0], ["Niveau 2", 2]], filters.first.choices
    assert_equal [%w[Abjuration Abjuration], %w[Évocation Évocation]], filters.last.choices
  end

  test "a list with a single value is left out: it would filter nothing" do
    assert_equal ["level"], catalog_filters(FIELDS, [entry(0, "Illusion"), entry(1, "Illusion")]).map(&:key)
  end

  test "each entry carries its values for the filters, as text" do
    assert_equal({ "level" => "2", "school" => "Évocation" },
                 JSON.parse(catalog_filter_values(entry(2, "Évocation"), catalog_filter_keys(FIELDS))))
  end

  private

  def entry(level, school)
    CatalogEntry.new(properties: { "level" => level, "school" => school })
  end
end
