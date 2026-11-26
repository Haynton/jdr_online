require "test_helper"

# The map on the board of the game room: one of the drawn maps of the table, emptied when that map is deleted
class GameTableBoardMapTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email: "boardkeeper@example.com", username: "boardkeeper", password: TEST_PASSWORD)
    sheet_template = SheetTemplate.create!(name: "Fantasy", locale: "fr")
    @game_table = GameTableCreator.new(user: owner, attributes: { name: "La Crypte" }, sheet_template:).call
    @other_table = GameTableCreator.new(user: owner, attributes: { name: "Le Phare" }, sheet_template:).call
  end

  test "a drawn map of the table goes on the board" do
    @game_table.board_game_map = drawn_map_of(@game_table)

    assert @game_table.valid?, @game_table.errors.full_messages.to_sentence
  end

  test "the board may stay empty" do
    assert_nil @game_table.board_game_map
    assert @game_table.valid?
  end

  test "a map of another table is refused" do
    @game_table.board_game_map = drawn_map_of(@other_table)

    assert @game_table.tap(&:validate).errors.of_kind?(:board_game_map, :not_on_table)
  end

  test "a map sent as an image alone, without a grid, is refused" do
    image_alone = @game_table.game_maps.create!(name: "Plan", image: image_file)
    @game_table.board_game_map = image_alone

    assert @game_table.tap(&:validate).errors.of_kind?(:board_game_map, :not_drawn)
  end

  test "deleting the map on the board empties the board" do
    game_map = drawn_map_of(@game_table)
    @game_table.update!(board_game_map: game_map)

    game_map.destroy!

    assert_nil @game_table.reload.board_game_map
  end

  test "deleting the table deletes its maps, the one on the board too" do
    game_map = drawn_map_of(@game_table)
    @game_table.update!(board_game_map: game_map)

    @game_table.destroy!

    assert_not GameMap.exists?(game_map.id)
  end

  private

  def drawn_map_of(game_table)
    game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10,
                                 layout: MapTemplate::BLANK_LAYOUT.merge("floors" => { "1,1" => "room" }))
  end

  def image_file
    Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/map.png"), "image/png")
  end
end
