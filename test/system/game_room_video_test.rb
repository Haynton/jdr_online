require "application_system_test_case"

# The cameras of the game room (video_island_controller.js) after a Turbo visit from one room to another: the list of
# places is a permanent element (data-turbo-permanent), which Turbo puts back in the new page only after the
# controller has connected. The controller waits for it instead of failing, and then shows its buttons
class GameRoomVideoTest < ApplicationSystemTestCase
  setup do
    @game_master = User.create!(email: "maitre@example.com", username: "maitre", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @first_table, @second_table = ["La Crypte", "Le Donjon"].map do |name|
      GameTable.create!(name: name, status: GameTable::READY_STATUS, sheet_template: sheet_template,
                        template_snapshot: sheet_template.snapshot).tap do |game_table|
        game_table.participations.create!(user: @game_master, role: :game_master)
      end
    end
  end

  test "the cameras keep working after a Turbo visit from one room to another" do
    sign_in_as_game_master
    visit game_table_path(@first_table)
    assert_cameras_shown

    page.execute_script("Turbo.visit(#{game_table_path(@second_table).to_json})")

    assert_selector "h1", text: "Le Donjon"
    assert_cameras_shown
  end

  private

  def sign_in_as_game_master
    visit new_user_session_path
    fill_in "user_email", with: "maitre@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "#side-nav"
  end

  # The pill under the cameras is rendered hidden and shown by the controller once connected
  def assert_cameras_shown
    assert_selector "#game-room-video-places"
    assert_selector "[data-video-island-target=controls]:not([hidden])", visible: :all
  end
end
