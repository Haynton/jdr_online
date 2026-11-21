require "test_helper"

class InvitationLinkTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @game_table = GameTable.create!(name: "La Crypte", description: "Une crypte oubliée", cover_image: "dragon",
                                    status: GameTable::READY_STATUS)
    @game_table.participations.create!(user: @game_master, role: :game_master)
  end

  test "a visitor sees the table over its cover, who invites them, with create an account and sign in" do
    get invitation_path(@game_table.invite_token), headers: { "Accept-Language" => "fr" }

    assert_response :success
    assert_select "#side-nav", count: 0
    assert_select "body.bg-page-deep"
    assert_select "section[aria-labelledby=invitation-table-title]" do
      assert_select "img.cover-fade[alt=''][src*='covers/dragon']"
      assert_select "span.text-brass", text: "Invitation"
      assert_select "span", text: "· de Julien"
      assert_select "h1#invitation-table-title", text: "La Crypte"
      assert_select "a[href=?]", new_user_registration_path, text: "Créer un compte"
      assert_select "a[href=?]", new_user_session_path, text: "Se connecter"
    end
  end

  test "after signing in, a visitor comes back to the invitation" do
    get invitation_path(@game_table.invite_token)
    post user_session_path, params: { user: { email: @player.email, password: TEST_PASSWORD } }

    assert_redirected_to invitation_path(@game_table.invite_token)
  end

  test "after signing up, a visitor comes back to the invitation" do
    get invitation_path(@game_table.invite_token)
    post user_registration_path, params: { user: { username: "nouveau", email: "nouveau@example.com",
                                                   password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD } }

    assert_redirected_to invitation_path(@game_table.invite_token)
  end

  test "opening the link changes nothing: joining is a button" do
    sign_in @player

    assert_no_difference("Participation.count") { get invitation_path(@game_table.invite_token) }
    assert_select "#side-nav"
    assert_select "form[action=?] button", join_invitation_path(@game_table.invite_token), text: "Rejoindre la table"
  end

  test "joining makes the user a player of the table, then leads to their character" do
    sign_in @player
    post join_invitation_path(@game_table.invite_token)

    participation = @game_table.participations.find_by!(user: @player)
    assert participation.player?
    assert participation.accepted?
    assert_redirected_to new_game_table_character_path(@game_table)
  end

  test "joining accepts an invitation by username to the same table" do
    invitation = @game_table.participations.create!(user: @player, role: :player, status: :pending)
    sign_in @player
    post join_invitation_path(@game_table.invite_token)

    assert invitation.reload.accepted?
  end

  test "someone already at the table goes to my tables, the game master included" do
    sign_in @game_master
    get invitation_path(@game_table.invite_token)

    assert_redirected_to game_tables_path(table: @game_table.id)
  end

  test "an unknown link, or the link of a draft, no longer works" do
    get invitation_path("unknown-token")
    assert_response :not_found
    assert_select "main h1", text: "This invitation link no longer works"

    @game_table.update!(status: GameTable::DRAFT_STATUS)
    sign_in @player
    post join_invitation_path(@game_table.invite_token)
    assert_response :not_found
    assert_not @game_table.participations.exists?(user: @player)
  end
end
