require "test_helper"

# The bell of the navigation: what waits for an answer (friend requests, invitations to a table), and its window
class NotificationsTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS)
    @game_table.participations.create!(user: @game_master, role: :game_master)
  end

  test "the bell counts the invitations and the friend requests, with a label for screen readers" do
    invite_player
    Friendship.create!(requester: @game_master, addressee: @player)
    sign_in @player
    get settings_display_path

    assert_select "#notifications-bell a[href=?][data-turbo-frame=notifications][title=?]", notifications_path,
                  "Notifications (2 notifications en attente)" do
      assert_select "span[aria-hidden=true].bg-brass", text: "2"
      assert_select "span.sr-only", text: ", 2 notifications en attente"
    end
    assert_select "dialog#notifications-dialog turbo-frame#notifications"
  end

  test "my tables has no dot any more, and nothing waiting leaves the bell plain" do
    @game_table.update!(status: GameTable::DRAFT_STATUS)
    invite_player
    sign_in @player
    get game_tables_path

    assert_select "#side-nav a[href=?][title=?]", game_tables_path, "Mes tables"
    assert_select "#notifications-bell a[title=?]", "Notifications"
    assert_select "#side-nav .bg-brass", count: 0
  end

  test "past nine notifications, the dot shows 9+" do
    10.times { |table_number| invite_player(GameTable.create!(name: "Table #{table_number}", status: "ready")) }
    sign_in @player
    get settings_display_path

    assert_select "#notifications-bell span[aria-hidden=true].bg-brass", text: "9+"
    assert_select "#notifications-bell span.sr-only", text: ", 10 notifications en attente"
  end

  test "the window lists the notifications, the most recent first, with their answers" do
    invite_player
    friendship = Friendship.create!(requester: @game_master, addressee: @player)
    sign_in @player
    get notifications_path, headers: { "Turbo-Frame" => "notifications" }

    assert_select "turbo-frame#notifications" do
      assert_select "h2#notifications-dialog-title", text: "Notifications"
      assert_select "li", count: 2
      assert_select "li:first-child", text: /Julien veut devenir votre ami/
      assert_select "li:first-child form[action=?] button", settings_friendship_path(friendship), text: "Accepter"
      assert_select "li:last-child", text: /Julien vous invite à la table « La Crypte »/
      assert_select "li:last-child form[action=?][data-turbo-frame=_top]",
                    game_table_invitation_answer_path(@game_table)
      assert_select "turbo-stream[action=replace][target=notifications-bell]"
    end
  end

  test "answered from the window, a friend request or a declined invitation comes back to the window" do
    invite_player
    friendship = Friendship.create!(requester: @game_master, addressee: @player)
    sign_in @player

    patch settings_friendship_path(friendship), headers: { "Turbo-Frame" => "notifications" }
    assert_redirected_to notifications_path
    assert @player.friend?(@game_master)

    delete game_table_invitation_answer_path(@game_table), headers: { "Turbo-Frame" => "notifications" }
    assert_redirected_to notifications_path
    assert_not @game_table.participations.exists?(user: @player)
  end

  test "opened directly, the notifications are a page, empty when nothing waits" do
    sign_in @player
    get notifications_path

    assert_select "main h1", text: "Notifications"
    assert_select "p", text: "Rien en attente pour l'instant."
    assert_select "dialog#notifications-dialog", count: 0
  end

  private

  def invite_player(game_table = @game_table)
    game_table.participations.create!(user: @player, role: :player, status: :pending)
  end
end
