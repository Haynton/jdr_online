require "test_helper"

# The step Maps of a table: the list of its maps, each one added, changed and deleted in its window, for its game
# master only
class TableMapsStepTest < ActionDispatch::IntegrationTest
  MAP_HEADERS = { "Turbo-Frame" => GameTables::MapDialogHelper::MAP_FRAME }.freeze

  setup do
    @game_master = User.create!(email: "gm@example.com", username: "maitre", password: TEST_PASSWORD, locale: "fr")
    @game_table = GameTableCreator.new(user: @game_master, attributes: { name: "La Crypte" },
                                       sheet_template: SheetTemplate.create!(name: "Fantasy", locale: "fr")).call
    @game_table.reach_creation_step("maps")
    sign_in @game_master
  end

  test "the step lists no map at first, and Continue opens the summary" do
    get edit_game_table_map_list_path(@game_table)

    assert_select "ol[aria-label] > li[aria-current=step]", text: /Cartes/
    assert_select "p", text: /Aucune carte pour l'instant/
    assert_select "a[href=?][data-turbo-frame=map_dialog]", new_game_table_game_map_path(@game_table),
                  text: /Ajouter une carte/

    patch game_table_map_list_path(@game_table)
    assert_redirected_to game_table_summary_path(@game_table)
  end

  test "a map is added in its window with its image and grid, then listed" do
    post game_table_game_maps_path(@game_table), headers: MAP_HEADERS,
                                                 params: { game_map: { name: "Taverne du Pendu", grid_cell_size: "70",
                                                                       grid_visible: "0", image: map_image } }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    game_map = @game_table.game_maps.sole
    assert_equal ["Taverne du Pendu", 70, false], [game_map.name, game_map.grid_cell_size, game_map.grid_visible]
    assert_predicate game_map.image, :attached?

    get edit_game_table_map_list_path(@game_table)
    assert_select "#map-list li", text: /Taverne du Pendu\s+Grille de 70 px, masquée/
  end

  test "a map needs a name and an image, a picture" do
    post game_table_game_maps_path(@game_table), headers: MAP_HEADERS, params: { game_map: { name: "" } }
    assert_response :unprocessable_content
    assert_select "turbo-frame#map_dialog p", text: /doit être rempli/

    post game_table_game_maps_path(@game_table), headers: MAP_HEADERS,
                                                 params: { game_map: { name: "Notes", image: map_image("notes.txt") } }
    assert_select "p", text: "doit être une image PNG, JPEG ou WebP"
    assert_empty @game_table.game_maps
  end

  test "changing a map keeps its image unless another is chosen, and it can be deleted" do
    game_map = @game_table.game_maps.create!(name: "Crypte", image: map_image)
    patch game_table_game_map_path(@game_table, game_map), headers: MAP_HEADERS,
                                                           params: { game_map: { name: "Crypte basse", image: "" } }

    assert_equal "Crypte basse", game_map.reload.name
    assert_predicate game_map.image, :attached?

    delete game_table_game_map_path(@game_table, game_map), headers: MAP_HEADERS
    assert_empty @game_table.game_maps.reload
  end

  test "only the game master of the table reaches its maps" do
    game_map = @game_table.game_maps.create!(name: "Crypte", image: map_image)
    player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD)
    @game_table.participations.create!(user: player, role: "player")
    sign_in player

    get edit_game_table_game_map_path(@game_table, game_map)
    assert_response :not_found
  end

  private

  def map_image(name = "map.png")
    fixture_file_upload(name, name.end_with?(".png") ? "image/png" : "text/plain")
  end
end
