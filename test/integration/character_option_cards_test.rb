require "test_helper"

# A list with icons (the class) drawn as cards on its step: a radio button in each card, sent with the form; the
# option picked explained beside them; the hidden field the page reads, of the usual id and without a name
class CharacterOptionCardsTest < ActionDispatch::IntegrationTest
  ICONS = { "Mage" => "wand_sparkles", "Prêtre" => "sun", "Guerrier" => "swords" }.freeze

  setup do
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    snapshot = sheet_template.snapshot
    class_field = snapshot["character_fields"]["fields"].find { |field| field["key"] == "class" }
    class_field["icons"] = ICONS
    class_field["descriptions"] = { "Mage" => "Un érudit des arcanes." }
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: snapshot)
    @game_table.participations.create!(user: game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(game_table: @game_table, kind: :pc, status: :draft,
                                                 creation_step: "class", sheet: { "class" => "Mage" })
    sign_in @player
  end

  test "the class is picked among cards, the one picked explained beside them" do
    get game_table_character_step_path(@game_table, "class")

    assert_select "label input[type=radio][name='character[sheet][class]']", count: 3
    assert_select "label input[type=radio][value=Mage][checked]"
    assert_select "label svg", minimum: 3
    assert_select "input[type=hidden]#character_sheet_class[value=Mage]:not([name])"
    assert_select "[data-described-choices-target=option][data-option=Mage]:not([hidden])",
                  text: /Un érudit des arcanes/
    assert_select "[data-described-choices-target=option][data-option=Guerrier][hidden]"
  end

  test "the card picked is the class saved" do
    patch game_table_character_step_path(@game_table, "class"), params: { character: { sheet: { class: "Guerrier" } } }

    assert_equal "Guerrier", @character.reload.sheet["class"]
  end
end
