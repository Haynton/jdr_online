require "application_system_test_case"

# A token dragged on the board with the mouse: it follows the pointer step by step, a wall stops a player's token, a
# bubble says the distance in the length of a cell of the template; the others see the new place once it is dropped
class BoardTokenMovesLiveTest < ApplicationSystemTestCase
  setup do
    create_user("maitre")
    player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    sheet_template.update!(character_fields: sheet_template.character_fields.merge(
      "grid" => { "cell_length" => 1.5, "unit" => "m" }
    ))
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template:,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: User.find_by(username: "maitre"), role: :game_master)
    aria = @game_table.participations.create!(user: player, role: :player)
                      .create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
    tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10, layout: walled_layout)
    BoardMapChanger.new(@game_table, tavern).call
    @aria_token = tavern.board_tokens.create!(character: aria, column: 1, row: 1, hidden: false)
  end

  test "a player drags their character, sees the distance, and the game master sees it arrive" do
    using_session(:game_master) { open_room_as("maitre") }
    open_room_as("joueur")

    press_and_move(from: [1, 1], to: [3, 1])
    assert_selector "[data-room-board-target=moveBubble]", text: "3 m"
    release_pointer

    assert_no_selector "[data-room-board-target=moveBubble]"
    wait_for_token_at(3, 1)
    using_session(:game_master) do
      assert_selector "#game-room-board-game-master [data-board-token-id='#{@aria_token.id}']", visible: :all
      assert_equal [3, 1], token_cell_shown("#game-room-board-tokens-game-master")
    end
  end

  test "dragged straight at a wall, a player's token stops just before it" do
    open_room_as("joueur")

    press_and_move(from: [1, 1], to: [8, 1])
    release_pointer

    wait_for_token_at(4, 1)
  end

  private

  # A room of 10 × 10, a stone wall down column 5 but on its last row
  def walled_layout
    floors = (0..9).to_a.product((0..9).to_a).to_h { |column, row| ["#{column},#{row}", "room"] }
    (0..8).each { |row| floors["5,#{row}"] = "stone" }
    MapTemplate::BLANK_LAYOUT.merge("floors" => floors)
  end

  def press_and_move(from:, to:)
    start = screen_point(*from)
    arrival = screen_point(*to)
    page.driver.browser.action.move_to_location(*start).click_and_hold
        .move_to_location(start.first + 10, start.last).move_to_location(*arrival).perform
  end

  def release_pointer
    page.driver.browser.action.release.perform
  end

  def screen_point(column, row)
    board = find("svg[data-room-board-target=map]")
    page.evaluate_script(<<~JS, board.native, column, row).map(&:round)
      (function (board, column, row) {
        const point = new DOMPoint((column + 0.5) * 24, (row + 0.5) * 24).matrixTransform(board.getScreenCTM())
        return [point.x, point.y]
      })(arguments[0], arguments[1], arguments[2])
    JS
  end

  def wait_for_token_at(column, row)
    50.times do
      return if @aria_token.reload.values_at(:column, :row) == [column, row]

      sleep 0.1
    end
    flunk "the token is at #{@aria_token.values_at(:column, :row)}, not at #{[column, row]}"
  end

  def token_cell_shown(tokens_selector)
    tokens = JSON.parse(find(tokens_selector, visible: :all)["data-tokens"])
    tokens.find { |token| token["id"] == @aria_token.id }.values_at("column", "row")
  end

  def open_room_as(username)
    visit new_user_session_path
    fill_in "user_email", with: "#{username}@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "#side-nav"
    visit game_table_path(@game_table)
    assert_selector "turbo-cable-stream-source[connected]", visible: false, minimum: 2
    assert_selector "[data-board-zoom-target=zoomButtons]"
  end

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end
end
