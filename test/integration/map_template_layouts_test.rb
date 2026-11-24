require "test_helper"

# The map editor saves the drawing of a map after each stroke (MapTemplates::LayoutsController): the layout comes as
# a JSON text, checked by MapLayoutValidator. Only on a map of one's own
class MapTemplateLayoutsTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = User.create!(email: "mj@example.com", username: "Morgane", password: TEST_PASSWORD, locale: "fr")
    @map_template = @game_master.map_templates.create!(name: "La taverne", columns: 10, rows: 10)
    sign_in @game_master
  end

  test "the page of a map holds the editor, hidden until its controller shows it, with the drawing and the tools" do
    @map_template.update!(layout: layout_with(floors: { "1,1" => "room" }))
    get edit_map_template_path(@map_template)

    assert_select "#map-editor[data-turbo-permanent][data-controller=map-editor]" \
                  "[data-map-editor-url-value=?][data-map-editor-columns-value='10']",
                  map_template_layout_path(@map_template)
    assert_includes css_select("#map-editor").first["data-map-editor-layout-value"], '"1,1":"room"'
    assert_select "#map-editor [data-map-editor-target=editor][hidden]"
    assert_select "button[data-map-editor-target=tool][data-tool-kind=floor]", count: MapFloors.keys.size
    assert_select "button[data-map-editor-target=tool][data-tool-kind=edge]", count: MapEdges.keys.size
    assert_select "button[data-tool-kind=floor][data-tool-key=room]", text: "Salle"
    assert_select "button[data-tool-kind=edge][data-tool-key=door]", text: "Porte"
    assert_select "button[data-tool-kind=eraser]", text: "Gomme"
  end

  test "a drawing sent by the editor is saved, and the answer says nothing" do
    drawing = layout_with(floors: { "0,0" => "room", "1,0" => "stone" }, edges: { "0,0|1,0" => "door" })
    patch map_template_layout_path(@map_template), params: { layout: drawing.to_json }

    assert_response :no_content
    assert_equal drawing, @map_template.reload.layout
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
