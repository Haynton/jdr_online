require "test_helper"
require "turbo/broadcastable/test_helper"

# A token dragged on the board (GameTables::BoardTokens::MovesController): the game master moves any token anywhere
# free; a player their character and its companions, only where a way leads without crossing a wall nor a blocked cell
class BoardTokenMovesTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template:,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    @aria = player_character(@player, "Aria")
    @goblin = @game_table.characters.create!(kind: :monster, name: "Gobelin")
    @tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10, layout: walled_layout)
    BoardMapChanger.new(@game_table, @tavern).call
    @aria_token = @tavern.board_tokens.create!(character: @aria, column: 1, row: 1, hidden: false)
  end

  test "a player moves their character around a wall, live for the table and for the game master" do
    sign_in @player

    game_master_broadcasts = capture_turbo_stream_broadcasts([@game_table, GameTableChannel::GAME_MASTER_AUDIENCE]) do
      players_broadcasts = capture_turbo_stream_broadcasts(@game_table) do
        patch game_table_board_token_move_path(@game_table, @aria_token), params: { column: 8, row: 6 }
      end
      assert_equal 1, players_broadcasts.size
    end

    assert_response :ok
    assert_equal [8, 6], @aria_token.reload.values_at(:column, :row)
    assert_equal 1, game_master_broadcasts.size
  end

  test "a player never reaches a cell walled off, a blocked cell, a token's cell nor a cell outside the grid" do
    @tavern.board_tokens.create!(character: @goblin, column: 3, row: 1)
    sign_in @player

    [[8, 1], [2, 2], [3, 1], [10, 1], ["deux", 1]].each do |column, row|
      patch game_table_board_token_move_path(@game_table, @aria_token), params: { column:, row: }
      assert_response :unprocessable_content, [column, row].inspect
    end
    assert_equal [1, 1], @aria_token.reload.values_at(:column, :row)
  end

  test "a player moves the companions of their character, never another token" do
    wolf = @game_table.characters.create!(kind: :companion, name: "Loup", owner_character: @aria)
    wolf_token = @tavern.board_tokens.create!(character: wolf, column: 1, row: 3)
    other_token = @tavern.board_tokens.create!(character: player_character(create_user("autre"), "Brann"),
                                               column: 1, row: 5)
    goblin_token = @tavern.board_tokens.create!(character: @goblin, column: 1, row: 7)
    sign_in @player

    patch game_table_board_token_move_path(@game_table, wolf_token), params: { column: 2, row: 3 }
    assert_response :ok
    [other_token, goblin_token].each do |token|
      sign_in @player
      patch game_table_board_token_move_path(@game_table, token), params: { column: 3, row: 3 }
      assert_response :not_found
    end
  end

  test "the game master moves any token anywhere free, through walls and onto blocked cells" do
    goblin_token = @tavern.board_tokens.create!(character: @goblin, column: 0, row: 0)
    sign_in @game_master

    patch game_table_board_token_move_path(@game_table, goblin_token), params: { column: 2, row: 2 }
    assert_response :ok
    assert_select "turbo-stream[action=replace][target=game-room-board-tokens-game-master]"
    patch game_table_board_token_move_path(@game_table, @aria_token), params: { column: 8, row: 1 }
    assert_equal [8, 1], @aria_token.reload.values_at(:column, :row)

    patch game_table_board_token_move_path(@game_table, goblin_token), params: { column: 8, row: 1 }
    assert_response :unprocessable_content
  end

  test "the room of a player knows which tokens it moves, and the walls that stop them, without drawing them" do
    wolf = @game_table.characters.create!(kind: :companion, name: "Loup", owner_character: @aria)
    sign_in @player

    get game_table_path(@game_table)

    own_tokens = css_select("#game-room-board-own-tokens").first
    assert_equal [@aria.id, wolf.id], JSON.parse(own_tokens["data-movable-character-ids"])
    board = css_select("#game-room-board-player svg[data-room-board-target=map]").first
    assert_includes JSON.parse(board["data-blocked-sides"]), "4,1|5,1"
    assert_includes JSON.parse(board["data-blocked-cells"]), [2, 2]
    assert_not_includes board["data-map-preview-layout-value"], "blocked"
  end

  test "someone not accepted at the table may not move a token" do
    invited = create_user("invite")
    @game_table.participations.create!(user: invited, role: :player, status: :pending)
    sign_in invited

    patch game_table_board_token_move_path(@game_table, @aria_token), params: { column: 2, row: 1 }

    assert_response :not_found
  end

  private

  # A room of 10 × 10, a stone wall down column 5 but on its last row (the way to the right), the top right closed by
  # a stone wall along row 4, and a cell painted blocked
  def walled_layout
    floors = (0..9).to_a.product((0..9).to_a).to_h { |column, row| ["#{column},#{row}", "room"] }
    (0..8).each { |row| floors["5,#{row}"] = "stone" }
    (6..9).each { |column| floors["#{column},4"] = "stone" }
    MapTemplate::BLANK_LAYOUT.merge("floors" => floors, "blocked" => ["2,2"])
  end

  def player_character(user, name)
    @game_table.participations.create!(user:, role: :player)
               .create_character!(game_table: @game_table, kind: :pc, status: :complete, name:)
  end

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end
end
