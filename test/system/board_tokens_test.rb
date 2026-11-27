require "application_system_test_case"

class BoardTokensLiveTest < ApplicationSystemTestCase
  setup do
    create_user("maitre")
    player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template:,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: User.find_by(username: "maitre"), role: :game_master)
    participation = @game_table.participations.create!(user: player, role: :player)
    participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
    @game_table.characters.create!(kind: :monster, name: "Gobelin", visible_to_players: false)
    floors = (0..9).to_a.product((0..9).to_a).to_h { |column, row| ["#{column},#{row}", "room"] }
    tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10,
                                           layout: MapTemplate::BLANK_LAYOUT.merge("floors" => floors))
    BoardMapChanger.new(@game_table, tavern).call
  end

  test "a creature put by the game master is hidden, then shown live to the player, then removed" do
    using_session(:player) { open_room_as("joueur") }
    open_room_as("maitre")

    find("a[aria-label='PNJ et ennemis']").click
    find("button[aria-label='Placer Gobelin sur la carte']").click
    click_board_at_cell(4, 4)
    assert_no_selector "[data-room-board-target=hint]"

    assert_selector game_master_token("[data-hidden=true]"), visible: :all
    using_session(:player) { assert_no_selector "[data-board-token-id]", visible: :all }

    find(game_master_token, visible: :all).click
    within("[data-room-board-target=tokenMenu]") { click_on "Montrer aux joueurs" }

    assert_selector game_master_token("[data-hidden=false]"), visible: :all
    using_session(:player) { assert_selector "[data-board-token-id][data-name=Gobelin]", visible: :all }

    find(game_master_token, visible: :all).click
    within("[data-room-board-target=tokenMenu]") { click_on "Retirer du plateau" }

    assert_no_selector game_master_token, visible: :all
    using_session(:player) { assert_no_selector "[data-board-token-id]", visible: :all }
  end

  test "one click puts one token, Shift and click put several, never two on a cell, Escape or Placer again stop" do
    open_room_as("maitre")
    find("a[aria-label='PNJ et ennemis']").click
    placer = find("button[aria-label='Placer Gobelin sur la carte']")

    placer.click
    assert_selector "button[aria-label='Placer Gobelin sur la carte'][aria-pressed=true]"
    click_board_at_cell(1, 1, shift: true)
    click_board_at_cell(1, 1, shift: true)
    click_board_at_cell(2, 1, shift: true)
    assert_selector game_master_token, visible: :all, count: 2
    assert_selector "[data-room-board-target=hint]"

    find("body").send_keys(:escape)
    assert_no_selector "[data-room-board-target=hint]"
    assert_selector "button[aria-label='Placer Gobelin sur la carte'][aria-pressed=false]"

    placer.click
    placer.click
    assert_no_selector "[data-room-board-target=hint]"
  end

  test "the game master renames a token from its menu, and the player sees the new name live" do
    goblin = @game_table.characters.find_by(name: "Gobelin")
    @game_table.board_game_map.board_tokens.create!(character: goblin, column: 3, row: 3, hidden: false)
    using_session(:player) { open_room_as("joueur") }
    open_room_as("maitre")

    find(game_master_token, visible: :all).click
    within("[data-room-board-target=tokenMenu]") do
      click_on "Renommer"
      assert_equal "Gobelin", find_field("Nom du jeton")[:placeholder]
      fill_in "Nom du jeton", with: "Chef gobelin"
      click_on "Enregistrer le nom"
    end

    assert_selector game_master_token("[data-name='Chef gobelin']"), visible: :all
    using_session(:player) { assert_selector "[data-board-token-id][data-name='Chef gobelin']", visible: :all }
  end

  test "the game master puts a player character from its quick sheet, once; its menu has no rename" do
    aria = @game_table.characters.find_by(name: "Aria")
    using_session(:player) { open_room_as("joueur") }
    open_room_as("maitre")

    find("button[data-combat-strip-target=portrait][aria-label^=Aria]").click
    within("#combat-sheet-character-#{aria.id}") { click_on "Placer sur la carte" }
    click_board_at_cell(5, 5)

    assert_selector game_master_token("[data-name=Aria][data-hidden=false]"), visible: :all
    using_session(:player) { assert_selector "[data-board-token-id][data-name=Aria]", visible: :all }
    assert_selector "#combat-sheet-character-#{aria.id} button[aria-disabled=true][data-room-board-kind-param=pc]",
                    visible: :all
    find(game_master_token("[data-name=Aria]"), visible: :all).click
    within("[data-room-board-target=tokenMenu]") do
      assert_button "Cacher aux joueurs"
      assert_no_button "Renommer"
    end
  end

  test "hidden by the game master, the token of a player character stays, faded, for its own player, live" do
    aria = @game_table.characters.find_by(name: "Aria")
    @game_table.board_game_map.board_tokens.create!(character: aria, column: 2, row: 2, hidden: false)
    using_session(:player) { open_room_as("joueur") }
    open_room_as("maitre")

    using_session(:player) { assert_selector "[data-board-token-id][data-name=Aria][data-hidden=false]", visible: :all }
    find(game_master_token("[data-name=Aria]"), visible: :all).click
    within("[data-room-board-target=tokenMenu]") { click_on "Cacher aux joueurs" }

    using_session(:player) { assert_selector "[data-board-token-id][data-name=Aria][data-hidden=true]", visible: :all }
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
    assert_selector "turbo-cable-stream-source[connected]", visible: false
    assert_selector "[data-board-zoom-target=zoomButtons]"
  end

  def game_master_token(state = "")
    "#game-room-board-game-master [data-board-token-id]#{state}"
  end

  def click_board_at_cell(column, row, shift: false)
    board = find("#game-room-board-game-master svg[data-room-board-target=map]")
    page.execute_script(<<~JS, board.native, column, row, shift)
      const [board, column, row, shiftKey] = arguments
      const point = new DOMPoint((column + 0.5) * 24, (row + 0.5) * 24).matrixTransform(board.getScreenCTM())
      const position = { bubbles: true, clientX: point.x, clientY: point.y, shiftKey }
      board.dispatchEvent(new PointerEvent("pointerdown", position))
      board.dispatchEvent(new MouseEvent("click", position))
    JS
  end
end
