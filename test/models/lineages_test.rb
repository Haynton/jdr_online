require "test_helper"

# The lineages of the heroic fantasy (SRD 5.2.1): a list under the species, offered only for a species that has some,
# whose spells become spells always prepared from their level (even for a class without spells) and which may set the
# speed (the wood elf)
class LineagesTest < ActiveSupport::TestCase
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    @template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_spells.fr.json")).call
    @game_table = GameTable.new(name: "La Crypte", starting_level: 5)
    @game_table.use_sheet_template(@template)
    @game_table.save!
  end

  test "a species with lineages offers its own, a species without none" do
    lineage = @game_table.character_sheet_fields.find { |field| field["key"] == "lineage" }
    type = FieldTypes.of(lineage)

    assert_equal ["Drow", "Haut-elfe", "Elfe sylvestre"], type.offered_options(lineage, { "species" => "Elfe" })
    assert_not type.asked_on?(lineage, { "species" => "Humain" })
  end

  test "the spells of a lineage are always prepared from their level, even for a fighter" do
    character = build_character("class" => "Guerrier", "species" => "Elfe", "lineage" => "Drow")

    assert_equal %w[dancing-lights faerie-fire darkness], character.spell_choices.always_prepared.keys
  end

  test "the wood elf sets its speed" do
    sheet = CharacterSheets::ChoiceEffectsApplier.new(fields: @game_table.character_sheet_fields, previous_sheet: {})
                                                 .call("species" => "Elfe", "lineage" => "Elfe sylvestre")

    assert_in_delta 10.5, sheet["speed"]
  end

  private

  def build_character(sheet)
    @game_table.characters.build(kind: :pc, name: "Vex", status: :draft, sheet: sheet)
  end
end
