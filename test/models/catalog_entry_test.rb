require "test_helper"

class CatalogEntryTest < ActiveSupport::TestCase
  SPELL_FIELDS = {
    "fields" => [
      { "key" => "level", "type" => "number", "min" => 0, "max" => 9, "required" => true },
      { "key" => "school", "type" => "choice", "options" => %w[Evocation Illusion], "required" => true },
      { "key" => "concentration", "type" => "boolean" },
      { "key" => "classes", "type" => "picks", "options" => %w[Wizard Cleric], "required" => true }
    ]
  }.freeze

  setup do
    @sheet_template = SheetTemplate.create!(name: "Fantasy", locale: "en", spell_fields: SPELL_FIELDS)
  end

  test "a spell is valid with properties that fit the spell fields of its template" do
    assert build_spell.valid?
  end

  test "a kind outside the list is refused" do
    assert build_spell(kind: "vehicle").tap(&:validate).errors.of_kind?(:kind, :inclusion)
  end

  test "a key is unique for a template and a kind" do
    build_spell.save!

    assert build_spell.tap(&:validate).errors.of_kind?(:key, :taken)
  end

  test "a name longer than the database column is refused" do
    spell = build_spell(name: "a" * (CatalogEntry::NAME_MAX_LENGTH + 1))

    assert spell.tap(&:validate).errors.of_kind?(:name, :too_long)
  end

  test "a property outside its field, or unknown to the template, is refused" do
    spell = build_spell(properties: { "level" => 12, "school" => "Cooking", "classes" => ["Wizard"],
                                      "colour" => "red" })
    errors = spell.tap(&:validate).errors

    assert errors.of_kind?(:'properties.level', :less_than_or_equal_to)
    assert errors.of_kind?(:'properties.school', :inclusion)
    assert errors.of_kind?(:'properties.colour', :invalid)
  end

  test "a required property must be there" do
    spell = build_spell(properties: { "school" => "Evocation" })
    errors = spell.tap(&:validate).errors

    assert errors.of_kind?(:'properties.level', :blank)
    assert errors.of_kind?(:'properties.classes', :blank)
  end

  test "the spells of a class, of some levels, cantrips first then by name" do
    build_spell(key: "shield", name: "Shield").save!
    build_spell(key: "fire-bolt", name: "Fire Bolt", properties: spell_properties(level: 0)).save!
    build_spell(key: "bless", name: "Bless", properties: spell_properties(classes: ["Cleric"])).save!
    build_spell(key: "blur", name: "Blur", properties: spell_properties(level: 2)).save!

    spells = @sheet_template.catalog_entries.spells.for_class("Wizard").of_level([0, 1]).by_level_and_name

    assert_equal ["Fire Bolt", "Shield"], spells.map(&:name)
  end

  private

  def build_spell(kind: "spell", key: "magic-missile", name: "Magic Missile", properties: spell_properties)
    @sheet_template.catalog_entries.build(kind: kind, key: key, name: name, properties: properties)
  end

  def spell_properties(level: 1, classes: ["Wizard"])
    { "level" => level, "school" => "Evocation", "concentration" => false, "classes" => classes }
  end
end
