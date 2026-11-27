require "application_system_test_case"

class BoardMapLiveTest < ApplicationSystemTestCase
  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
    tavern_layout = MapTemplate::BLANK_LAYOUT.merge("floors" => { "1,1" => "room", "2,1" => "room" })
    @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10, layout: tavern_layout)
  end

  test "the map put on the board by the game master shows live in the room of the player" do
    using_session(:player) do
      open_room_as("joueur", streams: 2) # the stream of the table, and the player's own (their hidden token)
      assert_text "Le MJ n'a pas encore posé de carte sur le plateau."
    end
    open_room_as("maitre", streams: 2) # the stream of the table, and the one of the game master (hidden rolls)

    find("a[aria-label=Cartes]").click
    find("button[aria-label='Placer Taverne sur le plateau']").click

    assert_selector "#game-room-board-game-master svg[aria-label=Taverne] g", visible: :all
    assert_selector "#game-room-map-list button[aria-pressed=true]", text: "Retirer"
    using_session(:player) { assert_selector "#game-room-board-player svg[aria-label=Taverne] g", visible: :all }

    find("button[aria-label='Retirer Taverne du plateau']").click

    assert_text "Placez une carte sur le plateau depuis le panneau Cartes"
    using_session(:player) { assert_text "Le MJ n'a pas encore posé de carte sur le plateau." }

    find("button[aria-label='Placer Taverne sur le plateau']").click
    assert_selector "#game-room-board-game-master svg[aria-label=Taverne]"
    assert_selector "svg#map-patterns pattern#map-pattern-wood", visible: :all, count: 1
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end

  def open_room_as(username, streams:)
    visit new_user_session_path
    fill_in "user_email", with: "#{username}@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "#side-nav"
    visit game_table_path(@game_table)
    assert_selector "turbo-cable-stream-source[connected]", visible: false, count: streams
  end
end
