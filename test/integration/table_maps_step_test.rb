require "test_helper"

# The step Maps of a table: the list of its maps, each one copied from « Mes cartes », changed and deleted in its
# window or in the map editor, for its game master only. Maps sent as an image before the editor are still changed and deleted
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
                  text: /Importer depuis « Mes cartes »/
    assert_select "form[action=?] button", game_table_game_maps_path(@game_table), text: /Créer une carte/

    patch game_table_map_list_path(@game_table)
    assert_redirected_to game_table_summary_path(@game_table)
  end

  test "« Importer depuis Mes cartes » lists my maps only, and the one chosen is copied into the table, then listed" do
    tavern = @game_master.map_templates.create!(name: "Taverne du Pendu", columns: 20, rows: 15, layout: drawing)
    stranger = User.create!(email: "other@example.com", username: "autre", password: TEST_PASSWORD)
    stranger.map_templates.create!(name: "Donjon d'un autre")

    get new_game_table_game_map_path(@game_table), headers: MAP_HEADERS
    assert_select "turbo-frame#map_dialog form[action=?] button[aria-label=?]", game_table_game_maps_path(@game_table),
                  "Ajouter la carte « Taverne du Pendu »"
    assert_select "button", text: /Donjon d'un autre/, count: 0

    post game_table_game_maps_path(@game_table), headers: MAP_HEADERS, params: { map_template_id: tavern.id }
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    game_map = @game_table.game_maps.sole
    assert_equal [tavern, "Taverne du Pendu", 20, 15, drawing], game_map.slice(:map_template, :name, :columns, :rows, :layout).values

    get edit_game_table_map_list_path(@game_table)
    assert_select "#map-list section[aria-labelledby=map-list-title] li svg[data-controller=map-preview]"
    assert_select "#map-list li", text: /Taverne du Pendu\s+20 × 15 cases/
  end

  test "without a map of my own, the window leads to « Mes cartes »; the map of another is not found" do
    get new_game_table_game_map_path(@game_table), headers: MAP_HEADERS
    assert_select "turbo-frame#map_dialog a[href=?][data-turbo-frame=_top]", map_templates_path

    stranger = User.create!(email: "other@example.com", username: "autre", password: TEST_PASSWORD)
    map_of_another = stranger.map_templates.create!(name: "Donjon d'un autre")
    post game_table_game_maps_path(@game_table), headers: MAP_HEADERS, params: { map_template_id: map_of_another.id }
    assert_response :not_found
    assert_empty @game_table.game_maps
  end

  test "a map copied opens in the map editor, which saves its drawing on the copy only" do
    tavern = @game_master.map_templates.create!(name: "Taverne", layout: drawing)
    game_map = MapTemplates::TableCopier.new(tavern, @game_table).call

    get edit_game_table_map_list_path(@game_table)
    assert_select "#map-list a[href=?][aria-label=?]", edit_game_table_game_map_path(@game_table, game_map),
                  "Placer les jetons et les zones bloquantes de Taverne"

    get edit_game_table_game_map_path(@game_table, game_map)
    assert_select "main[data-controller=map-editor][data-map-editor-url-value=?]",
                  game_table_game_map_layout_path(@game_table, game_map)
    assert_select "header input[name='game_map[name]'][value=Taverne]"
    assert_select "header a[href=?]", edit_game_table_map_list_path(@game_table), text: /Cartes de la table/
    assert_select "header button[data-tool-kind=blocker][title=?]", "Zones bloquantes"

    new_drawing = drawing.merge("edges" => { "1,1|2,1" => "door" }, "blocked" => ["5,5"])
    patch game_table_game_map_layout_path(@game_table, game_map), params: { layout: new_drawing.to_json, columns: "30" }
    assert_response :no_content
    assert_equal [new_drawing, 30], game_map.reload.slice(:layout, :columns).values
    assert_equal drawing, tavern.reload.layout
    assert_includes game_map.passage.blocked_cells, [5, 5]
  end

  test "the editor of a map of the table lists its non-player characters and enemies for their tokens" do
    goblin = @game_table.characters.create!(kind: :monster, name: "Gobelin")
    game_map = MapTemplates::TableCopier.new(@game_master.map_templates.create!(name: "Taverne"), @game_table).call

    get edit_game_table_game_map_path(@game_table, game_map)
    assert_select "[role=tab]#map-editor-tab-tokens", text: "Jetons"
    assert_select "[data-map-help-storage-key-value=map_editor_table_help] p", text: /Carte de votre table/
    assert_select "button[data-tool-kind=token][data-tool-key=?]", goblin.id.to_s, text: /Gobelin\s+Ennemi/
    editor = css_select("main[data-controller=map-editor]").first
    token_characters = JSON.parse(editor["data-map-editor-token-characters-value"])
    assert_equal({ goblin.id.to_s => { "name" => "Gobelin", "kind" => "monster" } }, token_characters)

    patch game_table_game_map_layout_path(@game_table, game_map),
          params: { layout: drawing.merge("tokens" => [{ character_id: goblin.id, column: 1, row: 1 }]).to_json }
    assert_response :no_content
    placed = game_map.reload.placed_tokens.map { |token| token.values_at(:character, :number) }
    assert_equal [[goblin, 1]], placed

    get edit_game_table_map_list_path(@game_table)
    assert_select "#map-list li span.sr-only", text: "1 jeton"
  end

  test "a creature of the bestiary is listed and copied into the table when its first token is put" do
    @game_table.sheet_template.catalog_entries.create!(kind: "monster", key: "goblin", name: "Gobelin éclaireur")
    game_map = MapTemplates::TableCopier.new(@game_master.map_templates.create!(name: "Taverne"), @game_table).call

    get edit_game_table_game_map_path(@game_table, game_map)
    assert_select "button[data-tool-kind=creature][data-tool-key=goblin]", text: /Gobelin éclaireur/
    assert_select "main[data-map-editor-creature-url-value=?]", game_table_game_map_creatures_path(@game_table, game_map)
    assert_select "[data-search-name='gobelin eclaireur']"

    2.times { post game_table_game_map_creatures_path(@game_table, game_map), params: { key: "goblin" } }
    assert_response :created
    assert_equal ["Gobelin éclaireur", "Gobelin éclaireur 2"], @game_table.npcs.pluck(:name)
    assert_equal({ "id" => @game_table.npcs.last.id, "name" => "Gobelin éclaireur 2", "kind" => "monster" },
                 response.parsed_body)

    post game_table_game_map_creatures_path(@game_table, game_map), params: { key: "dragon" }
    assert_response :not_found
  end

  test "a map copied is renamed in its editor; its grid stays" do
    game_map = MapTemplates::TableCopier.new(@game_master.map_templates.create!(name: "Taverne"), @game_table).call

    patch game_table_game_map_path(@game_table, game_map),
          params: { game_map: { name: "Taverne basse", columns: "40" } }
    assert_redirected_to edit_game_table_game_map_path(@game_table, game_map)
    assert_equal ["Taverne basse", 28], game_map.reload.slice(:name, :columns).values

    patch game_table_game_map_path(@game_table, game_map), params: { game_map: { name: "" } }
    assert_response :unprocessable_content
    assert_select "header input[name='game_map[name]'][aria-invalid=true]"
  end

  test "« Créer une carte » draws an empty map for the table and opens its editor" do
    post game_table_game_maps_path(@game_table)
    game_map = @game_table.game_maps.sole
    assert_redirected_to edit_game_table_game_map_path(@game_table, game_map)
    assert_equal ["Nouvelle carte", 28, 21, nil], game_map.slice(:name, :columns, :rows, :map_template).values
    assert_predicate game_map, :drawn?
  end

  test "a map of the table plays on a picture of its own, sent and taken away in its editor" do
    game_map = MapTemplates::TableCopier.new(@game_master.map_templates.create!(name: "Taverne"), @game_table).call

    post game_table_game_map_picture_path(@game_table, game_map), params: { picture: map_image }
    assert_redirected_to edit_game_table_game_map_path(@game_table, game_map)
    assert_predicate game_map.reload, :on_picture?
    assert_predicate game_map.image, :attached?

    delete game_table_game_map_picture_path(@game_table, game_map)
    assert_not game_map.reload.image.attached?
  end

  test "the drawing and the picture of a map sent as an image, or of another table, are not found" do
    image_map = @game_table.game_maps.create!(name: "Crypte", image: map_image)
    assert_not_found { patch game_table_game_map_layout_path(@game_table, image_map), params: { layout: drawing.to_json } }

    stranger = User.create!(email: "other@example.com", username: "autre", password: TEST_PASSWORD)
    other_table = GameTableCreator.new(user: stranger, attributes: { name: "Ailleurs" },
                                       sheet_template: SheetTemplate.create!(name: "Autre", locale: "fr")).call
    other_map = MapTemplates::TableCopier.new(stranger.map_templates.create!(name: "Donjon"), other_table).call
    assert_not_found { post game_table_game_map_picture_path(other_table, other_map), params: { picture: map_image } }
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

  # A 404 does not save the session: signed in again for the next request
  def assert_not_found
    yield
    assert_response :not_found
    sign_in @game_master
  end

  def drawing
    MapTemplate::BLANK_LAYOUT.merge("floors" => { "1,1" => "room", "2,1" => "room" })
  end

  def map_image(name = "map.png")
    fixture_file_upload(name, name.end_with?(".png") ? "image/png" : "text/plain")
  end
end
