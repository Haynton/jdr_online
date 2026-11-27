require "application_system_test_case"

class BoardZoomLiveTest < ApplicationSystemTestCase
  setup do
    @game_master = User.create!(email: "maitre@example.com", username: "maitre", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    @game_table.characters.create!(kind: :monster, name: "Gobelin", visible_to_players: false)
    floors = (0..19).to_a.product((0..14).to_a).to_h { |column, row| ["#{column},#{row}", "room"] }
    tavern = @game_table.game_maps.create!(name: "Taverne", columns: 20, rows: 15,
                                           layout: MapTemplate::BLANK_LAYOUT.merge("floors" => floors))
    @game_table.update!(board_game_map: tavern)
    sign_in_as_game_master
  end

  test "the buttons zoom in and out, and show the whole map again" do
    open_room
    whole_map = board_view_box

    click_zoom_button "Zoomer"
    assert_operator board_view_box[2], :<, whole_map[2]

    click_zoom_button "Afficher toute la carte"
    assert_equal whole_map, board_view_box
  end

  test "the wheel of a mouse zooms around the pointer" do
    open_room
    whole_map = board_view_box

    turn_wheel_over("#game-room-board-game-master svg[data-board-zoom-target=map]")

    assert_operator board_view_box[2], :<, whole_map[2]
  end

  test "a left drag only selects; Space, the hand, H or the wheel button move the map" do
    open_room
    click_zoom_button "Zoomer"
    click_zoom_button "Zoomer"
    zoomed_in = board_view_box

    drag_board_by(-150)
    assert_equal zoomed_in, board_view_box

    drag_board_by(-100, holding: :space)
    after_space = board_view_box
    assert_operator after_space[0], :>, zoomed_in[0]

    click_zoom_button "Déplacer la carte"
    assert_selector "[data-board-zoom-target=handButton][aria-pressed=true]"
    drag_board_by(-100)
    after_hand = board_view_box
    assert_operator after_hand[0], :>, after_space[0]

    find("body").send_keys("h")
    assert_selector "[data-board-zoom-target=handButton][aria-pressed=false]"
    drag_board_by(-100)
    assert_equal after_hand, board_view_box

    drag_board_by(100, button: :middle)
    assert_operator board_view_box[0], :<, after_hand[0]
  end

  test "the wheel still zooms in the map editor" do
    map_template = @game_master.map_templates.create!(name: "Grotte", columns: 20, rows: 15)
    visit edit_map_template_path(map_template)
    board = find("svg[data-map-editor-target=board]")
    view_box_before = board[:viewBox]

    turn_wheel_over("svg[data-map-editor-target=board]")

    assert_not_equal view_box_before, board[:viewBox]
  end

  private

  def sign_in_as_game_master
    visit new_user_session_path
    fill_in "user_email", with: "maitre@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "#side-nav"
  end

  def open_room
    visit game_table_path(@game_table)
    assert_selector "[data-board-zoom-target=zoomButtons]"
  end

  def board_view_box
    find("#game-room-board-game-master svg[data-board-zoom-target=map]")[:viewBox].split.map(&:to_f)
  end

  def click_zoom_button(label)
    find("[data-board-zoom-target=zoomButtons] button[aria-label='#{label}']").click
  end

  def turn_wheel_over(selector)
    page.execute_script(<<~JS, find(selector))
      const board = arguments[0]
      const box = board.getBoundingClientRect()
      board.dispatchEvent(new WheelEvent("wheel", { deltaY: -3, deltaMode: WheelEvent.DOM_DELTA_LINE, bubbles: true,
                                                    cancelable: true, clientX: box.left + box.width / 2,
                                                    clientY: box.top + box.height / 2 }))
    JS
  end

  def drag_board_by(horizontal_pixels, holding: nil, button: :left)
    board = find("#game-room-board-game-master svg[data-board-zoom-target=map]")
    action = page.driver.browser.action.move_to(board.native)
    action = action.key_down(holding) if holding
    action = action.pointer_down(button).move_by(horizontal_pixels, 0).pointer_up(button)
    action = action.key_up(holding) if holding
    action.perform
  end
end
