require "test_helper"

class TablesTest < ActionDispatch::IntegrationTest
  test "without a table, my tables shows the default cover, the empty state and the create card, in french" do
    sign_in create_user(locale: "fr")
    get game_tables_path

    assert_response :success
    assert_select "main section[aria-labelledby=empty-tables-title]" do
      assert_select "img[alt=''][src*='covers/sentinelle']"
      assert_select "h1#empty-tables-title", text: "Aucune table pour l'instant"
    end
    assert_select "main h2#all-tables-title", text: "Toutes mes tables"
    assert_select "#{cards_row_selector} > li", count: 1
  end

  test "my tables is translated in english" do
    sign_in create_user(locale: "en")
    get game_tables_path

    assert_select "main h1", text: "No table yet"
    assert_select "main h2", text: "All my tables"
    assert_select "#{cards_row_selector} a", text: "Create a table"
  end

  test "the create card comes first in the row, with the default cover" do
    user = create_user(locale: "fr")
    create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    sign_in user
    get game_tables_path

    assert_select "#{cards_row_selector} > li:first-child a[href=?]", new_game_table_path do
      assert_select "img[src*='covers/sentinelle']"
      assert_select "span", text: "Créer une table"
    end
  end

  test "a table card shows the role of the user, the name, the players and the cover of the table" do
    user = create_user(locale: "fr")
    game_table = create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    game_table.participations.create!(user: create_other_user, role: :player)
    sign_in user
    get game_tables_path

    assert_select "#{cards_row_selector} a[href=?]", game_tables_path(table: game_table.id) do
      assert_select "img[src*='covers/wolf']"
      assert_select "span", text: "MJ"
      assert_select "span", text: "· Brouillon"
      assert_select "span", text: "Les Marches du Nord"
      assert_select "span", text: "1 joueur"
    end
  end

  test "a table no longer in draft is shown in progress, on its card and at the top" do
    user = create_user(locale: "fr")
    game_table = create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    game_table.update!(status: "active")
    sign_in user
    get game_tables_path

    assert_select "#{cards_row_selector} span", text: "· En cours"
    assert_select "section[aria-labelledby=chosen-table-title] span", text: "· En cours"
  end

  test "each table card carries its role and status for the filter, the create card none" do
    user = create_user(locale: "fr")
    game_table = create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    sign_in user
    get game_tables_path

    assert_select "#{cards_row_selector} > li[data-table-filter-target=card][data-role=game_master][data-status=draft]",
                  count: 1 do
      assert_select "a[href=?]", game_tables_path(table: game_table.id)
    end
    assert_select "#{cards_row_selector} > li:first-child:not([data-table-filter-target])"
    assert_select "#{cards_row_selector} > li[hidden][data-table-filter-target=noMatch]",
                  text: "Aucune table ne correspond à ce filtre."
  end

  test "without a table, there is nothing to filter: no pills, no message" do
    sign_in create_user(locale: "fr")
    get game_tables_path

    assert_select "[data-table-filter-target=pills]", count: 0
    assert_select "[data-table-filter-target=noMatch]", count: 0
  end

  test "the filter pills are named, hidden until their controller shows them, and split role from status" do
    user = create_user(locale: "fr")
    create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    sign_in user
    get game_tables_path

    assert_select "div[hidden][role=group][aria-label=?][data-table-filter-target=pills]", "Filtrer les tables" do
      assert_select "button[aria-pressed=false][data-group=role][data-value=game_master]", text: "MJ"
      assert_select "button[aria-pressed=false][data-group=role][data-value=player]", text: "Joueur"
      assert_select "button[aria-pressed=false][data-group=status][data-value=draft]", text: "Brouillon"
      assert_select "button[aria-pressed=false][data-group=status][data-value=in_progress]", text: "En cours"
      assert_select "span[aria-hidden=true].bg-line", count: 1
    end
  end

  test "from the first table, the empty state gives way to the newest table" do
    user = create_user(locale: "fr")
    create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    create_table_for(user, name: "L'Ombre du Dragon", cover_image: "dragon")
    sign_in user
    get game_tables_path

    assert_select "section[aria-labelledby=empty-tables-title]", count: 0
    assert_select "section[aria-labelledby=chosen-table-title]" do
      assert_select "img[src*='covers/dragon']"
      assert_select "h1#chosen-table-title", text: "L'Ombre du Dragon"
      assert_select "p", text: "Une description"
    end
    assert_select "#{cards_row_selector} a[aria-current=true]", count: 1, text: /L'Ombre du Dragon/
  end

  test "choosing a card shows that table at the top" do
    user = create_user(locale: "fr")
    older_table = create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    create_table_for(user, name: "L'Ombre du Dragon", cover_image: "dragon")
    sign_in user
    get game_tables_path(table: older_table.id)

    assert_select "h1#chosen-table-title", text: "Les Marches du Nord"
    assert_select "#{cards_row_selector} a[aria-current=true]", count: 1, text: /Les Marches du Nord/
  end

  test "the chosen table sits in a frame, whose links still open a whole page" do
    user = create_user(locale: "fr")
    create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    sign_in user
    get game_tables_path

    assert_select "turbo-frame#chosen_table[target=_top] section[aria-labelledby=chosen-table-title]"
  end

  test "a table card only replaces the chosen table and the address, and moves the gold outline itself" do
    user = create_user(locale: "fr")
    game_table = create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    sign_in user
    get game_tables_path

    assert_select "#{cards_row_selector} a[href=?][data-turbo-frame=chosen_table][data-turbo-action=advance]" \
                  "[data-action='card-row#choose']", game_tables_path(table: game_table.id)
    assert_select "#{cards_row_selector} a[href=?]:not([data-turbo-frame])", new_game_table_path
  end

  test "the tables of other users are neither in the row nor shown when asked for" do
    other_table = create_table_for(create_other_user, name: "L'Ombre du Dragon", cover_image: "dragon")
    sign_in create_user(locale: "fr")
    get game_tables_path(table: other_table.id)

    assert_select "section[aria-labelledby=empty-tables-title]"
    assert_select "main", text: /L'Ombre du Dragon/, count: 0
  end

  test "the game master can join the game, set it up and create another one, and sees the avatars of the players" do
    user = create_user(locale: "fr")
    game_table = create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    game_table.update!(status: "ready")
    game_table.participations.create!(user: create_other_user, role: :player)
    sign_in user
    get game_tables_path

    assert_select "section[aria-labelledby=chosen-table-title]" do
      assert_select "a.bg-primary[href=?]", game_table_path(game_table), text: "Rejoindre la partie"
      assert_select "a[href=?]", edit_game_table_details_path(game_table), text: "Paramètres de la partie"
      assert_select "a[href=?]", new_game_table_path, text: "Créer une table"
      assert_select "span[aria-hidden=true]", text: "OT"
      assert_select "p", text: /1 joueur/
    end
  end

  test "the game master of a draft resumes its creation instead of joining the game" do
    user = create_user(locale: "fr")
    game_table = create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    sign_in user
    get game_tables_path

    assert_select "a.bg-primary[href=?]", edit_game_table_details_path(game_table), text: "Reprendre la création"
    assert_select "a[href=?]", game_table_path(game_table), count: 0
  end

  test "a player with a character can join the game but has no settings button" do
    user = create_user(locale: "fr")
    game_table = create_table_for(create_other_user, name: "L'Ombre du Dragon", cover_image: "dragon")
    participation = game_table.participations.create!(user: user, role: :player)
    participation.create_character!(game_table: game_table, name: "Aldric")
    sign_in user
    get game_tables_path

    assert_select "a[href=?]", game_table_path(game_table), text: "Rejoindre la partie"
    assert_select "a[href=?]", edit_game_table_path(game_table), count: 0
  end

  test "a player without a character creates it before joining the game" do
    user = create_user(locale: "fr")
    game_table = create_table_for(create_other_user, name: "L'Ombre du Dragon", cover_image: "dragon")
    game_table.participations.create!(user: user, role: :player)
    sign_in user
    get game_tables_path

    assert_select "a[href=?]", new_game_table_character_path(game_table), text: "Créer mon personnage"
    assert_select "a[href=?]", game_table_path(game_table), count: 0
  end

  test "the old address of the settings of the game leads to the pages of its creation" do
    user = create_user(locale: "fr")
    game_table = create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    sign_in user
    get edit_game_table_path(game_table)

    assert_redirected_to edit_game_table_details_path(game_table)
  end

  test "a draft has no settings button: its game master resumes its creation" do
    user = create_user(locale: "fr")
    create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    sign_in user
    get game_tables_path

    assert_select "section[aria-labelledby=chosen-table-title] a", text: "Paramètres de la partie", count: 0
  end

  test "a player cannot open the settings of the game, even by its address" do
    user = create_user(locale: "fr")
    game_table = create_table_for(create_other_user, name: "L'Ombre du Dragon", cover_image: "dragon")
    game_table.participations.create!(user: user, role: :player)
    sign_in user
    get edit_game_table_path(game_table)

    assert_response :not_found
  end

  test "the row of cards has arrows named for screen readers, hidden until the controller shows them" do
    sign_in create_user(locale: "fr")
    get game_tables_path

    assert_select "section[data-controller~=card-row]" do
      assert_select "button[hidden][aria-label=?][data-action='card-row#scrollPrevious']", "Tables précédentes"
      assert_select "button[hidden][aria-label=?][data-action='card-row#scrollNext']", "Tables suivantes"
      assert_select "ul.no-scrollbar[data-card-row-target=row]"
    end
  end

  test "a participant opens the game room of their table" do
    user = create_user(locale: "fr")
    game_table = create_table_for(user, name: "Les Marches du Nord", cover_image: "wolf")
    sign_in user
    get game_table_path(game_table)

    assert_response :success
    assert_select "h1", text: "Les Marches du Nord"
    assert_select "form[action=?][method=get][data-turbo-confirm] button[aria-label=?]", game_tables_path,
                  "Quitter la partie"
  end

  test "someone who is not at a table cannot open it" do
    other_table = create_table_for(create_other_user, name: "L'Ombre du Dragon", cover_image: "dragon")
    sign_in create_user(locale: "fr")
    get game_table_path(other_table)

    assert_response :not_found
  end

  test "the create a table page is translated in english" do
    sign_in create_user(locale: "en")
    get new_game_table_path

    assert_select "main h1", text: "Create a table"
  end

  test "a visitor is sent to the sign in page" do
    get game_tables_path
    assert_redirected_to new_user_session_path

    get new_game_table_path
    assert_redirected_to new_user_session_path
  end

  test "a signed in user opening the home page goes to their tables" do
    sign_in create_user(locale: "fr")
    get root_path

    assert_redirected_to game_tables_path
  end

  test "a visitor keeps the home page" do
    get root_path

    assert_response :success
  end

  test "signing in leads to my tables" do
    user = create_user(locale: "fr")
    post user_session_path, params: { user: { email: user.email, password: TEST_PASSWORD } }

    assert_redirected_to game_tables_path
  end

  test "signing up leads to my tables" do
    post user_registration_path, params: { user: { username: "new_player", email: "new.player@example.com",
                                                   password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD } }

    assert_redirected_to game_tables_path
  end

  test "a page asked for before signing in comes first" do
    user = create_user(locale: "fr")
    get settings_account_path
    post user_session_path, params: { user: { email: user.email, password: TEST_PASSWORD } }

    assert_redirected_to settings_account_path
  end

  private

  def cards_row_selector
    "main section[aria-labelledby=all-tables-title] ul"
  end

  def create_user(locale:)
    User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: locale)
  end

  def create_other_user
    User.create!(email: "other@example.com", username: "other", password: TEST_PASSWORD)
  end

  def create_table_for(user, name:, cover_image:)
    game_table = GameTable.create!(name: name, description: "Une description", cover_image: cover_image)
    game_table.participations.create!(user: user, role: :game_master)
    game_table
  end
end
