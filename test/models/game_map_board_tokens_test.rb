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

  test "a token gets its number the first time it is shown, in that order; the first one shows none" do
    first, second, third = place_goblins(3)
    third.update!(hidden: false)
    first.update!(hidden: false)

    assert_equal [2, nil, 1], [first, second, third].each(&:reload).map(&:number)
    assert_equal [2, nil, nil], [first, second, third].map(&:shown_number)
  end

  test "removing a token never renumbers the others, and a number is never given again" do
    first, second, third = place_goblins(3)
    [first, second, third].each { |token| token.update!(hidden: false) }

    second.destroy!
    fourth = place_goblins(1, from_column: 5).first
    fourth.update!(hidden: false)

    assert_equal [1, 3, 4], [first, third, fourth].each(&:reload).map(&:number)
  end

  test "a letter is given once when the token is put, and never moves" do
    first, second, third = place_goblins(3)
    first.destroy!
    third.update!(hidden: false)
    third.update!(hidden: true)

    assert_equal %w[B C], [second, third].each(&:reload).map(&:letter)
    assert_equal "D", place_goblins(1, from_column: 5).first.letter
  end

  test "each token of the map has its own letter, whatever its character; the numbers stay by character" do
    wolf = @game_table.characters.create!(kind: :monster, name: "Loup")
    goblin = place_goblins(1).first
    wolves = [2, 3].map { |column| @tavern.board_tokens.create!(character: wolf, column:, row: 1, hidden: false) }
    goblin.update!(hidden: false)

    assert_equal %w[A B C], [goblin, *wolves].map(&:letter)
    assert_equal [1, 1, 2], [goblin, *wolves].each(&:reload).map(&:number)
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

  test "an enemy renamed or turned into an NPC changes on the board of the players at once, if it stands on it" do
    @tavern.board_tokens.create!(character: @goblin, column: 1, row: 1, hidden: false)
    @game_table.update!(board_game_map: @tavern)
    wolf = @game_table.characters.create!(kind: :monster, name: "Loup")

    assert_turbo_stream_broadcasts(@game_table, count: 2) do
      @goblin.update!(name: "Chef de guerre")
      @goblin.update!(kind: :npc)
    end
    unseen_changes = capture_turbo_stream_broadcasts(@game_table) do
      @goblin.update!(gm_notes: "Lâche")
      wolf.update!(name: "Grand loup")
    end
    assert_empty unseen_changes
  end

  test "the map of the board deleted: the board goes empty for the players and for the game master at once" do
    @game_table.update!(board_game_map: @tavern)
    other_map = @game_table.game_maps.create!(name: "Cave", columns: 10, rows: 10, layout: MapTemplate::BLANK_LAYOUT)

    assert_empty(capture_turbo_stream_broadcasts(@game_table) { other_map.destroy! })
    players = capture_turbo_stream_broadcasts(@game_table) do
      assert_turbo_stream_broadcasts([@game_table, GameTableChannel::GAME_MASTER_AUDIENCE], count: 1) do
        @tavern.destroy!
      end
    end
    assert_equal(["game-room-board-player"], players.map { |stream| stream["target"] })
    assert_nil @game_table.reload.board_game_map
  end

  private

  def place_goblins(count, from_column: 1)
    columns = from_column...(from_column + count)
    columns.map { |column| @tavern.board_tokens.create!(character: @goblin, column:, row: 1) }
  end
end
