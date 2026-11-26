require "test_helper"

class BoardTokenCopierTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email: "copier@example.com", username: "copier", password: TEST_PASSWORD)
    sheet_template = SheetTemplate.create!(name: "Fantasy", locale: "fr")
    @game_table = GameTableCreator.new(user: owner, attributes: { name: "La Crypte" }, sheet_template:).call
    @goblin = @game_table.characters.create!(kind: :monster, name: "Gobelin")
    @innkeeper = @game_table.characters.create!(kind: :npc, name: "Aubergiste")
    editor_tokens = [{ "character_id" => @goblin.id, "column" => 1, "row" => 1 },
                     { "character_id" => @innkeeper.id, "column" => 2, "row" => 1, "hidden" => false }]
    @tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10,
                                            layout: MapTemplate::BLANK_LAYOUT.merge("tokens" => editor_tokens))
  end

  test "the tokens of the editor go on the board with their starting state" do
    BoardTokenCopier.new(@tavern).call

    copied = @tavern.board_tokens.map { |token| [token.character.name, token.column, token.row, token.hidden] }
    assert_equal [["Gobelin", 1, 1, true], ["Aubergiste", 2, 1, false]], copied
    assert_predicate @tavern.reload, :tokens_copied?
  end

  test "they are copied once: tokens taken off the board never come back" do
    BoardTokenCopier.new(@tavern).call
    @tavern.board_tokens.delete_all

    BoardTokenCopier.new(@tavern.reload).call

    assert_empty @tavern.board_tokens
  end

  test "putting a map on the board for the first time copies its tokens" do
    BoardMapChanger.new(@game_table, @tavern).call

    assert_equal 2, @tavern.board_tokens.count
  end
end
