require "application_system_test_case"

class MapEditorTokenStateTest < ApplicationSystemTestCase
  setup do
    game_master = User.create!(email: "maitre@example.com", username: "maitre", password: TEST_PASSWORD, locale: "fr")
    player = User.create!(email: "joueur@example.com", username: "joueur", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template:,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: game_master, role: :game_master)
    @aria = @game_table.participations.create!(user: player, role: :player)
                       .create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
    goblin = @game_table.characters.create!(kind: :monster, name: "Gobelin")
    floors = (0..9).to_a.product((0..9).to_a).to_h { |column, row| ["#{column},#{row}", "room"] }
    tokens = [{ "character_id" => goblin.id, "column" => 4, "row" => 4 }]
    @tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10,
                                            layout: MapTemplate::BLANK_LAYOUT.merge("floors" => floors,
                                                                                    "tokens" => tokens))
    sign_in_as_game_master
  end

  test "with no tool in hand, a click on a token chooses whether it starts hidden from the players" do
    visit edit_game_table_game_map_path(@game_table, @tavern)
    board = find("svg[data-map-editor-target=board]")
    board.right_click

    click_board_at_cell(4, 4)
    within("[data-map-editor-target=tokenMenu]") do
      assert_text "Gobelin"
      assert_selector "[role=menuitemradio][aria-checked=true]", text: "Caché aux joueurs au départ"
      click_on "Montré aux joueurs au départ"
    end

    assert_no_selector "[data-map-editor-target=tokenMenu]"
    wait_for_saved_token { |token| token["hidden"] == false }

    find("[data-map-editor-target=undoButton]").click
    wait_for_saved_token { |token| token["hidden"] != false }
  end

  test "a player character has one token on the map: put elsewhere, it moves there, shown to the players at first" do
    visit edit_game_table_game_map_path(@game_table, @tavern)
    find("[role=tab]", text: "Jetons", match: :first).click
    within("section[aria-labelledby$=player-tokens-title]", match: :first) { assert_text "Joué par joueur" }
    find("button[data-tool-kind=token][data-tool-key='#{@aria.id}']", match: :first).click

    click_board_at_cell(1, 1)
    click_board_at_cell(2, 2)

    50.times do
      break if aria_token_cells == [[2, 2, false]]

      sleep 0.1
    end
    assert_equal [[2, 2, false]], aria_token_cells
  end

  private

  def aria_token_cells
    aria_tokens = @tavern.reload.layout["tokens"].select { |token| token["character_id"] == @aria.id }
    aria_tokens.map { |token| token.values_at("column", "row", "hidden") }
  end

  def sign_in_as_game_master
    visit new_user_session_path
    fill_in "user_email", with: "maitre@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "#side-nav"
  end

  def click_board_at_cell(column, row)
    board = find("svg[data-map-editor-target=board]")
    x, y = page.evaluate_script(<<~JS, board.native, column, row)
      (function (board, column, row) {
        const point = new DOMPoint((column + 0.5) * 24, (row + 0.5) * 24).matrixTransform(board.getScreenCTM())
        return [point.x, point.y]
      })(arguments[0], arguments[1], arguments[2])
    JS
    page.driver.browser.action.move_to_location(x.round, y.round).click.perform
  end

  def wait_for_saved_token
    50.times do
      return if yield(@tavern.reload.layout["tokens"].first)

      sleep 0.1
    end
    flunk "the token was not saved as expected: #{@tavern.layout['tokens'].first}"
  end
end
