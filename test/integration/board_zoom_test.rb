require "test_helper"

class BoardZoomTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
    @tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10,
                                            layout: MapTemplate::BLANK_LAYOUT.merge("floors" => { "1,1" => "room" }))
  end

  test "an empty board has no zoom" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "[data-controller=board-zoom]", count: 0
  end

  test "everyone at the table gets the zoom of the map on the board" do
    @game_table.update!(board_game_map: @tavern)

    [@player, @game_master].each do |person|
      sign_in person
      get game_table_path(@game_table)

      assert_select "[data-controller=board-zoom][data-board-zoom-columns-value='10']" \
                    "[data-board-zoom-rows-value='10']" do
        assert_select "svg[data-board-zoom-target=map][data-action*='wheel->board-zoom#zoomOrMoveWithWheel']"
        assert_select "[role=group][aria-label='Zoom de la carte'][hidden] button", count: 3
      end
    end
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end
end
