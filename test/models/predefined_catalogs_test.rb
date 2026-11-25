require "test_helper"

# The predefined catalogs are files of db/seeds/catalogs (the spells of the heroic fantasy, from the SRD 5.2):
# these tests read them and check them against their template, as the seed would load them
class PredefinedCatalogsTest < ActiveSupport::TestCase
  CATALOG_FILES = Rails.root.glob("db/seeds/catalogs/*.json").sort

  test "every entry of every file is valid for its template" do
    each_catalog do |catalog_file, catalog, sheet_template|
      catalog["entries"].each do |entry_attributes|
        entry = sheet_template.catalog_entries.build(kind: catalog["kind"], **entry_attributes.symbolize_keys)

        assert entry.valid?, "#{catalog_file.basename} #{entry.key}: #{entry.errors.full_messages.to_sentence}"
      end
    end
  end

  test "the languages of a catalog share the same keys and levels: only the texts change" do
    CATALOG_FILES.group_by { |catalog_file| catalog_file.basename.to_s.split(".").first }.each_value do |versions|
      keys_and_levels = versions.map do |catalog_file|
        read_json(catalog_file)["entries"].to_h { |entry| [entry["key"], entry.dig("properties", "level")] }
      end

      assert_equal 1, keys_and_levels.uniq.size, "#{versions.map(&:basename).join(', ')} do not share the same entries"
    end
  end

  test "keys and names are unique in a file" do
    each_catalog do |catalog_file, catalog|
      %w[key name].each do |attribute|
        values = catalog["entries"].pluck(attribute)

        assert_equal values.uniq, values, "#{catalog_file.basename}: a #{attribute} twice"
      end
    end
  end

  test "the heroic fantasy has every spell of the SRD 5.2, cantrips to level 9" do
    spells = read_json(Rails.root.join("db/seeds/catalogs/heroic_fantasy_spells.en.json"))["entries"]
    spells_by_level = spells.group_by { |spell| spell.dig("properties", "level") }.transform_values(&:size)

    assert_equal({ 0 => 27, 1 => 57, 2 => 57, 3 => 42, 4 => 34, 5 => 38, 6 => 31, 7 => 20, 8 => 17, 9 => 16 },
                 spells_by_level)
  end

  test "the heroic fantasy has the creatures of challenge 0 to 2 of the SRD 5.2, the same in both languages" do
    bestiaries = %w[en fr].map do |locale|
      read_json(Rails.root.join("db/seeds/catalogs/heroic_fantasy_monsters.#{locale}.json"))["entries"]
    end
    numbers = %w[challenge armor_class hp speed strength]

    assert_equal [177, 177], bestiaries.map(&:size)
    assert_equal({ "0" => 28, "1/8" => 19, "1/4" => 32, "1/2" => 27, "1" => 27, "2" => 44 },
                 bestiaries.first.map { |creature| creature.dig("properties", "challenge") }.tally)
    assert_equal(*bestiaries.map { |entries| entries.map { |creature| creature["properties"].slice(*numbers).except("speed") } })
    assert_equal(*bestiaries.map { |entries| entries.map { |creature| creature.dig("properties", "attacks").to_a.size } })
  end

  test "every class with spells has enough of them to choose from, at levels 1 to 4" do
    each_catalog do |catalog_file, catalog, sheet_template|
      next unless catalog["kind"] == "spell"

      class_list = sheet_template.character_fields["fields"].find { |field| field["key"] == "class" }
      class_list["effects"].each do |class_option, effects|
        next unless (spellcasting = effects["spellcasting"])

        assert_includes CharacterSheets::SpellChoices::PREPARED_CHANGES, spellcasting["prepared_changes"], class_option

        (1..4).each do |level|
          assert_enough_spells(catalog, class_option, spellcasting, level, "#{catalog_file.basename} #{class_option}")
        end
      end
    end
  end

  test "every spell an option always prepares is in the catalog of spells of its template" do
    CATALOG_FILES.select { |catalog_file| read_json(catalog_file)["kind"] == "spell" }.each do |catalog_file|
      spell_keys = read_json(catalog_file)["entries"].pluck("key")
      template = create_template_of(catalog_file)
      template.character_fields["fields"].each do |field|
        field["effects"].to_h.each do |option, effects|
          missing = effects["always_prepared_spells"].to_h.values.flatten - spell_keys
          assert_empty missing, "#{catalog_file.basename} #{option}"
        end
      end
    end
  end

  test "every item of a starting equipment is in the catalog, and every group of your choice has items" do
    CATALOG_FILES.select { |catalog_file| read_json(catalog_file)["kind"] == "item" }.each do |catalog_file|
      items = read_json(catalog_file)["entries"]
      groups = items.filter_map { |item| item.dig("properties", "group") }.uniq
      template = create_template_of(catalog_file)
      starting_lines(template).each do |line|
        known = line["choose"] ? (line["choose"] - groups).empty? : items.any? { |item| item["key"] == line["key"] }
        assert known, "#{catalog_file.basename} #{line}"
      end
    end
  end

  test "the loader fills the catalog of the template, and updates it when run again" do
    catalog_file = Rails.root.join("db/seeds/catalogs/heroic_fantasy_spells.fr.json")
    sheet_template = create_template_of(catalog_file)

    Catalogs::Loader.new(catalog_file).call
    Catalogs::Loader.new(catalog_file).call

    assert_equal 339, sheet_template.catalog_entries.spells.count
    assert_equal "Projectile magique", sheet_template.catalog_entries.find_by(key: "magic-missile").name
  end

  private

  def each_catalog
    CATALOG_FILES.each do |catalog_file|
      yield catalog_file, read_json(catalog_file), create_template_of(catalog_file)
    end
  end

  def assert_enough_spells(catalog, class_option, spellcasting, level, context)
    levels = catalog["entries"].select { |entry| entry.dig("properties", "classes").include?(class_option) }
                               .map { |entry| entry.dig("properties", "level") }
    highest_level = spellcasting["max_spell_level"][level - 1]

    assert_operator levels.count(0), :>=, spellcasting["cantrips"][level - 1], "#{context}: cantrips at #{level}"
    assert_operator levels.count { |spell_level| spell_level.between?(1, highest_level) }, :>=,
                    spellcasting["prepared"][level - 1], "#{context}: prepared spells at #{level}"
  end

  # Every line of every option of the starting equipment of the template (its classes and backgrounds)
  def starting_lines(template)
    template.character_fields["fields"].flat_map do |field|
      field["effects"].to_h.values.flat_map do |effects|
        effects.dig("starting_equipment", "options").to_a.flat_map { |option| option["items"].to_a }
      end
    end
  end

  # The template the file belongs to, made from its own file of db/seeds/sheet_templates
  def create_template_of(catalog_file)
    template_name, locale = catalog_file.basename(".json").to_s.split(".")
    # heroic_fantasy_spells, heroic_fantasy_items: the template is the name without its kind
    template_file = Rails.root.join("db/seeds/sheet_templates/#{template_name.sub(/_[a-z]+\z/, '')}.#{locale}.json")
    SheetTemplate.find_or_create_by!(read_json(template_file))
  end

  def read_json(file)
    JSON.parse(file.read(encoding: "UTF-8"))
  end
end
