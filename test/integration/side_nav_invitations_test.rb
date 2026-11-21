require "test_helper"

class SideNavInvitationsTest < ActionDispatch::IntegrationTest
  setup do
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS)
    @game_table.participations.create!(user: game_master, role: :game_master)
  end

  test "my tables in the navigation shows how many invitations wait, with a label for screen readers" do
    invite_player
    sign_in @player
    get settings_display_path

    assert_select "#side-nav a[href=?][title=?]", game_tables_path, "Mes tables (1 invitation en attente)" do
      assert_select "span[aria-hidden=true].bg-brass", text: "1"
      assert_select "span.sr-only", text: ", 1 invitation en attente"
    end
  end

  test "without an invitation to answer, my tables in the navigation has no dot" do
    @game_table.update!(status: GameTable::DRAFT_STATUS)
    invite_player
    sign_in @player
    get game_tables_path

    assert_select "#side-nav a[href=?][title=?]", game_tables_path, "Mes tables"
    assert_select "#side-nav .bg-brass", count: 0
  end

  test "past nine invitations, the dot shows 9+" do
    10.times { |table_number| invite_player(GameTable.create!(name: "Table #{table_number}", status: "ready")) }
    sign_in @player
    get settings_display_path

    assert_select "#side-nav span[aria-hidden=true].bg-brass", text: "9+"
    assert_select "#side-nav span.sr-only", text: ", 10 invitations en attente"
  end

  private

  def invite_player(game_table = @game_table)
    game_table.participations.create!(user: @player, role: :player, status: :pending)
  end
end
