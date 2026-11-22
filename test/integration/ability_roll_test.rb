require "test_helper"

class AbilityRollTest < ActionDispatch::IntegrationTest
  ABILITIES = %w[strength dexterity constitution].map do |key|
    { "key" => key, "label" => key.capitalize, "type" => "ability", "min" => 1, "max" => 30,
      "modifier" => "half_above_ten", "section" => "Caractéristiques" }
  end.freeze

  setup do
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, template_snapshot: {
                                      "character_fields" => {
                                        "ability_roll" => { "dice" => 4, "sides" => 6, "keep_highest" => 3 },
                                        "fields" => ABILITIES
                                      }
                                    })
    @game_table.participations.create!(user: game_master, role: :game_master)
    @game_table.participations.create!(user: @player, role: :player)
  end

  test "the server rolls one score per ability, with its dice" do
    sign_in @player
    post game_table_ability_roll_path(@game_table), as: :json

    results = response.parsed_body["results"]
    assert_equal 3, results.size
    results.each { |result| assert_equal result["kept"].sum, result["total"] }
  end

  test "the sheet offers the roll, its method, and a list to place a result on each ability" do
    sign_in @player
    get new_game_table_character_path(@game_table)

    assert_select "[data-controller~=ability-roll][data-ability-roll-url-value=?]",
                  game_table_ability_roll_path(@game_table)
    assert_select "button[data-action='ability-roll#roll']", text: /Lancer les dés/
    assert_select "p", text: /4d6 par caractéristique, en gardant les 3 meilleurs/
    assert_select "select[aria-label=?][data-score-input=character_sheet_strength]:not([name])",
                  "Attribuer un résultat à Strength"
  end

  test "without a roll method in the template, there is nothing to roll" do
    @game_table.update!(template_snapshot: { "character_fields" => { "fields" => ABILITIES } })
    sign_in @player
    get new_game_table_character_path(@game_table)
    assert_select "[data-controller~=ability-roll]", count: 0

    post game_table_ability_roll_path(@game_table), as: :json
    assert_response :not_found
  end

  test "only a player of the table rolls" do
    sign_in @game_table.participations.game_master.first.user
    post game_table_ability_roll_path(@game_table), as: :json

    assert_response :not_found
  end
end
