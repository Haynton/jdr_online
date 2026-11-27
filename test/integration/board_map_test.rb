require "test_helper"
require "turbo/broadcastable/test_helper"

class BoardMapTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
    @goblin = @game_table.characters.create!(kind: :monster, name: "Gobelin", visible_to_players: false)
    @tavern = drawn_map_of(@game_table, "Taverne")
  end

  test "the game master puts a map on the board, then takes it off" do
    sign_in @game_master

    patch game_table_board_map_path(@game_table), params: { game_map_id: @tavern.id }, as: :turbo_stream
    assert_response :ok
    assert_equal @tavern, @game_table.reload.board_game_map
    assert_select "turbo-stream[action=replace][target=game-room-board-game-master] svg[aria-label=Taverne]"
    assert_select "turbo-stream[action=replace][target=game-room-map-list] button[aria-pressed=true]", text: "Retirer"

    delete game_table_board_map_path(@game_table), as: :turbo_stream
    assert_response :ok
    assert_nil @game_table.reload.board_game_map
  end

  test "without JavaScript, the game master comes back to the room" do
    sign_in @game_master

    patch game_table_board_map_path(@game_table), params: { game_map_id: @tavern.id }

    assert_redirected_to game_table_path(@game_table)
    assert_equal @tavern, @game_table.reload.board_game_map
  end

  test "a player may not put a map on the board" do
    sign_in @player

    patch game_table_board_map_path(@game_table), params: { game_map_id: @tavern.id }, as: :turbo_stream

    assert_response :not_found
    assert_nil @game_table.reload.board_game_map
  end

  test "a map of another table or an image alone are refused" do
    other_table = GameTable.create!(name: "Le Phare", status: GameTable::READY_STATUS)
    image_alone = @game_table.game_maps.create!(name: "Plan", image: image_file)

    [drawn_map_of(other_table, "Phare"), image_alone].each do |refused_map|
      sign_in @game_master
      patch game_table_board_map_path(@game_table), params: { game_map_id: refused_map.id }, as: :turbo_stream

      assert_response :not_found
    end
    assert_nil @game_table.reload.board_game_map
  end

  test "the new board goes live to the players only: the game master gets it in his answer" do
    sign_in @game_master

    assert_turbo_stream_broadcasts(@game_table, count: 1) do
      assert_no_turbo_stream_broadcasts([@game_table, GameTableChannel::GAME_MASTER_AUDIENCE]) do
        patch game_table_board_map_path(@game_table), params: { game_map_id: @tavern.id }, as: :turbo_stream
      end
    end
  end

  test "a map played on its picture goes live with an address of the picture on the site" do
    picture_map = @game_table.game_maps.create!(name: "Grotte", columns: 10, rows: 10, image: image_file,
                                                layout: MapTemplate::BLANK_LAYOUT.merge("mode" => "picture"))
    sign_in @game_master

    broadcasts = capture_turbo_stream_broadcasts(@game_table) do
      patch game_table_board_map_path(@game_table), params: { game_map_id: picture_map.id }, as: :turbo_stream
    end

    picture_url = broadcasts.first.at_css("svg")["data-map-preview-picture-url-value"]
    assert_match %r{\A/rails/active_storage/}, picture_url
  end

  test "the players see the map on the board, without the tokens nor the blocked zones of the editor" do
    @game_table.update!(board_game_map: @tavern)
    sign_in @player

    get game_table_path(@game_table)

    assert_select "#game-room-board-player svg[aria-label=Taverne]" do |boards|
      layout = JSON.parse(boards.first["data-map-preview-layout-value"])
      assert_equal({ "1,1" => "room", "2,1" => "room" }, layout["floors"])
      assert_nil layout["tokens"]
      assert_nil layout["blocked"]
      assert_equal "{}", boards.first["data-map-preview-token-characters-value"]
    end
    assert_select "#game-room-board-game-master", count: 0
  end

  test "the game master sees the map with what stops a token, its tokens apart from the drawing" do
    BoardMapChanger.new(@game_table, @tavern).call
    sign_in @game_master

    get game_table_path(@game_table)

    assert_select "#game-room-board-game-master svg[data-map-preview-show-natural-blocks-value=true]" do |boards|
      assert_nil JSON.parse(boards.first["data-map-preview-layout-value"])["tokens"]
    end
    assert_select "#game-room-board-tokens-game-master[data-tokens*=Gobelin]"
    assert_select "#game-room-board-player", count: 0
  end

  test "an empty board says who puts a map on it" do
    sign_in @player
    get game_table_path(@game_table)
    assert_select "#game-room-board-player p", text: /Le MJ n'a pas encore posé de carte/

    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "#game-room-board-game-master p", text: /Placez une carte sur le plateau/
  end

  test "the room listens to the stream of the table once, outside the chat" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "turbo-cable-stream-source[channel=GameTableChannel]", count: 1
    assert_select "#game-room-chat-body turbo-cable-stream-source", count: 0
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end

  def drawn_map_of(game_table, name)
    layout = MapTemplate::BLANK_LAYOUT.merge("floors" => { "1,1" => "room", "2,1" => "room" }, "blocked" => ["2,1"])
    layout["tokens"] = [{ "character_id" => @goblin.id, "column" => 1, "row" => 1 }] if game_table == @game_table
    game_table.game_maps.create!(name:, columns: 10, rows: 10, layout:)
  end

  def image_file
    Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/map.png"), "image/png")
  end
end
