require "test_helper"

# The starting equipment on its step: its options, the item of your choice, the check of the server, and the inventory
# and the gold made when the character is complete
class CharacterEquipmentTest < ActionDispatch::IntegrationTest
  setup do
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: game_master, role: :game_master)
    @game_table.participations.create!(user: @player, role: :player)
    sign_in @player
  end

  test "the equipment has its own step: a switch between the items and the gold, then one line per item" do
    choose_class("Mage")
    get equipment_step_path

    assert_select "main h1", text: "Équipement"
    assert_select "[role=tablist]", count: 0
    assert_select "fieldset legend", text: "Classe · Mage"
    assert_select "label", text: "Objets"
    assert_select "label", text: "55 pièces d'or"
    assert_select "p", text: /55 pièces d'or\s+pour acheter votre équipement vous-même\./
    assert_select "input[type=radio][name=?][value=a][checked]", "character[sheet][class_equipment][option]"
    assert_select "input[type=radio][name=?][value=b]:not([checked])", "character[sheet][class_equipment][option]"
    assert_select "li span", text: "2 × Dague"
    assert_select "select[name=?] option", "character[sheet][class_equipment][picks][a][1]", text: "Luth"
  end

  test "the spells have their own step after the equipment, for a class that casts them" do
    choose_class("Mage")
    assert_equal %w[class equipment spells description summary], character.creation_steps.all.map(&:key)

    choose_class("Guerrier")
    assert_equal %w[class equipment description summary], character.creation_steps.all.map(&:key)
  end

  test "the option chosen and its item of your choice are saved, the picks of another option left out" do
    choose_class("Mage")
    patch equipment_step_path, params: { character: { sheet: { class_equipment: {
      option: "a", picks: { a: { "1" => "lute" }, b: { "1" => "flute" } }
    } } } }

    assert_equal({ "option" => "a", "picks" => { "1" => "lute" } }, character.sheet["class_equipment"])
  end

  test "an item outside the group of its line is refused" do
    choose_class("Mage")
    patch equipment_step_path, params: { character: { sheet: { class_equipment: {
      option: "a", picks: { a: { "1" => "dagger" } }
    } } } }

    assert_response :unprocessable_content
    assert_nil character.sheet["class_equipment"]
  end

  test "the complete character carries its starting equipment and its gold" do
    choose_class("Mage")
    patch equipment_step_path, params: { character: { sheet: { class_equipment: {
      option: "a", picks: { a: { "1" => "lute" } }
    } } } }
    patch game_table_character_step_path(@game_table, "spells"), params: { character: { spell_keys: [""] } }
    patch game_table_character_step_path(@game_table, "description"), params: { character: { name: "Elara" } }
    patch game_table_character_step_path(@game_table, "summary")

    finished = character
    assert_predicate finished, :complete?
    items = finished.inventory_items.order(:id).map { |item| [item.name, item.quantity.to_s] }
    assert_equal [%w[Dague 2], %w[Luth 1]], items
    assert_equal 5, finished.sheet["gold"]
  end

  private

  def choose_class(option)
    patch game_table_character_step_path(@game_table, "class"), params: { character: { sheet: { class: option } } }
  end

  def equipment_step_path
    game_table_character_step_path(@game_table, "equipment")
  end

  def character
    @player.participations.find_by!(game_table: @game_table).reload.character
  end
end
