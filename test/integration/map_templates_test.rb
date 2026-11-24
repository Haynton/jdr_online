require "test_helper"

# « Mes cartes » (MapTemplatesController): a game master creates a map (its name and the size of its grid), renames
# it, deletes it. Every permission is checked by the server: only their own maps
class MapTemplatesTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = User.create!(email: "mj@example.com", username: "Morgane", password: TEST_PASSWORD, locale: "fr")
    @other_game_master = User.create!(email: "autre@example.com", username: "Basile", password: TEST_PASSWORD)
    sign_in @game_master
  end

  test "the list starts with the card that creates a map, then my maps only, each a link to its page" do
    tavern = @game_master.map_templates.create!(name: "La taverne", columns: 20, rows: 15)
    @other_game_master.map_templates.create!(name: "Le donjon de Basile")
    get map_templates_path

    assert_response :success
    assert_select "main h1", text: "Mes cartes"
    assert_select "section[aria-labelledby=own-maps-title]" do
      assert_select "li:first-child form[action=?][method=post] button", map_templates_path, text: /Créer une carte/
      assert_select "li a[href=?]", edit_map_template_path(tavern), text: /La taverne.*20 × 15 cases/m
    end
    assert_select "li", text: /Basile/, count: 0
    assert_select "#side-nav a[href=?][aria-current=page]", map_templates_path, text: /Mes cartes/
  end

  test "« Créer une carte » makes a map named « Nouvelle carte », of the default size, and opens its editor" do
    assert_difference -> { @game_master.map_templates.count }, 1 do
      post map_templates_path
    end

    map_template = MapTemplate.last
    assert_redirected_to edit_map_template_path(map_template)
    assert_equal ["Nouvelle carte", 28, 21], [map_template.name, map_template.columns, map_template.rows]
  end

  test "creating a map opens its page, with the size chosen" do
    get new_map_template_path
    assert_select "input[name='map_template[columns]'][value='28'][min='10'][max='60']"

    assert_difference -> { @game_master.map_templates.count }, 1 do
      post map_templates_path, params: { map_template: { name: "La crypte", columns: "30", rows: "12" } }
    end

    map_template = MapTemplate.last
    assert_redirected_to edit_map_template_path(map_template)
    assert_equal [30, 12], [map_template.columns, map_template.rows]
    assert_equal MapTemplate::BLANK_LAYOUT, map_template.layout
    follow_redirect!
    assert_select "main h1", text: "La crypte"
    assert_select "#side-nav a[href=?][aria-current=page]", map_templates_path
  end

  test "a map without a name or with a grid too small is not created, the form says why" do
    assert_no_difference -> { MapTemplate.count } do
      post map_templates_path, params: { map_template: { name: "", columns: "5", rows: "21" } }
    end

    assert_response :unprocessable_content
    assert_select "input[name='map_template[name]'][aria-invalid=true]"
    assert_select "input[name='map_template[columns]'][aria-invalid=true][value='5']"
  end

  test "a drawing cannot be sent at the creation: only the name and the size" do
    post map_templates_path, params: { map_template: { name: "La crypte", layout: { "floors" => "x" } } }

    assert_equal MapTemplate::BLANK_LAYOUT, MapTemplate.last.layout
  end

  test "renaming keeps the grid and the drawing; a blank name is refused" do
    map_template = @game_master.map_templates.create!(name: "La taverne")

    patch map_template_path(map_template), params: { map_template: { name: "L'auberge", columns: "40" } }
    assert_redirected_to edit_map_template_path(map_template)
    assert_equal ["L'auberge", 28], [map_template.reload.name, map_template.columns]

    patch map_template_path(map_template), params: { map_template: { name: "" } }
    assert_response :unprocessable_content
    assert_select "main h1", text: "L'auberge"
    assert_select "aside[data-tabs-selected-index-value='2'] input[name='map_template[name]'][aria-invalid=true]"
  end

  test "deleting a map, after a question, takes it out of my maps" do
    map_template = @game_master.map_templates.create!(name: "La taverne")
    get edit_map_template_path(map_template)
    assert_select "form[action=?] button[data-turbo-confirm][data-confirm-variant=danger]",
                  map_template_path(map_template)

    assert_difference -> { MapTemplate.count }, -1 do
      delete map_template_path(map_template)
    end
    assert_redirected_to map_templates_path
  end

  test "the map of another game master is not found" do
    map_of_another = @other_game_master.map_templates.create!(name: "Le donjon de Basile")

    assert_not_found { get edit_map_template_path(map_of_another) }
    assert_not_found { patch map_template_path(map_of_another), params: { map_template: { name: "À moi" } } }
    assert_not_found { delete map_template_path(map_of_another) }
    assert_equal "Le donjon de Basile", map_of_another.reload.name
  end

  test "a visitor is sent to the login" do
    sign_out @game_master
    get map_templates_path

    assert_redirected_to new_user_session_path
  end

  private

  # sign_in of Devise signs in the next request only, and a 404 does not save the session: sign in again after it
  def assert_not_found
    yield
    assert_response :not_found
    sign_in @game_master
  end
end
