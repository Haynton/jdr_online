require "test_helper"

# A map of a table: a copy of a map of « Mes cartes » (its grid and its drawing, checked like the original), or an
# image alone, sent before the editor
class GameMapTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email: "cartographer@example.com", username: "cartographer", password: TEST_PASSWORD)
    @game_table = GameTableCreator.new(user: owner, attributes: { name: "La Crypte" },
                                       sheet_template: SheetTemplate.create!(name: "Fantasy", locale: "fr")).call
  end

  test "a drawn map needs no image, and its drawing is checked against its grid" do
    drawn = @game_table.game_maps.build(name: "Taverne", columns: 10, rows: 10,
                                        layout: MapTemplate::BLANK_LAYOUT.merge("floors" => { "1,1" => "room" }))
    assert drawn.valid?, drawn.errors.full_messages.to_sentence
    assert_predicate drawn, :drawn?

    drawn.layout = MapTemplate::BLANK_LAYOUT.merge("floors" => { "12,1" => "room" })
    assert drawn.tap(&:validate).errors.of_kind?(:layout, :cell_outside_grid)
  end

  test "a drawn map has a grid of 10 to 60 cells a side" do
    too_small = @game_table.game_maps.build(name: "Cave", columns: 9, rows: 10, layout: MapTemplate::BLANK_LAYOUT)

    assert too_small.tap(&:validate).errors.of_kind?(:columns, :in)
  end

  test "a map without a drawing needs its image, like before" do
    image_alone = @game_table.game_maps.build(name: "Plan")

    assert image_alone.tap(&:validate).errors.of_kind?(:image, :blank)
    assert_not image_alone.drawn?
  end
end
