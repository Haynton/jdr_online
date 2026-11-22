require "test_helper"

class StartingEquipmentTest < ActiveSupport::TestCase
  setup do
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
  end

  test "the options of the class picked, and none before a class" do
    choice = equipment_for("Mage").choices.first

    assert_equal %w[a b], choice.options.pluck("key")
    assert_nil choice.chosen_key
    assert_empty equipment_for(nil).choices
  end

  test "the items of the option chosen, the item of your choice once picked, and its gold" do
    equipment = equipment_for("Mage", "option" => "a", "picks" => { "1" => "lute" })

    items = equipment.chosen_items.map { |item| [item.entry.name, item.count.to_s] }
    assert_equal [%w[Dague 2], %w[Luth 1]], items
    assert_equal 5, equipment.gold
    assert_equal 55, equipment_for("Mage", "option" => "b").gold
  end

  test "an option not offered, or a pick outside its group, is refused" do
    equipment = equipment_for("Mage")
    field = equipment.choices.first.field

    assert_nil equipment.error_for(field, { "option" => "a", "picks" => { "1" => "flute" } })
    assert_equal [:inclusion], equipment.error_for(field, { "option" => "c" })
    assert_equal [:inclusion], equipment.error_for(field, { "option" => "a", "picks" => { "1" => "dagger" } })
  end

  test "changing the class drops a choice the new class does not offer" do
    character = build_character("Guerrier", "option" => "a", "picks" => { "1" => "lute" })

    assert_not CharacterSheets::StartingEquipment.new(character).keep_offered(character.sheet).key?("class_equipment")
  end

  test "the gold of the options picked, read from the fields and the sheet" do
    fields = @game_table.character_sheet_fields

    sheet = { "class" => "Guerrier", "class_equipment" => { "option" => "b" } }
    assert_equal 60, CharacterSheets::StartingEquipment.gold_from(fields: fields, sheet: sheet)
    assert_nil CharacterSheets::StartingEquipment.gold_from(fields: fields, sheet: { "class" => "Guerrier" })
  end

  private

  def equipment_for(class_option, class_equipment = nil)
    CharacterSheets::StartingEquipment.new(build_character(class_option, class_equipment))
  end

  def build_character(class_option, class_equipment)
    sheet = { "class" => class_option, "class_equipment" => class_equipment }.compact
    @game_table.characters.build(kind: :pc, sheet: sheet)
  end
end
