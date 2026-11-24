require "test_helper"

class SpellSlotsTest < ActiveSupport::TestCase
  setup do
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
  end

  test "the slots of the class at the level of the character, with the label and help of the template" do
    slots = slots_for("Mage", level: 3)

    assert_equal [[1, 4], [2, 2]], slots.counts
    assert_equal "Emplacements de sorts", slots.label
    assert_equal "Rendus après un repos long.", slots.help
  end

  test "a level of spell without slots is left out, and a class may name its slots" do
    slots = slots_for("Prêtre", level: 2)

    assert_equal [[2, 2]], slots.counts
    assert_equal "Faveurs", slots.label
    assert_equal "Rendues à l'aube.", slots.help
  end

  test "no slots for a class without spells, a character without class or a template without slots" do
    assert_nil slots_for("Guerrier", level: 5)
    assert_nil slots_for(nil, level: 5)

    @game_table.template_snapshot["character_fields"].delete("spell_slots")

    assert_nil slots_for("Mage", level: 5)
  end

  private

  def slots_for(class_option, level:)
    character = @game_table.characters.build(kind: :pc, sheet: { "class" => class_option, "level" => level }.compact)
    CharacterSheets::SpellSlots.new(character).call
  end
end
