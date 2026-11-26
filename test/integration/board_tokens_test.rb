require "test_helper"
require "turbo/broadcastable/test_helper"

class BoardTokensTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template:,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
    @goblin = @game_table.characters.create!(kind: :monster, name: "Gobelin", visible_to_players: false)
    @tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10,
                                            layout: MapTemplate::BLANK_LAYOUT.merge("floors" => { "1,1" => "room" }))
    BoardMapChanger.new(@game_table, @tavern).call
  end

  test "the game master puts a creature on the board, hidden from the players" do
    sign_in @game_master

    players_broadcasts = capture_turbo_stream_broadcasts(@game_table) do
      post game_table_board_tokens_path(@game_table), params: { character_id: @goblin.id, column: 3, row: 4 }
    end

    assert_response :ok
    token = @tavern.board_tokens.sole
    assert_equal [@goblin, 3, 4, true], [token.character, token.column, token.row, token.hidden]
    assert_select "turbo-stream[action=replace][target=game-room-board-tokens-game-master]"
    assert_includes response.body, "Gobelin"
    assert_equal 1, players_broadcasts.size
    assert_not_includes players_broadcasts.first.to_html, "Gobelin"
  end

  test "shown to the players, the creature goes live to them; hidden again, it leaves them" do
    token = @tavern.board_tokens.create!(character: @goblin, column: 1, row: 1)
    sign_in @game_master

    shown = capture_turbo_stream_broadcasts(@game_table) do
      patch game_table_board_token_path(@game_table, token), params: { hidden: false }
    end
    assert_not token.reload.hidden?
    assert_includes shown.first.to_html, "Gobelin"

    hidden = capture_turbo_stream_broadcasts(@game_table) do
      patch game_table_board_token_path(@game_table, token), params: { hidden: true }
    end
    assert_predicate token.reload, :hidden?
    assert_not_includes hidden.first.to_html, "Gobelin"
  end

  test "the game master removes a token, or all the tokens of the board" do
    token = @tavern.board_tokens.create!(character: @goblin, column: 1, row: 1)
    @tavern.board_tokens.create!(character: @goblin, column: 2, row: 1)
    sign_in @game_master

    delete game_table_board_token_path(@game_table, token)
    assert_equal 1, @tavern.board_tokens.count

    post game_table_board_clearing_path(@game_table), as: :turbo_stream
    assert_response :ok
    assert_empty @tavern.board_tokens.reload
    assert_select "turbo-stream[action=replace][target=game-room-map-list]"
  end

  test "without JavaScript, removing all the tokens comes back to the room" do
    sign_in @game_master

    post game_table_board_clearing_path(@game_table)

    assert_redirected_to game_table_path(@game_table)
  end

  test "a player may not put, show nor remove a token" do
    token = @tavern.board_tokens.create!(character: @goblin, column: 1, row: 1)
    sign_in @player

    post game_table_board_tokens_path(@game_table), params: { character_id: @goblin.id, column: 2, row: 2 }
    assert_response :not_found
    sign_in @player
    patch game_table_board_token_path(@game_table, token), params: { hidden: false }
    assert_response :not_found
    assert_predicate token.reload, :hidden?
  end

  test "a character of another table, a cell outside the grid or a board without a map are refused" do
    other_table = GameTable.create!(name: "Le Phare", status: GameTable::READY_STATUS)
    stranger = other_table.characters.create!(kind: :monster, name: "Loup")
    sign_in @game_master

    post game_table_board_tokens_path(@game_table), params: { character_id: stranger.id, column: 1, row: 1 }
    assert_response :not_found
    sign_in @game_master
    post game_table_board_tokens_path(@game_table), params: { character_id: @goblin.id, column: 10, row: 1 }
    assert_response :unprocessable_content
    @tavern.board_tokens.create!(character: @goblin, column: 5, row: 5)
    post game_table_board_tokens_path(@game_table), params: { character_id: @goblin.id, column: 5, row: 5 }
    assert_response :unprocessable_content
    @tavern.board_tokens.delete_all

    BoardMapChanger.new(@game_table, nil).call
    sign_in @game_master
    post game_table_board_tokens_path(@game_table), params: { character_id: @goblin.id, column: 1, row: 1 }
    assert_response :not_found
    assert_empty @tavern.board_tokens.reload
  end

  test "a player sees only the tokens shown, in the board and in the strip of the fighters" do
    @tavern.board_tokens.create!(character: @goblin, column: 1, row: 1)
    innkeeper = @game_table.characters.create!(kind: :npc, name: "Aubergiste")
    @tavern.board_tokens.create!(character: innkeeper, column: 2, row: 1, hidden: false)

    sign_in @player
    get game_table_path(@game_table)
    assert_select "#game-room-board-tokens-player[data-tokens*=Aubergiste]:not([data-tokens*=Gobelin])"
    assert_select "[data-controller=combat-strip]", text: /Gobelin/, count: 0

    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "#game-room-board-tokens-game-master[data-tokens*=Aubergiste][data-tokens*=Gobelin]"
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end
end
