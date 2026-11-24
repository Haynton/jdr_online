require "test_helper"

# A map played on a picture of one's own (MapTemplates::PicturesController): sent from the tab Image of the editor,
# a picture of the formats a browser shows; the map switches to the mode "picture". Only on a map of one's own
class MapTemplatePicturesTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = User.create!(email: "mj@example.com", username: "Morgane", password: TEST_PASSWORD, locale: "fr")
    @map_template = @game_master.map_templates.create!(name: "La taverne", columns: 20, rows: 15)
    sign_in @game_master
  end

  test "a picture sent is kept, the map is played on it, laid as wide as the grid" do
    post map_template_picture_path(@map_template), params: { map_template: { picture: picture_file } }

    assert_redirected_to edit_map_template_path(@map_template)
    @map_template.reload
    assert_predicate @map_template.picture, :attached?
    assert_equal "picture", @map_template.layout["mode"]
    assert_equal MapTemplate.picture_settings_for(20), @map_template.layout["picture"]
  end

  test "the editor of a map on a picture shows its tab Image, its picture and how to set the grid" do
    @map_template.use_picture(picture_file)
    @map_template.save!
    get edit_map_template_path(@map_template)

    assert_select "header input[name=map-making][value=picture][checked]"
    assert_select "[data-map-editor-target=drawingPanel][hidden]"
    assert_select "[data-map-editor-target=picturePanel]:not([hidden]) input#map-picture-width"
    assert_select "main[data-map-editor-picture-url-value*=?]", "map.png"
    assert_select "[data-map-editor-target=picturePanel] form[action=?] button[data-turbo-confirm]",
                  map_template_picture_path(@map_template)
  end

  test "a file that is not a picture is refused, said in a bubble" do
    post map_template_picture_path(@map_template),
         params: { map_template: { picture: fixture_file_upload("notes.txt", "text/plain") } }

    assert_redirected_to edit_map_template_path(@map_template)
    assert_match "PNG, JPEG ou WebP", flash[:alert]
    assert_not @map_template.reload.picture.attached?
    assert_nil @map_template.layout["mode"]
  end

  test "taking the picture away keeps the map on its mode and its settings" do
    @map_template.use_picture(picture_file)
    @map_template.save!

    delete map_template_picture_path(@map_template)

    assert_redirected_to edit_map_template_path(@map_template)
    assert_not @map_template.reload.picture.attached?
    assert_equal "picture", @map_template.layout["mode"]
  end

  test "the map of another game master is not found" do
    map_of_another = User.create!(email: "autre@example.com", username: "Basile", password: TEST_PASSWORD)
                         .map_templates.create!(name: "Le donjon de Basile")

    post map_template_picture_path(map_of_another), params: { map_template: { picture: picture_file } }

    assert_response :not_found
    assert_not map_of_another.reload.picture.attached?
  end

  private

  def picture_file
    fixture_file_upload("map.png", "image/png")
  end
end
