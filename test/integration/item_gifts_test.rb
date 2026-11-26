require "test_helper"

# The game master gives an item of the catalog of the table to a player, from the game room: a copy goes into the
# inventory of their character
class ItemGiftsTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
  end

  test "the game master gives an item to a player, back to the room with a message" do
    sign_in @game_master

    assert_difference("@character.inventory_items.count", 1) do
      post game_table_item_gift_path(@game_table), params: { key: "dagger", character_id: @character.id, quantity: 3 }
    end
    assert_redirected_to game_table_path(@game_table)
    item = @character.inventory_items.last
    assert_equal ["dagger", "Dague", 3], [item.key, item.name, item.quantity]
    assert_equal "3 × « Dague » donnés à Aria.", flash[:notice]
  end

  test "the panel of the items has a window to give one, for the game master only" do
    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "#game-room-panel-items button[data-action='item-gift#open'][data-item-gift-key-param=dagger]"
    assert_select "#game-room-panel-items dialog form[action=?] input[type=radio][value=?]",
                  game_table_item_gift_path(@game_table), @character.id.to_s
  end

  test "a player cannot give an item, nor an unknown item be given" do
    sign_in @player
    post game_table_item_gift_path(@game_table), params: { key: "dagger", character_id: @character.id }
    assert_response :not_found

    sign_in @game_master
    post game_table_item_gift_path(@game_table), params: { key: "excalibur", character_id: @character.id }
    assert_response :not_found
    assert_equal 0, @character.inventory_items.count
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end
end
