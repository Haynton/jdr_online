require "test_helper"
require "turbo/broadcastable/test_helper"

class GameMapBoardTokensTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup do
    owner = User.create!(email: "numberer@example.com", username: "numberer", password: TEST_PASSWORD)
    sheet_template = SheetTemplate.create!(name: "Fantasy", locale: "fr")
    @game_table = GameTableCreator.new(user: owner, attributes: { name: "La Crypte" }, sheet_template:).call
    @goblin = @game_table.characters.create!(kind: :monster, name: "Gobelin")
    floors = (0..9).to_a.product((0..9).to_a).to_h { |column, row| ["#{column},#{row}", "room"] }
    @tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10,
                                            layout: MapTemplate::BLANK_LAYOUT.merge("floors" => floors))
  end

  test "the numbers follow the order in which the tokens are shown, the hidden ones after them" do
    first, second, third = [1, 2, 3].map { |column| @tavern.board_tokens.create!(character: @goblin, column:, row: 1) }
    third.update!(hidden: false)
    first.update!(hidden: false)

    numbers = @tavern.numbered_board_tokens.to_h { |token, number| [token, number] }
    assert_equal({ third => 1, first => 2, second => 3 }, numbers)
  end

  test "a number never changes once the token has been shown" do
    first, second = [1, 2].map { |column| @tavern.board_tokens.create!(character: @goblin, column:, row: 1) }
    second.update!(hidden: false)
    first.update!(hidden: false)
    second.update!(hidden: true)

    assert_equal 1, @tavern.numbered_board_tokens.to_h.fetch(second)
  end

  test "a smaller grid takes away the tokens outside it and tells the players" do
    wide_floors = (0..11).to_a.product((0..9).to_a).to_h { |column, row| ["#{column},#{row}", "room"] }
    @tavern.update!(columns: 12, layout: @tavern.layout.merge("floors" => wide_floors))
    @tavern.board_tokens.create!(character: @goblin, column: 11, row: 1)
    kept = @tavern.board_tokens.create!(character: @goblin, column: 1, row: 1)
    @game_table.update!(board_game_map: @tavern)
    narrow_floors = wide_floors.select { |cell, _floor| cell.split(",").first.to_i < 10 }

    assert_turbo_stream_broadcasts(@game_table, count: 1) do
      @tavern.update!(columns: 10, layout: @tavern.layout.merge("floors" => narrow_floors))
    end
    assert_equal [kept], @tavern.board_tokens.reload
  end

  test "an enemy deleted leaves the board of the players at once" do
    @tavern.board_tokens.create!(character: @goblin, column: 1, row: 1)
    @game_table.update!(board_game_map: @tavern)

    assert_turbo_stream_broadcasts(@game_table, count: 1) do
      @goblin.destroy!
    end
    assert_empty @tavern.board_tokens.reload
  end
end
