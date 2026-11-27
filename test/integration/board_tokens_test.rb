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
    @aria = participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
    @goblin = @game_table.characters.create!(kind: :monster, name: "Gobelin", visible_to_players: false)
    @tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10,
                                            layout: MapTemplate::BLANK_LAYOUT.merge("floors" => room_floors))
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

  test "the game master puts a player character, shown at once, and only once on the map" do
    sign_in @game_master

    players_broadcasts = capture_turbo_stream_broadcasts(@game_table) do
      post game_table_board_tokens_path(@game_table), params: { character_id: @aria.id, column: 2, row: 2 }
    end
    assert_response :ok
    assert_not @tavern.board_tokens.sole.hidden?
    assert_includes players_broadcasts.first.to_html, "Aria"

    post game_table_board_tokens_path(@game_table), params: { character_id: @aria.id, column: 3, row: 2 }
    assert_response :unprocessable_content
    assert_equal 1, @tavern.board_tokens.count
  end

  test "hidden by the game master, a player character leaves the others but stays, faded, for its own player" do
    token = @tavern.board_tokens.create!(character: @aria, column: 2, row: 2, hidden: false)
    participation = @aria.participation
    sign_in @game_master

    own_stream = capture_turbo_stream_broadcasts([@game_table, participation]) do
      shared = capture_turbo_stream_broadcasts(@game_table) do
        patch game_table_board_token_path(@game_table, token), params: { hidden: true }
      end
      assert_not_includes shared.first.to_html, "Aria"
    end
    assert_equal 1, own_stream.size
    assert_equal([[token.id, true]], own_tokens_in(own_stream.first).map { |own| own.values_at("id", "hidden") })
  end

  test "the room of a player holds their own hidden token, and never the one of another player" do
    @tavern.board_tokens.create!(character: @aria, column: 2, row: 2, hidden: true)
    other_player = create_user("autre")
    @game_table.participations.create!(user: other_player, role: :player)
               .create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Brann")

    sign_in @player
    get game_table_path(@game_table)
    assert_equal ["Aria"], JSON.parse(css_select("#game-room-board-own-tokens").first["data-tokens"]).pluck("name")

    sign_in other_player
    get game_table_path(@game_table)
    assert_equal [], JSON.parse(css_select("#game-room-board-own-tokens").first["data-tokens"])
  end

  test "a player character shows its picture and takes no letter: the next creature still gets A" do
    @aria.avatar.attach(fixture_file_upload("map.png", "image/png"))
    @tavern.board_tokens.create!(character: @aria, column: 2, row: 2, hidden: false)
    @tavern.board_tokens.create!(character: @goblin, column: 3, row: 2)
    sign_in @game_master

    get game_table_path(@game_table)

    aria_token, goblin_token = JSON.parse(css_select("#game-room-board-tokens-game-master").first["data-tokens"])
    assert_match %r{\A/rails/active_storage/}, aria_token["picture"]
    assert_equal ["", "A"], [aria_token["letter"], goblin_token["letter"]]
  end

  test "a player changes or removes the picture of their character: its token changes at once for the whole table" do
    @tavern.board_tokens.create!(character: @aria, column: 2, row: 2, hidden: false)
    sign_in @player

    game_master_broadcasts = capture_turbo_stream_broadcasts([@game_table, GameTableChannel::GAME_MASTER_AUDIENCE]) do
      players_broadcasts = capture_turbo_stream_broadcasts(@game_table) do
        picture = fixture_file_upload("map.png", "image/png")
        patch character_avatar_path(@aria), params: { character: { avatar: picture } }, as: :turbo_stream
      end
      assert_includes players_broadcasts.first.to_html, "/rails/active_storage/"
    end
    assert_equal 1, game_master_broadcasts.size

    removed = capture_turbo_stream_broadcasts(@game_table) { delete character_avatar_path(@aria), as: :turbo_stream }
    assert_not_includes removed.first.to_html, "/rails/active_storage/"
  end

  test "a player character put, removed then put again keeps its name alone, never « Aria 2 »" do
    sign_in @game_master

    post game_table_board_tokens_path(@game_table), params: { character_id: @aria.id, column: 2, row: 2 }
    delete game_table_board_token_path(@game_table, @tavern.board_tokens.sole)
    players_broadcasts = capture_turbo_stream_broadcasts(@game_table) do
      post game_table_board_tokens_path(@game_table), params: { character_id: @aria.id, column: 3, row: 2 }
    end

    assert_response :ok
    assert_nil @tavern.board_tokens.sole.number
    shown_tokens = JSON.parse(players_broadcasts.first.at_css("[data-tokens]")["data-tokens"])
    assert_equal([["Aria", nil]], shown_tokens.map { |token| token.values_at("name", "number") })
  end

  test "a player character still in creation cannot be put on the board" do
    newcomer = create_user("nouveau")
    draft = @game_table.participations.create!(user: newcomer, role: :player)
                       .create_character!(game_table: @game_table, kind: :pc, status: :draft, name: "Brouillon")
    sign_in @game_master

    post game_table_board_tokens_path(@game_table), params: { character_id: draft.id, column: 2, row: 2 }

    assert_response :not_found
  end

  test "a player removed from the table: their token leaves the board of the others at once" do
    @tavern.board_tokens.create!(character: @aria, column: 2, row: 2, hidden: false)

    players_broadcasts = capture_turbo_stream_broadcasts(@game_table) do
      @game_table.participations.find_by!(user: @player).destroy!
    end

    assert_empty @tavern.board_tokens.reload
    assert_equal 1, players_broadcasts.size
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

  test "the game master renames a token, live for the players when it is shown; a player may not" do
    token = @tavern.board_tokens.create!(character: @goblin, column: 1, row: 1, hidden: false)
    sign_in @game_master

    renamed = capture_turbo_stream_broadcasts(@game_table) do
      patch game_table_board_token_path(@game_table, token), params: { name: "Chef gobelin" }
    end
    assert_response :ok
    assert_equal ["Chef gobelin", false], [token.reload.name, token.hidden?]
    assert_includes renamed.first.to_html, "Chef gobelin"

    patch game_table_board_token_path(@game_table, token), params: { name: "a" * 61 }
    assert_response :unprocessable_content
    assert_equal "Chef gobelin", token.reload.name

    sign_in @player
    patch game_table_board_token_path(@game_table, token), params: { name: "Gobelin peureux" }
    assert_response :not_found
    assert_equal "Chef gobelin", token.reload.name
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
    @tavern.update!(layout: @tavern.layout.merge("blocked" => ["6,6"]))
    post game_table_board_tokens_path(@game_table), params: { character_id: @goblin.id, column: 6, row: 6 }
    assert_response :unprocessable_content

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

  test "a player sees the numbers of the tokens shown, given when they were shown, never a hidden one" do
    hidden, first, second = [1, 2, 3].map { |column| @tavern.board_tokens.create!(character: @goblin, column:, row: 1) }
    first.update!(hidden: false)
    sign_in @player

    get game_table_path(@game_table)
    assert_equal [nil], player_token_numbers

    second.update!(hidden: false)
    get game_table_path(@game_table)
    assert_equal [nil, 2], player_token_numbers
    assert_not_includes player_tokens.pluck("id"), hidden.id
    assert_equal [nil, nil], player_tokens.pluck("letter")

    sign_in @game_master
    get game_table_path(@game_table)
    game_master_tokens = JSON.parse(css_select("#game-room-board-tokens-game-master").first["data-tokens"])
    assert_equal %w[A B C], game_master_tokens.pluck("letter")
  end

  private

  def own_tokens_in(broadcast)
    JSON.parse(broadcast.at_css("[data-tokens]")["data-tokens"])
  end

  def player_tokens
    JSON.parse(css_select("#game-room-board-tokens-player").first["data-tokens"])
  end

  def player_token_numbers
    player_tokens.pluck("number")
  end

  def room_floors
    (0..9).to_a.product((0..9).to_a).to_h { |column, row| ["#{column},#{row}", "room"] }
  end

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end
end
