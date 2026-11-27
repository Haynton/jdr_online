require "test_helper"

# The order of initiative of the strip of the fighters (CombatStrip): each fighter its own roll, enemies of the same
# kind too, the latest roll of the panel « Dés » first, else the simulated one
class CombatStripTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email: "maitre@example.com", username: "maitre", password: TEST_PASSWORD)
    @game_table = GameTableCreator.new(user: owner, attributes: { name: "La Crypte" },
                                       sheet_template: SheetTemplate.create!(name: "Fantasy", locale: "fr")).call
    @first_goblin = @game_table.characters.create!(kind: :monster, name: "Guerrier gobelin")
    @second_goblin = @game_table.characters.create!(kind: :monster, name: "Guerrier gobelin 2")
    tokens = [@first_goblin, @second_goblin].each_with_index.map do |goblin, column|
      { "character_id" => goblin.id, "column" => column, "row" => 0 }
    end
    floors = (0..9).to_a.product((0..9).to_a).to_h { |column, row| ["#{column},#{row}", "room"] }
    tavern = @game_table.game_maps.create!(name: "Taverne", columns: 10, rows: 10,
                                           layout: MapTemplate::BLANK_LAYOUT.merge("floors" => floors,
                                                                                   "tokens" => tokens))
    BoardMapChanger.new(@game_table, tavern).call
    @strip = CombatStrip.new(GameRoom.new(@game_table.participations.find_by(role: :game_master)))
  end

  test "two enemies of the same kind keep their own roll" do
    roll_initiative(@second_goblin, 18)
    roll_initiative(@first_goblin, 3)

    assert_equal [["Guerrier gobelin 2", 18], ["Guerrier gobelin", 3]], initiatives
  end

  test "the latest roll of a fighter counts" do
    roll_initiative(@first_goblin, 3)
    roll_initiative(@first_goblin, 15)
    roll_initiative(@second_goblin, 9)

    assert_equal [["Guerrier gobelin", 15], ["Guerrier gobelin 2", 9]], initiatives
  end

  test "a fighter who has not rolled keeps the simulated roll, never the one of its kind" do
    roll_initiative(@first_goblin, 30)

    assert_not_equal 30, initiatives.to_h.fetch("Guerrier gobelin 2")
  end

  private

  def roll_initiative(character, total)
    ChatMessage.record_event(@game_table, :initiative_rolled, label: "Initiative", character: character.name,
                                                              character_id: character.id, notation: "1d20",
                                                              dice: [total], total: total)
  end

  def initiatives
    @strip.groups.map { |group| [group.name, group.initiative] }
  end
end
