require "test_helper"

class TablesTest < ActionDispatch::IntegrationTest
  test "my tables shows its title and the empty state, in french" do
    sign_in create_user(locale: "fr")
    get tables_path

    assert_response :success
    assert_select "main header h1", text: "Mes tables"
    assert_select "main header p.text-muted", text: "Vos parties en cours, comme MJ ou comme joueur."
    assert_select "main section[aria-labelledby=empty-tables-title].border-dashed" do
      assert_select "h2#empty-tables-title", text: "Aucune table pour l'instant"
      assert_select "span[aria-hidden=true] svg"
    end
  end

  test "the cards sit in a grid: one column on a phone, two on a tablet, three on a wide screen" do
    sign_in create_user(locale: "fr")
    get tables_path

    assert_select "#{cards_grid_selector} > section[aria-labelledby=empty-tables-title]"
  end

  test "my tables is translated in english" do
    sign_in create_user(locale: "en")
    get tables_path

    assert_select "main h1", text: "My tables"
    assert_select "main h2", text: "No table yet"
  end

  test "the create a table button is in the header only, the join button waits for its page" do
    sign_in create_user(locale: "fr")
    get tables_path

    assert_select "main header a.bg-primary[href=?]", new_table_path, text: "Créer une table"
    assert_select "main section a", count: 0
    assert_select "main a", count: 1
  end

  test "the create a table page says it is coming soon and leads back to my tables" do
    sign_in create_user(locale: "fr")
    get new_table_path

    assert_response :success
    assert_select "main h1", text: "Créer une table"
    assert_select "main a[href=?]", tables_path, text: "Retour à mes tables"
  end

  test "the create a table page is translated in english" do
    sign_in create_user(locale: "en")
    get new_table_path

    assert_select "main h1", text: "Create a table"
  end

  test "a visitor is sent to the sign in page" do
    get tables_path
    assert_redirected_to new_user_session_path

    get new_table_path
    assert_redirected_to new_user_session_path
  end

  test "a signed in user opening the home page goes to their tables" do
    sign_in create_user(locale: "fr")
    get root_path

    assert_redirected_to tables_path
  end

  test "a visitor keeps the home page" do
    get root_path

    assert_response :success
  end

  test "signing in leads to my tables" do
    user = create_user(locale: "fr")
    post user_session_path, params: { user: { email: user.email, password: TEST_PASSWORD } }

    assert_redirected_to tables_path
  end

  test "signing up leads to my tables" do
    post user_registration_path, params: { user: { username: "new_player", email: "new.player@example.com",
                                                   password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD } }

    assert_redirected_to tables_path
  end

  test "a page asked for before signing in comes first" do
    user = create_user(locale: "fr")
    get settings_account_path
    post user_session_path, params: { user: { email: user.email, password: TEST_PASSWORD } }

    assert_redirected_to settings_account_path
  end

  private

  def cards_grid_selector
    "main div.grid.grid-cols-1.md\\:grid-cols-2.lg\\:grid-cols-3"
  end

  def create_user(locale:)
    User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: locale)
  end
end
