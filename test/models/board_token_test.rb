require "test_helper"

class BoardTokenTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email: "tokenkeeper@example.com", username: "tokenkeeper", password: TEST_PASSWORD)
    sheet_template = SheetTemplate.create!(name: "Fantasy", locale: "fr")
    @game_table = GameTableCreator.new(user: owner, attributes: { name: "La Crypte" }, sheet_template:).call
    @goblin = @game_table.characters.create!(kind: :monster, name: "Gobelin")
    @tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10, layout: MapTemplate::BLANK_LAYOUT)
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
