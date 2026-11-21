require "test_helper"

# The last step of the creation of a table (summary, with the invitation link) and taking a draft up again
class TableCreationStepsTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @fantasy = SheetTemplate.create!(name: "Fantasy héroïque", locale: "fr")
    @game_table = GameTableCreator.new(user: @user, attributes: { name: "Les Marches du Nord" },
                                       sheet_template: @fantasy).call
    @game_table.reach_creation_step("summary")
    sign_in @user
  end

  test "the summary shows the table, the later steps, the invitation and the two ways to finish" do
    get game_table_summary_path(@game_table)

    assert_response :success
    assert_select "ol[aria-label=?] > li:not([aria-hidden])", "Étapes de la création", count: 4
    assert_select "ol[aria-label] > li[aria-current=step]", text: /Récapitulatif/
    # The name of the table is the title of the page: no other title keeps the cover away from the band of the steps
    assert_select "h1#summary-table-title", text: "Les Marches du Nord"
    assert_select "main h1", count: 1
    assert_select "a[href=?]", edit_game_table_details_path(@game_table), text: "Modifier"
    assert_select "form[action=?]", game_table_summary_path(@game_table) do
      assert_select "button[name=join_game]", text: "Terminer et rejoindre la partie"
      assert_select "button:not([name=join_game])", text: "Terminer la création"
    end
  end

  test "the invitation card holds the link, to copy or to send by email" do
    get game_table_summary_path(@game_table)

    link = invitation_url(@game_table.invite_token)
    assert_select "input#invitation-link[readonly][value=?]", link
    assert_select "[data-controller=clipboard] button[hidden][data-action='clipboard#copy']", text: /Copier le lien/
    assert_select "a[href^='mailto:?'][href*='#{ERB::Util.url_encode(link)}']", text: "Envoyer par e-mail"
  end

  test "the game master invites a player by their username, who stays pending until they accept" do
    User.create!(email: "luara@example.com", username: "Luara", password: TEST_PASSWORD)

    assert_difference("Participation.pending.count", 1) do
      post game_table_player_invitations_path(@game_table), params: { player_invitation: { username: "luara" } }
    end

    assert_redirected_to game_table_summary_path(@game_table)
    follow_redirect!
    assert_select "ul[aria-label=?] li", "Joueurs invités", text: /Luara\s*En attente/
  end

  test "usernames are suggested while typing: those beginning with the text, never someone already at the table" do
    User.create!(email: "luara@example.com", username: "Luara", password: TEST_PASSWORD)
    User.create!(email: "lumen@example.com", username: "Lumen", password: TEST_PASSWORD)
    User.create!(email: "aluna@example.com", username: "Aluna", password: TEST_PASSWORD)
    invited_player = User.create!(email: "lucie@example.com", username: "Lucie", password: TEST_PASSWORD)
    @game_table.participations.create!(user: invited_player, role: :player, status: :pending)

    get game_table_player_suggestions_path(@game_table), params: { query: "LU" }

    assert_equal %w[Luara Lumen], response.parsed_body
  end

  test "below two letters, no username is suggested" do
    User.create!(email: "luara@example.com", username: "Luara", password: TEST_PASSWORD)

    get game_table_player_suggestions_path(@game_table), params: { query: "l" }

    assert_equal [], response.parsed_body
  end

  test "a % typed is a plain character, not a wildcard that would list every player" do
    User.create!(email: "luara@example.com", username: "Luara", password: TEST_PASSWORD)

    get game_table_player_suggestions_path(@game_table), params: { query: "%%" }

    assert_equal [], response.parsed_body
  end

  test "the username field is tied to the list of suggestions" do
    get game_table_summary_path(@game_table)

    assert_select "form[data-controller=username-suggestions][data-username-suggestions-url-value=?]",
                  game_table_player_suggestions_path(@game_table) do
      assert_select "input#player_invitation_username[list=player-suggestions][autocomplete=off]"
      assert_select "datalist#player-suggestions[data-username-suggestions-target=list]"
    end
  end

  test "a player of the table cannot read the suggestions" do
    player = User.create!(email: "other@example.com", username: "other", password: TEST_PASSWORD)
    @game_table.participations.create!(user: player, role: :player)
    sign_in player

    get game_table_player_suggestions_path(@game_table), params: { query: "pl" }

    assert_response :not_found
  end

  test "an unknown username is refused under the field, on the summary" do
    assert_no_difference("Participation.count") do
      post game_table_player_invitations_path(@game_table), params: { player_invitation: { username: "personne" } }
    end

    assert_response :unprocessable_content
    assert_select "input#player_invitation_username[aria-invalid=true]"
    assert_select "p", text: /aucun joueur n'a ce pseudo/
  end

  test "the game master takes an invitation back" do
    invited_player = User.create!(email: "luara@example.com", username: "Luara", password: TEST_PASSWORD)
    participation = @game_table.participations.create!(user: invited_player, role: :player, status: :pending)

    assert_difference("Participation.count", -1) do
      delete game_table_player_invitation_path(@game_table, participation)
    end
    assert_redirected_to game_table_summary_path(@game_table)
  end

  test "the game master cannot be taken off their own table" do
    game_master_participation = @game_table.participations.game_master.first

    delete game_table_player_invitation_path(@game_table, game_master_participation)

    assert_response :not_found
    assert Participation.exists?(game_master_participation.id)
  end

  test "a pending invitation does not show the table in the player's my tables" do
    invited_player = User.create!(email: "luara@example.com", username: "Luara", password: TEST_PASSWORD, locale: "fr")
    @game_table.participations.create!(user: invited_player, role: :player, status: :pending)
    sign_in invited_player

    get game_tables_path

    assert_select "main", text: /Les Marches du Nord/, count: 0
  end

  test "a new link replaces the old one, asked first" do
    old_token = @game_table.invite_token
    get game_table_summary_path(@game_table)
    assert_select "form[action=?][data-turbo-confirm]", game_table_invite_token_path(@game_table)

    patch game_table_invite_token_path(@game_table)

    assert_redirected_to game_table_summary_path(@game_table)
    assert_not_equal old_token, @game_table.reload.invite_token
  end

  test "finishing the creation makes the table ready and leads back to my tables, without joining the game" do
    patch game_table_summary_path(@game_table)

    assert_redirected_to game_tables_path(table: @game_table.id)
    assert_not @game_table.reload.draft?
    follow_redirect!
    assert_select "a[href=?]", game_table_path(@game_table), text: "Rejoindre la partie"
  end

  test "finishing the creation can lead straight into the game" do
    patch game_table_summary_path(@game_table), params: { join_game: "1" }

    assert_redirected_to game_table_path(@game_table)
    assert_not @game_table.reload.draft?
  end

  test "once the creation is over, its summary cannot be opened any more" do
    @game_table.finish_creation!

    get game_table_summary_path(@game_table)

    assert_response :not_found
  end

  test "a player of the table cannot open its summary nor change its link" do
    player = User.create!(email: "other@example.com", username: "other", password: TEST_PASSWORD)
    @game_table.participations.create!(user: player, role: :player)
    sign_in player

    get game_table_summary_path(@game_table)
    assert_response :not_found
    # sign_in only holds for the next request, and an error response does not send the session cookie back
    sign_in player
    patch game_table_invite_token_path(@game_table)
    assert_response :not_found
  end

  test "my tables takes a draft up again at the step it stopped at" do
    get game_tables_path(table: @game_table.id)

    assert_select "a[href=?]", game_table_summary_path(@game_table), text: "Reprendre la création"
  end

  test "the invitation link leads to a temporary page of the table" do
    get invitation_path(@game_table.invite_token)

    assert_response :success
    assert_select "main h1", text: "Invitation à « Les Marches du Nord »"
  end
end
