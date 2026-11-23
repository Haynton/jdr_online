require "test_helper"

class PredefinedLoaderTest < ActiveSupport::TestCase
  test "it creates every predefined template of its files, with its catalog" do
    templates = SheetTemplates::PredefinedLoader.new.call

    assert_equal 4, templates.size
    assert templates.all?(&:predefined?)
    heroic_fantasy = SheetTemplate.predefined.find_by!(name: "Fantasy héroïque", locale: "fr")
    assert_predicate heroic_fantasy.catalog_entries.spells, :any?
  end

  test "run again, it updates the templates without making them twice or deleting anything" do
    SheetTemplates::PredefinedLoader.new.call
    heroic_fantasy = SheetTemplate.predefined.find_by!(name: "Fantasy héroïque", locale: "fr")
    heroic_fantasy.update!(description: "Changée à la main")
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    own_template = SheetTemplates::Duplicator.new(original: heroic_fantasy, owner: game_master).call
    counts = [SheetTemplate.count, CatalogEntry.count]

    SheetTemplates::PredefinedLoader.new.call

    assert_equal counts, [SheetTemplate.count, CatalogEntry.count]
    assert_not_equal "Changée à la main", heroic_fantasy.reload.description
    assert_predicate own_template.reload, :persisted?
  end

  test "a file refused leaves the database as it was" do
    broken_file = Rails.root.join("tmp/broken_template.fr.json")
    unknown_field_type = { fields: [{ key: "strength", label: "Force", type: "unknown" }] }
    broken_file.write({ name: "Cassé", locale: "fr", character_fields: unknown_field_type }.to_json)

    assert_raises(ActiveRecord::RecordInvalid) { SheetTemplates::Loader.new(broken_file).call }
    assert_not SheetTemplate.exists?(name: "Cassé")
  ensure
    broken_file&.delete
  end
end
