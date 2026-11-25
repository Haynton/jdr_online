require "test_helper"

class SettingsFriendsTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @luara = User.create!(email: "luara@example.com", username: "Luara", password: TEST_PASSWORD)
    @othna = User.create!(email: "othna@example.com", username: "othna", password: TEST_PASSWORD)
    sign_in @user
  end

  test "the friends section is in the menu, with the form and an empty list" do
    get settings_friends_path

    assert_response :success
    assert_select "nav a[href=?][aria-current=page]", settings_friends_path, text: "Amis"
    assert_select "form[action=?][data-username-suggestions-url-value=?]", settings_friendships_path,
                  settings_friend_suggestions_path do
      assert_select "input#friend_request_username[list=friend-suggestions]"
    end
    assert_select "h3", text: "Demandes reçues", count: 0
    assert_select "p", text: /Pas encore d'amis/
  end

  test "a request sent shows as pending, and can be cancelled" do
    post settings_friendships_path, params: { friend_request: { username: "luara" } }

    assert_redirected_to settings_friends_path
    follow_redirect!
    assert_select ".sr-only [role=status]", text: "Demande d'ami envoyée à Luara."
    assert_select "li", text: /Luara\s*En attente/

    delete settings_friendship_path(Friendship.last)
    assert_not Friendship.exists?
  end

  test "an unknown username is refused under the field" do
    post settings_friendships_path, params: { friend_request: { username: "personne" } }

    assert_response :unprocessable_content
    assert_select "#friend_request_username[aria-invalid=true]"
    assert_select "p", text: /aucun joueur n'a ce pseudo/
  end

  test "a request received is accepted, then the friend can be removed after a question" do
    friendship = Friendship.create!(requester: @luara, addressee: @user)
    get settings_friends_path
    assert_select "h3", text: "Demandes reçues"
    assert_select "form[action=?] button[aria-label=?]", settings_friendship_path(friendship),
                  "Accepter la demande de Luara"

    patch settings_friendship_path(friendship)
    assert @user.friend?(@luara)
    follow_redirect!
    assert_select "h3", text: "Demandes reçues", count: 0
    assert_select "button[data-turbo-confirm][data-confirm-variant=danger]", text: "Retirer"

    delete settings_friendship_path(friendship)
    assert_not @user.friend?(@luara)
  end

  test "the requester cannot accept their own request, and nobody touches the friendship of others" do
    sent = Friendship.create!(requester: @user, addressee: @luara)
    others = Friendship.create!(requester: @luara, addressee: @othna)

    patch settings_friendship_path(sent)
    assert_response :not_found
    assert_predicate sent.reload, :pending?

    sign_in @user
    delete settings_friendship_path(others)
    assert_response :not_found
    assert Friendship.exists?(others.id)
  end

  test "suggestions leave out the user and anybody already asked or a friend" do
    Friendship.create!(requester: @othna, addressee: @user)
    User.create!(email: "olga@example.com", username: "olga", password: TEST_PASSWORD)

    get settings_friend_suggestions_path, params: { query: "o" }
    assert_equal [], response.parsed_body

    get settings_friend_suggestions_path, params: { query: "ol" }
    assert_equal %w[olga], response.parsed_body

    get settings_friend_suggestions_path, params: { query: "ot" }
    assert_equal [], response.parsed_body
  end
end
