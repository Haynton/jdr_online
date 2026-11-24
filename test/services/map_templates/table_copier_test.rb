require "test_helper"

# A map of « Mes cartes » copied into a table: its grid, its whole drawing (the properties of each cell, for the board)
# and its picture, a file of its own; the table keeps its copy when the original changes or goes
module MapTemplates
  class TableCopierTest < ActiveSupport::TestCase
    setup do
      @owner = User.create!(email: "cartographer@example.com", username: "cartographer", password: TEST_PASSWORD)
      @game_table = GameTableCreator.new(user: @owner, attributes: { name: "La Crypte" },
                                         sheet_template: SheetTemplate.create!(name: "Fantasy", locale: "fr")).call
      @drawing = MapTemplate::BLANK_LAYOUT.merge(
        "floors" => { "1,1" => "room", "2,1" => "room" }, "edges" => { "1,1|2,1" => "door" },
        "objects" => [{ "key" => "table", "column" => 1, "row" => 1, "rotation" => 0 }]
      )
      @map_template = @owner.map_templates.create!(name: "La taverne", columns: 20, rows: 15, layout: @drawing)
    end

    test "the copy keeps the name, the grid and every cell of the drawing" do
      game_map = TableCopier.new(@map_template, @game_table).call

      assert_equal [@game_table, @map_template, "La taverne", 20, 15],
                   [game_map.game_table, game_map.map_template, game_map.name, game_map.columns, game_map.rows]
      assert_equal @drawing, game_map.layout
      assert_not game_map.image.attached?
    end

    test "the copy does not follow the original" do
      game_map = TableCopier.new(@map_template, @game_table).call
      @map_template.update!(name: "Renommée", layout: MapTemplate::BLANK_LAYOUT)

      assert_equal ["La taverne", @drawing], game_map.reload.slice(:name, :layout).values
      @map_template.destroy!
      assert_nil game_map.reload.map_template
    end

    test "a map played on a picture is copied with a picture of its own" do
      @map_template.use_picture(io: file_fixture("map.png").open, filename: "map.png", content_type: "image/png")
      @map_template.save!

      game_map = TableCopier.new(@map_template, @game_table).call

      assert_predicate game_map, :on_picture?
      assert_predicate game_map.image, :attached?
      assert_not_equal @map_template.picture.blob, game_map.image.blob
      assert_equal @map_template.picture.download, game_map.image.download
    end
  end
end
