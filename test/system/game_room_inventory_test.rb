require "application_system_test_case"

# The panel « Inventaire » of a player in the game room: − takes one item away and the server redraws the list in
# place, the panel open and each line still opening its details; the last one is asked first. Gold pieces are spent
# the same way, never more than the character has
class GameRoomInventoryTest < ApplicationSystemTestCase
  setup do
    player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: create_user("maitre"), role: :game_master)
    participation = @game_table.participations.create!(user: player, role: :player)
    character = participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
    @character = character
    @potion = character.inventory_items.create!(key: "potion", name: "Potion", quantity: 2,
                                                description: "Rend des points de vie.")
  end

  test "a player takes a potion away, then the last one after the question" do
    open_room_as("joueur")
    find("a[data-panel-id=game-room-panel-inventory]").click

    within("#game-room-inventory") { find("button[aria-label='Retirer 1 Potion']").click }

    assert_selector "#game-room-inventory", text: "Potion"
    assert_no_selector "#game-room-inventory", text: "2 × Potion"
    assert_selector "#game-room-panel-inventory[data-open]"
    assert_selector "#game-room-inventory button[data-action='details-dialog#open']", text: "Potion"
    assert_equal 1, @potion.reload.quantity

    within("#game-room-inventory") { find("button[aria-label='Retirer 1 Potion']").click }
    within("dialog[open]") { click_on "Retirer" }

    assert_no_selector "#game-room-inventory li"
    assert_not InventoryItem.exists?(@potion.id)
  end

  test "a player spends gold pieces: too many are refused under the field, the panel stays open" do
    @character.update_columns(sheet: @character.sheet.merge("gold" => 7))
    open_room_as("joueur")
    find("a[data-panel-id=game-room-panel-inventory]").click

    within("#game-room-inventory") do
      fill_in "inventory-value-gold", with: "9"
      page.execute_script("document.getElementById('inventory-value-gold').removeAttribute('max')")
      click_on "Retirer"
    end

    assert_selector "#inventory-value-gold-error", text: "Indiquez une somme de 1 à 7."
    within("#game-room-inventory") do
      fill_in "inventory-value-gold", with: "4"
      find("button[aria-label=\"Augmenter Pièces d'or\"]").click
      click_on "Retirer"
    end

    assert_selector "#game-room-inventory", text: /Pièces d'or\s*2/i
    assert_no_selector "#inventory-value-gold-error"
    assert_selector "#game-room-panel-inventory[data-open]"
    assert_equal 2, @character.reload.sheet["gold"]
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end

  def open_room_as(username)
    visit new_user_session_path
    fill_in "user_email", with: "#{username}@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "#side-nav"
    visit game_table_path(@game_table)
  end
end
