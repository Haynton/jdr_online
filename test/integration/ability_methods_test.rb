require "test_helper"

# The way to get the scores of the abilities: picked by the game master on the step Settings (or left to the player),
# shown and checked on the abilities step of a character
class AbilityMethodsIntegrationTest < ActionDispatch::IntegrationTest
  ABILITIES = %w[strength dexterity constitution].map do |key|
    { "key" => key, "label" => key.capitalize, "type" => "ability", "min" => 1, "max" => 30,
      "modifier" => "half_above_ten", "section" => "Caractéristiques" }
  end.freeze
  METHODS = [
    { "type" => "roll", "label" => "Lancer de dés", "help" => "4d6, les 3 meilleurs.", "dice" => 4, "sides" => 6 },
    { "type" => "standard_array", "label" => "Tableau standard", "help" => "Placez 15, 12 et 8.",
      "values" => [15, 12, 8] },
    { "type" => "point_buy", "label" => "Achat de points", "help" => "10 points.", "points" => 10,
      "costs" => { "8" => 0, "9" => 1, "10" => 2, "11" => 3, "12" => 4, "13" => 5, "14" => 7, "15" => 9 } }
  ].freeze

  setup do
    @game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD, locale: "fr")
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, template_snapshot: {
                                      "character_fields" => { "ability_methods" => METHODS, "fields" => ABILITIES }
                                    })
    @game_table.participations.create!(user: @game_master, role: :game_master)
    @game_table.participations.create!(user: @player, role: :player)
  end

  test "the game master picks a way, or leaves it to the players; an unknown one is refused" do
    sign_in @game_master
    patch game_table_settings_path(@game_table), params: { game_table: { ability_method_choice: "point_buy" } }
    assert_equal "point_buy", @game_table.reload.ability_method_choice

    patch game_table_settings_path(@game_table), params: { game_table: { ability_method_choice: "player_choice" } }
    assert_predicate @game_table.reload, :players_choose_ability_method?

    patch game_table_settings_path(@game_table), params: { game_table: { ability_method_choice: "tarot" } }
    assert_response :unprocessable_content
  end

  test "the starting equipment has no player's choice: its first way already lets the player pick" do
    @game_table.template_snapshot["character_fields"]["starting_equipment_methods"] =
      [{ "type" => "either", "label" => "Objets ou or" }, { "type" => "gold_only", "label" => "Or seulement" }]
    @game_table.save!
    sign_in @game_master

    patch game_table_settings_path(@game_table), params: { game_table: { starting_equipment_method_choice: "gold_only" } }
    assert_equal "gold_only", @game_table.reload.starting_equipment_method_choice

    patch game_table_settings_path(@game_table),
          params: { game_table: { starting_equipment_method_choice: "player_choice" } }
    assert_response :unprocessable_content
  end

  test "nothing picked, the first way of the template is played" do
    assert_equal "roll", @game_table.ability_method_choice
  end

  test "the standard array offers its values and refuses one placed twice" do
    pick("standard_array")
    sign_in @player
    get game_table_character_step_path(@game_table, "sheet")
    assert_select "[data-controller~=ability-roll][data-ability-roll-preset-value=?]", "[15,12,8]"
    assert_select "button[data-action='ability-roll#roll']", count: 0

    send_scores({ strength: 15, dexterity: 15, constitution: 8 })
    assert_response :unprocessable_content
    assert_select "p", text: "15 est déjà placé sur une autre caractéristique", count: 2

    send_scores({ strength: 15, dexterity: 12, constitution: 8 })
    assert_equal({ "strength" => 15, "dexterity" => 12, "constitution" => 8 }, character.ability_scores)
  end

  test "the point buy counts the points, bounds the scores, and refuses too many points" do
    pick("point_buy")
    sign_in @player
    get game_table_character_step_path(@game_table, "sheet")
    assert_select "p[data-point-buy-target=status]", text: "0 points dépensés sur 10"
    assert_select "input#character_sheet_strength[min='8'][max='15'][data-typed-max='15']"

    send_scores({ strength: 15, dexterity: 12 })
    assert_response :unprocessable_content
    assert_select "p", text: "Retirez 3 points pour continuer."
  end

  test "a player picks their way when the table leaves it to them, and it is checked" do
    pick("player_choice")
    sign_in @player
    get game_table_character_step_path(@game_table, "sheet")
    assert_select "input[type=radio][name='character[ability_method]'][value=roll][checked]"

    send_scores({ strength: 18 }, ability_method: "standard_array")
    assert_response :unprocessable_content
    assert_select "input[type=radio][name='character[ability_method]'][value=standard_array][checked]"
    assert_select "p", text: "à choisir parmi 15, 12, 8"
  end

  test "a draft saved in the background keeps its scores from before when the new ones break the way" do
    pick("standard_array")
    sign_in @player
    send_scores({ strength: 15 })
    patch draft_game_table_character_step_path(@game_table, "sheet"),
          params: { character: { name: "Lia", sheet: { strength: "15", dexterity: "15" } } }

    assert_response :no_content
    assert_equal({ "strength" => 15 }, character.ability_scores)
    assert_equal "Lia", character.name
  end

  test "without rolls again, the server gives back the roll kept; without typing, the scores come from it" do
    pick("roll")
    @game_table.update!(ability_rerolls: false, ability_scores_typed: false)
    sign_in @player
    post game_table_ability_roll_path(@game_table)
    first_roll = response.parsed_body["results"]
    assert response.parsed_body["final"]
    post game_table_ability_roll_path(@game_table)
    assert_equal first_roll, response.parsed_body["results"]

    get game_table_character_step_path(@game_table, "sheet")
    assert_select "input#character_sheet_strength[readonly]"
    totals = first_roll.pluck("total")
    send_scores({ strength: totals.max + 1 })
    assert_response :unprocessable_content
    send_scores({ strength: totals[0], dexterity: totals[1], constitution: totals[2] })
    assert_equal totals.first(3), character.ability_scores.values_at("strength", "dexterity", "constitution")
  end

  test "by default, as the rules: one roll kept, any score typed (real dice); the table may allow rolling again" do
    pick("roll")
    sign_in @player
    post game_table_ability_roll_path(@game_table)
    assert response.parsed_body["final"]
    @game_table.update!(ability_rerolls: true)
    post game_table_ability_roll_path(@game_table)
    assert_not response.parsed_body["final"]
    send_scores({ strength: 3, dexterity: 18 })
    assert_equal({ "strength" => 3, "dexterity" => 18 }, character.ability_scores)
  end

  private

  def pick(type)
    @game_table.update!(ability_method_choice: type)
  end

  def character
    @game_table.characters.find_by!(participation: @game_table.participations.find_by!(user: @player)).reload
  end

  def send_scores(scores, ability_method: nil)
    patch game_table_character_step_path(@game_table, "sheet"),
          params: { character: { name: "Lia", ability_method: ability_method, sheet: scores.transform_values(&:to_s) } }
  end
end
