require "test_helper"

class BoardTokenTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email: "tokenkeeper@example.com", username: "tokenkeeper", password: TEST_PASSWORD)
    sheet_template = SheetTemplate.create!(name: "Fantasy", locale: "fr")
    @game_table = GameTableCreator.new(user: owner, attributes: { name: "La Crypte" }, sheet_template:).call
    @goblin = @game_table.characters.create!(kind: :monster, name: "Gobelin")
    floors = (0..9).to_a.product((0..9).to_a).to_h { |column, row| ["#{column},#{row}", "room"] }
    @tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10,
                                            layout: MapTemplate::BLANK_LAYOUT.merge("floors" => floors))
  end

  test "an enemy of the table stands on a cell of the map, hidden from the players at first" do
    token = @tavern.board_tokens.create!(character: @goblin, column: 9, row: 0)

    assert token.hidden?
  end

  test "a cell holds one token" do
    @tavern.board_tokens.create!(character: @goblin, column: 2, row: 2)

    assert @tavern.board_tokens.build(character: @goblin, column: 2, row: 2).tap(&:validate)
                  .errors.of_kind?(:base, :cell_taken)
    assert @tavern.board_tokens.build(character: @goblin, column: 3, row: 2).valid?
  end

  test "two tokens put at once on the same cell: the database refuses the second, said as a cell taken" do
    @tavern.board_tokens.create!(character: @goblin, column: 2, row: 2)
    late_token = BoardToken.new(game_map: @tavern, character: @goblin, column: 2, row: 2)
    late_token.define_singleton_method(:cell_free) { nil }

    assert_not late_token.save_on_its_cell
    assert late_token.errors.of_kind?(:base, :cell_taken)
    assert_equal 1, @tavern.board_tokens.count
  end

  test "a token is never put on the empty ground nor on a blocked zone, but one already there may change" do
    @tavern.layout["floors"].delete("5,5")
    @tavern.layout["blocked"] = ["6,6"]
    @tavern.save!

    [[5, 5], [6, 6]].each do |column, row|
      token = BoardToken.new(game_map: @tavern, character: @goblin, column:, row:)
      assert token.tap(&:validate).errors.of_kind?(:base, :cell_blocked), [column, row]
    end
    token = @tavern.board_tokens.create!(character: @goblin, column: 7, row: 7)
    @tavern.update!(layout: @tavern.layout.merge("blocked" => %w[6,6 7,7]))
    assert token.update(hidden: false)
  end

  test "a token named on its own shows its name instead of its number, and its character's name when emptied" do
    @tavern.board_tokens.create!(character: @goblin, column: 1, row: 1, hidden: false)
    token = @tavern.board_tokens.create!(character: @goblin, column: 2, row: 1, hidden: false)
    assert_equal ["Gobelin", 2], [token.displayed_name, token.shown_number]

    token.update!(name: "  Chef gobelin ")
    assert_equal ["Chef gobelin", nil], [token.displayed_name, token.shown_number]

    token.update!(name: "   ")
    assert_equal ["Gobelin", 2], [token.reload.displayed_name, token.shown_number]
  end

  test "renaming a token never changes the numbers of the others, nor the next one given" do
    first, second, third = [1, 2, 3].map do |column|
      @tavern.board_tokens.create!(character: @goblin, column:, row: 1, hidden: false)
    end
    hidden = @tavern.board_tokens.create!(character: @goblin, column: 4, row: 1)

    second.update!(name: "Chef gobelin")
    hidden.update!(name: "Gobelin espion")
    assert_equal [nil, nil, 3], [first, second, third].each(&:reload).map(&:shown_number)
    assert_equal [1, 2, 3], [first, second, third].map(&:number)

    hidden.update!(hidden: false, name: nil)
    assert_equal 4, hidden.reload.shown_number
    second.update!(name: nil)
    assert_equal 2, second.reload.shown_number
  end

  test "a name longer than 60 characters is refused" do
    token = @tavern.board_tokens.create!(character: @goblin, column: 1, row: 1)

    assert_not token.update(name: "a" * 61)
  end

  test "a cell outside the grid is refused" do
    [[10, 0], [0, 10], [-1, 0]].each do |column, row|
      token = @tavern.board_tokens.build(character: @goblin, column:, row:)

      assert_not token.valid?, [column, row]
    end
  end

  test "a character of a player or of another table is refused" do
    other_table = GameTableCreator.new(user: User.first, attributes: { name: "Ailleurs" },
                                       sheet_template: SheetTemplate.create!(name: "Autre", locale: "fr")).call
    strangers = [@game_table.characters.build(kind: :pc, name: "Aria"),
                 other_table.characters.create!(kind: :monster, name: "Loup")]

    strangers.each do |stranger|
      token = @tavern.board_tokens.build(character: stranger, column: 1, row: 1)

      assert token.tap(&:validate).errors.of_kind?(:character, :not_a_creature_of_the_table), stranger.name
    end
  end

  test "the tokens go with their map and with their character" do
    @tavern.board_tokens.create!(character: @goblin, column: 1, row: 1)
    wolf = @game_table.characters.create!(kind: :monster, name: "Loup")
    @tavern.board_tokens.create!(character: wolf, column: 2, row: 1)

    wolf.destroy!
    assert_equal [@goblin], @tavern.board_tokens.reload.map(&:character)

    @tavern.destroy!
    assert_equal 0, BoardToken.count
  end
end
