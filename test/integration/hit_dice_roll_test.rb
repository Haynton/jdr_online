require "test_helper"

# The hit points of the levels after the first: the way the table picks (or leaves to the player), the hit dice rolled
# once on the summary of the character, and a roll the table imposes required to finish it
class HitDiceRollTest < ActionDispatch::IntegrationTest
  FIELDS = [
    { "key" => "class", "label" => "Classe", "type" => "choice", "section" => "Personnage", "options" => ["Guerrier"],
      "effects" => { "Guerrier" => { "hit_die" => 10 } } },
    { "key" => "constitution", "label" => "Constitution", "type" => "ability", "modifier" => "half_above_ten",
      "section" => "Personnage" },
    { "key" => "level", "label" => "Niveau", "type" => "number", "min" => 1, "max" => 20, "section" => "Combat" },
    { "key" => "max_hp", "label" => "Points de vie", "type" => "computed", "rule" => "hit_points_by_level",
      "class_from" => "class", "level_from" => "level", "based_on" => "constitution", "section" => "Combat" },
    { "key" => "hp", "label" => "Points de vie", "type" => "resource", "at_creation" => false,
      "initial_from" => "max_hp", "section" => "Combat" }
  ].freeze
  METHODS = [{ "type" => "average", "label" => "Moyenne du dé de vie" },
             { "type" => "roll", "label" => "Lancer du dé de vie" }].freeze

  setup do
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD, locale: "fr")
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, template_snapshot: {
                                      "character_fields" => { "hit_point_methods" => METHODS, "fields" => FIELDS }
                                    })
    @game_table.participations.create!(user: game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(game_table: @game_table, name: "Aldric", status: "draft",
                                                 creation_step: "summary",
                                                 sheet: { "class" => "Guerrier", "constitution" => 14, "level" => 3 })
    sign_in @player
  end

  test "with the average, nothing to roll: the hit points count it" do
    get summary_path

    assert_select "button", text: /Lancer les dés de vie/, count: 0
    assert_equal "28", max_hit_points
  end

  test "left to the player, the average counts until they roll once; the rolls stay" do
    @game_table.update!(hit_point_method_choice: "player_choice")
    get summary_path
    assert_select "p", text: /comptent la moyenne/
    assert_select "form[action=?] button", game_table_hit_dice_roll_path(@game_table), text: /Lancer les dés de vie/

    post game_table_hit_dice_roll_path(@game_table)
    assert_redirected_to summary_path
    rolls = @character.reload.hit_point_rolls
    assert_equal [10, 2], [rolls["sides"], rolls["results"].size]
    assert_equal "roll", @character.hit_point_method
    assert_equal (12 + rolls["results"].sum { |roll| roll + 2 }).to_s, max_hit_points

    post game_table_hit_dice_roll_path(@game_table)
    assert_response :not_found
    assert_equal rolls, @character.reload.hit_point_rolls
  end

  test "imposed by the table, the hit points wait for the roll, and the character cannot be finished without it" do
    @game_table.update!(hit_point_method_choice: "roll")
    assert_nil max_hit_points

    patch summary_path
    assert_response :unprocessable_content
    assert_select "p", text: "Lancez vos dés de vie avant de terminer."
    assert_predicate @character.reload, :draft?

    post game_table_hit_dice_roll_path(@game_table)
    patch summary_path
    assert_predicate @character.reload, :complete?
    assert_equal @character.sheet["hp"]["max"].to_s, max_hit_points
  end

  test "a roll holds while the class and the level stay" do
    @game_table.update!(hit_point_method_choice: "roll")
    @character.update!(hit_point_rolls: { "sides" => 10, "results" => [4, 5] })
    assert_equal [4, 5], @character.kept_hit_point_rolls

    @character.update!(sheet: @character.sheet.merge("level" => 4))
    assert_nil @character.kept_hit_point_rolls
  end

  private

  def summary_path
    game_table_character_step_path(@game_table, "summary")
  end

  def max_hit_points
    @character.reload.computed_sheet_values[:values]["max_hp"]
  end
end
