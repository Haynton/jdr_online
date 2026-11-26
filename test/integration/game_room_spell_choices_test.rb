require "test_helper"

# A player changes the spells of their character from the game room: the list of the Spells step in the window of the
# room, checked by the server (the numbers of the class and the level), the change written in the chat; only their
# own character, only with spells to choose
class GameRoomSpellChoicesTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = User.create!(email: "maitre@example.com", username: "maitre", password: TEST_PASSWORD, locale: "fr")
    @player = User.create!(email: "joueur@example.com", username: "joueur", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria",
                                                 sheet: { "class" => "Mage" })
    @character.choose_spells(%w[fire-bolt magic-missile])
    @character.save!
    @frame = { "Turbo-Frame" => GameRoomHelper::SHEET_FRAME }
  end

  test "the panel of the spells opens the list of the Spells step in the window of the room" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "#game-room-panel-spells a[href=?][data-turbo-frame=?]", edit_game_table_spell_choice_path(@game_table),
                  GameRoomHelper::SHEET_FRAME, text: /Changer mes sorts/

    get edit_game_table_spell_choice_path(@game_table), headers: @frame

    assert_select "turbo-frame##{GameRoomHelper::SHEET_FRAME}" do
      assert_select "h2#character-sheet-dialog-title", text: "Changer mes sorts"
      assert_select "input[type=checkbox][name=?][value=fire-bolt][checked]", "character[spell_keys][]"
      assert_select "dialog#spell-choice-details-dialog"
      assert_select "button[data-action='frame-dialog#close']", text: "Annuler"
    end
  end

  test "the spells changed are saved, the room refreshed and the change written in the chat" do
    sign_in @player
    patch game_table_spell_choice_path(@game_table),
          params: { character: { spell_keys: ["", "light", "magic-missile"] } }, headers: @frame

    assert_response :success
    assert_match(/<turbo-stream action="refresh"/, response.body)
    assert_equal %w[light magic-missile], @character.reload.spells.pluck("key")
    event = @game_table.chat_messages.last
    assert_equal "spells_changed", event.event_key
    assert_equal "+ Lumière · − Trait de feu", event.event_params["changes"]
  end

  test "too many spells in a group are refused, the list comes back with its error" do
    sign_in @player
    patch game_table_spell_choice_path(@game_table),
          params: { character: { spell_keys: %w[fire-bolt light mage-hand] } }, headers: @frame

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Sorts mineurs/
    assert_equal %w[fire-bolt magic-missile], @character.reload.spells.pluck("key")
    assert_empty @game_table.chat_messages
  end

  test "the game master and a character without spells to choose get no list" do
    sign_in @game_master
    get edit_game_table_spell_choice_path(@game_table)

    assert_response :not_found

    @character.update_columns(sheet: { "class" => "Guerrier" })
    sign_in @player
    get edit_game_table_spell_choice_path(@game_table)

    assert_response :not_found
  end
end
