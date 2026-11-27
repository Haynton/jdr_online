require "test_helper"

# The tokens put on a map of a table (MapLayouts::TokensCheck, GameMap#placed_tokens): non-player characters and
# enemies of the table, as many of each as wanted, one per cell; gone with the character they stand for
class MapTokensTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email: "cartographer@example.com", username: "cartographer", password: TEST_PASSWORD)
    @game_table = GameTableCreator.new(user: owner, attributes: { name: "La Crypte" },
                                       sheet_template: SheetTemplate.create!(name: "Fantasy", locale: "fr")).call
    @goblin = @game_table.characters.create!(kind: :monster, name: "Gobelin")
    @innkeeper = @game_table.characters.create!(kind: :npc, name: "Aubergiste")
  end

  test "a band of the same enemy is accepted, each token numbered for the board" do
    game_map = map_with(tokens: [token(@goblin, 1, 1), token(@innkeeper, 2, 1), token(@goblin, 3, 1)])

    assert game_map.valid?, game_map.errors.full_messages.to_sentence
    placed = game_map.placed_tokens.map { |token| [token[:character].name, *token.values_at(:column, :row, :number)] }
    assert_equal [["Gobelin", 1, 1, 1], ["Aubergiste", 2, 1, 1], ["Gobelin", 3, 1, 2]], placed
  end

  test "a token of another table, outside the grid, on a taken cell or of a wrong form is refused" do
    stranger = User.create!(email: "other@example.com", username: "autre", password: TEST_PASSWORD)
    other_table = GameTableCreator.new(user: stranger, attributes: { name: "Ailleurs" },
                                       sheet_template: SheetTemplate.create!(name: "Autre", locale: "fr")).call
    other_goblin = other_table.characters.create!(kind: :monster, name: "Gobelin")
    refused = { [token(other_goblin, 1, 1)] => :unknown_token_character,
                [token(@goblin, 10, 1)] => :token_outside_grid,
                [token(@goblin, 1, 1), token(@innkeeper, 1, 1)] => :tokens_overlap,
                [{ "character_id" => @goblin.id, "column" => "1", "row" => 1 }] => :invalid_token }

    refused.each do |tokens, error|
      assert map_with(tokens:).tap(&:validate).errors.of_kind?(:layout, error), error
    end
  end

  test "a token says whether it starts hidden from the players, hidden when it says nothing" do
    shown = token(@goblin, 1, 1).merge("hidden" => false)
    game_map = map_with(tokens: [shown, token(@innkeeper, 2, 1).merge("hidden" => true), token(@goblin, 3, 1)])

    assert game_map.valid?, game_map.errors.full_messages.to_sentence
    assert_equal [false, true, true], game_map.placed_tokens.pluck(:hidden)
  end

  test "a complete player character stands on a map once, shown at first; one still in creation is refused" do
    aria = player_character("Aria")
    draft = player_character("Brouillon", status: :draft)
    game_map = map_with(tokens: [token(aria, 1, 1), token(@goblin, 2, 1)])

    assert game_map.valid?, game_map.errors.full_messages.to_sentence
    assert_equal [false, true], game_map.placed_tokens.pluck(:hidden)
    refused = { [token(aria, 1, 1), token(aria, 2, 1)] => :player_character_twice,
                [token(draft, 1, 1)] => :unknown_token_character }
    refused.each do |tokens, error|
      assert map_with(tokens:).tap(&:validate).errors.of_kind?(:layout, error), error
    end
  end

  test "a token hidden by something else than true or false, or with an unknown key, is refused" do
    [token(@goblin, 1, 1).merge("hidden" => "oui"), token(@goblin, 1, 1).merge("hidden" => nil),
     token(@goblin, 1, 1).merge("conditions" => [])].each do |refused_token|
      assert map_with(tokens: [refused_token]).tap(&:validate).errors.of_kind?(:layout, :invalid_token), refused_token
    end
  end

  test "a token never stands on a blocked zone painted by the game master" do
    game_map = map_with(tokens: [token(@goblin, 1, 1)])
    game_map.layout["blocked"] = ["1,1"]

    assert game_map.tap(&:validate).errors.of_kind?(:layout, :token_on_blocked_cell)
  end

  test "a map of « Mes cartes » has no token" do
    map_template = MapTemplate.new(name: "Carte", owner: User.first, columns: 10, rows: 10,
                                   layout: MapTemplate::BLANK_LAYOUT.merge("tokens" => [token(@goblin, 1, 1)]))

    assert map_template.tap(&:validate).errors.of_kind?(:layout, :tokens_without_table)
  end

  test "an enemy deleted leaves the maps of its table" do
    game_map = map_with(tokens: [token(@goblin, 1, 1), token(@innkeeper, 2, 1)])
    game_map.save!

    @goblin.destroy!

    assert_equal [@innkeeper.id], game_map.reload.layout["tokens"].pluck("character_id")
  end

  private

  def player_character(name, status: :complete)
    player = User.create!(email: "#{name.downcase}@example.com", username: name.downcase, password: TEST_PASSWORD)
    participation = @game_table.participations.create!(user: player, role: :player)
    participation.create_character!(game_table: @game_table, kind: :pc, status:, name:)
  end

  def map_with(tokens:)
    @game_table.game_maps.build(name: "Taverne", columns: 10, rows: 10,
                                layout: MapTemplate::BLANK_LAYOUT.merge("tokens" => tokens))
  end

  def token(character, column, row)
    { "character_id" => character.id, "column" => column, "row" => row }
  end
end
