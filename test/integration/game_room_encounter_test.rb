require "test_helper"

# The panel « Rencontre » of the game master (EncounterBudget, SRD 5.2.1): the budget of each difficulty for the
# finished characters of the players, and the experience points of the NPCs of the table and of its bestiary, by
# their challenge rating; and its rule sheets. A player never gets them
class GameRoomEncounterTest < ActionDispatch::IntegrationTest
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_monsters.fr.json")).call
    @game_table = GameTable.new(name: "La Crypte", starting_level: 3, status: GameTable::READY_STATUS)
    @game_table.use_sheet_template(template)
    @game_table.save!
    @game_master = User.create!(email: "gm@example.com", username: "meneuse", password: TEST_PASSWORD, locale: "fr")
    @game_table.participations.create!(user: @game_master, role: :game_master)
    @players = %w[aria borin].map do |name|
      player = User.create!(email: "#{name}@example.com", username: name, password: TEST_PASSWORD, locale: "fr")
      participation = @game_table.participations.create!(user: player, role: :player)
      participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: name.capitalize,
                                      sheet: { "class" => "Guerrier", "level" => 3 })
      player
    end
    @game_table.characters.create!(kind: :npc, name: "Capitaine Vorn", sheet: { "challenge" => "2" })
  end

  test "the budget adds what each finished character's level gives, the creatures their experience points" do
    budget = EncounterBudget.new(@game_table)

    assert_equal [3, 3], budget.party_levels
    assert_equal [300, 450, 800], budget.difficulties.map(&:budget)
    creatures = budget.creatures
    assert_equal ["Capitaine Vorn", 450], [creatures.first.name, creatures.first.xp]
    goblin = creatures.find { |creature| creature.key == "goblin-warrior" }
    assert_equal ["1/4", 50], [goblin.rating, goblin.xp]
  end

  test "the game master opens the panel « Rencontre », a player never" do
    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "#game-room-panel-encounter" do
      assert_select "p", text: "2 personnages · niveaux 3 et 3"
      assert_select "dd", text: "300 XP"
      assert_select "button[data-key=?][data-xp='450']", "npc-#{@game_table.npcs.first.id}"
    end

    sign_in @players.first
    get game_table_path(@game_table)
    assert_select "#game-room-panel-encounter", count: 0
  end

  test "the game master reads the rule sheets of the template, a player never" do
    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "#game-room-panel-rules" do
      assert_select "h3", text: "Environnement"
      assert_select "summary", text: "Froid extrême"
      assert_select "li[data-search-name*=?]", "froid extreme"
    end

    sign_in @players.first
    get game_table_path(@game_table)
    assert_select "#game-room-panel-rules", count: 0
  end
end
