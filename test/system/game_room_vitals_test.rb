require "application_system_test_case"

# The hit points of a player's character changed by the game master in their quick sheet: saved, and shown at once in
# the panel « Ma fiche » of the player (GameTableChannel). Two browsers, one per person
class GameRoomVitalsLiveTest < ApplicationSystemTestCase
  VITAL_FIELDS = [
    { "key" => "hp", "label" => "Points de vie", "type" => "resource", "receives_damage" => true,
      "at_creation" => false, "section" => "Notes" },
    { "key" => "temp_hp", "label" => "PV temporaires", "abbreviation" => "PV temp.", "type" => "resource",
      "absorbs_damage_for" => "hp", "at_creation" => false, "section" => "Notes" }
  ].freeze

  setup do
    sheet_template = EquipmentSpellsTemplateBuilder.create_template(extra_fields: VITAL_FIELDS)
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: create_user("maitre"), role: :game_master)
    participation = @game_table.participations.create!(user: create_user("joueur"), role: :player)
    @character = participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria",
                                                 sheet: { "hp" => { "current" => 10, "max" => 12 } })
  end

  test "the game master takes hit points away, the player sees them go at once" do
    using_session(:player) do
      open_room_as("joueur")
      find("a[data-panel-id=game-room-panel-character]").click
      assert_selector "#character-#{@character.id}-hit-points", text: "10/12"
    end
    open_room_as("maitre")
    find("button[data-combat-strip-target=portrait][aria-label^=Aria]").click
    within("#combat-sheet-character-#{@character.id}") do
      find("button[aria-label='Ajouter 1 à PV temporaires de Aria']").click
      assert_selector "#character-#{@character.id}-temporary-hit-points", text: "1"
      3.times do
        find("button[aria-label='Retirer 1 PV à Aria']").click
        sleep 0.2
      end
      assert_selector "#character-#{@character.id}-hit-points", text: "8/12"
    end

    using_session(:player) do
      assert_selector "#character-#{@character.id}-hit-points", text: "8/12"
      assert_selector "#character-#{@character.id}-temporary-hit-points", text: "0"
    end
    assert_equal 8, @character.reload.sheet.dig("hp", "current")
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
  end
end
