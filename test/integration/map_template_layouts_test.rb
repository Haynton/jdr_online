require "test_helper"

# The map editor saves the drawing of a map after each stroke (MapTemplates::LayoutsController): the layout comes as
# a JSON text, checked by MapLayoutValidator. Only on a map of one's own
class MapTemplateLayoutsTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = User.create!(email: "mj@example.com", username: "Morgane", password: TEST_PASSWORD, locale: "fr")
    @map_template = @game_master.map_templates.create!(name: "La taverne", columns: 10, rows: 10)
    sign_in @game_master
  end

  test "the page of a map is the editor: the bar, the board and the panel, hidden until their controllers show them" do
    @map_template.update!(layout: layout_with(floors: { "1,1" => "room" }))
    get edit_map_template_path(@map_template)

    assert_select "main[data-controller=map-editor][data-map-editor-url-value=?][data-map-editor-columns-value='10']",
                  map_template_layout_path(@map_template)
    assert_includes css_select("main[data-controller=map-editor]").first["data-map-editor-layout-value"], '"1,1":"room"'
    assert_select "header h1", text: "La taverne"
    assert_select "header [role=toolbar][hidden] button[data-tool-kind=eraser]", text: "Gomme"
    assert_select "header [role=toolbar] button[data-action='map-editor#undo'][disabled]", text: "Annuler"
    assert_select "header [role=toolbar] button[data-action='map-editor#redo'][disabled]", text: "Rétablir"
    assert_select "header [role=toolbar] button[data-action='map-editor#clearEverything']", text: "Tout effacer"
    assert_select "header button[data-action='map-editor#showWholeMap']", count: 0
    assert_select "[data-map-editor-target=zoomButtons][hidden] button[aria-label=?]", "Afficher toute la carte"
    assert_select "[data-map-editor-target=zoomButtons] button[aria-label=?]", "Zoomer"
    # The size of the grid floats over the board, shown by the editor
    assert_select "[data-map-editor-target=gridSize][hidden] button[data-action='map-editor#addColumn'][aria-label=?]",
                  "Une colonne de plus"
    assert_select "svg[data-map-editor-target=board][hidden]"
    # « Mes cartes » is in the navigation: not again in the panel (Anthony's request)
    assert_select "aside a[href=?]", map_templates_path, count: 0
    assert_select "[data-controller=map-help][hidden] button[aria-controls=map-editor-help][aria-label=?]", "Aide"
    assert_select "aside [role=tablist][hidden] button[role=tab][id^=map-editor-tab-]", count: 3
    # How the map is made, in the bar: drawn here, the drawing panel shown, the panel of the picture hidden
    assert_select "header input[name=map-making][value=draw][checked]"
    assert_select "header input[name=map-making][value=picture]:not([checked])"
    assert_select "[data-map-editor-target=drawingPanel]:not([hidden])"
    assert_select "[data-map-editor-target=picturePanel][hidden]"
    # This map has a cell drawn: its tab Terrain first
    assert_select "[data-map-editor-target=drawingPanel][data-tabs-selected-index-value=?]", "1"
    assert_select "header input[name='map_template[name]'][value=?][aria-label=?]", "La taverne", "Nom de la carte"
    assert_select "[data-map-editor-target=gridSize] input#map-columns[value='10'][data-action='change->map-editor#resizeGrid']"
    assert_select "[data-map-editor-target=gridSize] [data-map-editor-target=rowsCount]", text: "10"
    # Deleted from « Mes cartes », not here (Anthony's request)
    assert_select "form[action=?] input[name=_method][value=delete]", map_template_path(@map_template), count: 0
  end

  test "a map still empty opens on its tab Templates: the maps ready to use, each with its drawing and its button" do
    get edit_map_template_path(@map_template)

    assert_select "[data-map-editor-target=drawingPanel][data-tabs-selected-index-value=?]", "0"
    assert_select "#map-editor-tab-presets", text: "Modèles"
    assert_select "#map-editor-panel-presets li[data-map-preset]", count: MapPresets::KEYS.size
    assert_select "#map-editor-panel-presets button[data-action='map-editor#usePreset'][aria-label=?]",
                  "Utiliser le modèle « Campement »"
  end

  test "the tab Objects shows one family at a time; the bar turns and takes objects away" do
    get edit_map_template_path(@map_template)

    assert_select "#map-editor-panel-objects [role=tablist][hidden] button[role=tab]", text: "Mobilier"
    assert_select "#map-objects-panel-furniture button[data-tool-kind=object]",
                  count: MapObjects.of_family("furniture").size
    assert_select "#map-editor-panel-objects button[data-tool-kind=object]", count: MapObjects::ALL.size
    assert_select "button[data-tool-key=bed] span[aria-hidden=true]", text: "2×1"
    # The degrees only in the tooltip: in the label, they changed the width of the button
    assert_select "header [role=toolbar] button[data-action='map-editor#rotatePlacement'][title='Pivoter (R) · 0°']",
                  text: "Pivoter (R)"
    assert_select "header [role=toolbar] button[data-tool-kind=remover]", text: "Retirer objet"
    # Only the tools of the panel have a swatch to draw: a swatch of another kind would stop the editor
    assert_select "header [data-map-editor-target=swatch]", count: 0
    drawn_kinds = %w[floor edge object].map { |kind| ":not([data-tool-kind=#{kind}])" }.join
    assert_select "[data-map-editor-target=swatch]#{drawn_kinds}", count: 0
    assert_select "#map-editor-panel-floors[role=tabpanel] button[data-tool-kind=floor]", count: MapFloors.keys.size
    assert_select "#map-editor-panel-floors button[data-tool-kind=edge]", count: MapEdges.keys.size
    assert_select "#map-editor-panel-floors button[data-tool-key=room]", text: "Salle"
  end

  test "the figures of the drawing are given in the words of the page, by count" do
    get edit_map_template_path(@map_template)

    labels = JSON.parse(css_select("main[data-controller=map-editor]").first["data-map-editor-figure-labels-value"])
    assert_equal I18n.t("map_templates.editor.figures.cells", locale: :fr).stringify_keys, labels["cells"]
    assert_equal I18n.t("map_templates.editor.figures.objects", locale: :fr).stringify_keys, labels["objects"]
  end

  test "a drawing sent by the editor is saved, and the answer says nothing" do
    drawing = layout_with(floors: { "0,0" => "room", "1,0" => "stone" }, edges: { "0,0|1,0" => "door" })
    patch map_template_layout_path(@map_template), params: { layout: drawing.to_json }

    assert_response :no_content
    assert_equal drawing, @map_template.reload.layout
  end

  test "a drawing with objects is saved; an object off the floor is refused" do
    drawing = layout_with(floors: { "0,0" => "room", "1,0" => "room" })
    drawing["objects"] = [{ "key" => "bed", "column" => 0, "row" => 0, "rotation" => 0 }]
    patch map_template_layout_path(@map_template), params: { layout: drawing.to_json }
    assert_response :no_content
    assert_equal drawing, @map_template.reload.layout

    drawing["objects"] = [{ "key" => "bed", "column" => 1, "row" => 0, "rotation" => 0 }]
    patch map_template_layout_path(@map_template), params: { layout: drawing.to_json }
    assert_response :unprocessable_content
  end

  test "the size of the grid is saved with the drawing; a drawing outside the new grid is refused" do
    drawing = layout_with(floors: { "11,0" => "room" })
    patch map_template_layout_path(@map_template), params: { layout: drawing.to_json, columns: "12", rows: "12" }
    assert_response :no_content
    assert_equal [12, 12, drawing], [@map_template.reload.columns, @map_template.rows, @map_template.layout]

    patch map_template_layout_path(@map_template), params: { layout: drawing.to_json, columns: "10", rows: "10" }
    assert_response :unprocessable_content
    assert_equal 12, @map_template.reload.columns
  end

  test "a wrong drawing is refused with its message, and the saved one stays" do
    patch map_template_layout_path(@map_template), params: { layout: layout_with(floors: { "12,0" => "room" }).to_json }

    assert_response :unprocessable_content
    assert_match(/12,0/, response.parsed_body["errors"].to_sentence)
    assert_equal MapTemplate::BLANK_LAYOUT, @map_template.reload.layout
  end

  test "a text that is not JSON, or no drawing at all, is refused" do
    patch map_template_layout_path(@map_template), params: { layout: "{floors" }
    assert_response :unprocessable_content

    patch map_template_layout_path(@map_template)
    assert_response :bad_request
  end

  test "the drawing of another game master's map is not found" do
    other_map = User.create!(email: "autre@example.com", username: "Basile", password: TEST_PASSWORD)
                    .map_templates.create!(name: "Le donjon de Basile")
    patch map_template_layout_path(other_map), params: { layout: layout_with(floors: { "0,0" => "room" }).to_json }

    assert_response :not_found
    assert_equal MapTemplate::BLANK_LAYOUT, other_map.reload.layout
  end

  private

  def layout_with(floors: {}, edges: {})
    MapTemplate::BLANK_LAYOUT.merge("floors" => floors, "edges" => edges)
  end
end
