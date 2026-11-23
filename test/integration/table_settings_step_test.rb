require "test_helper"

# The second step of the creation of a table: the settings that depend on the template chosen (the starting level)
class TableSettingsStepTest < ActionDispatch::IntegrationTest
  LEVELLED_FIELDS = [
    { "key" => "level", "label" => "Niveau", "type" => "number", "from_table" => "starting_level", "section" => "Identité" }
  ].freeze

  setup do
    @user = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @levelled = SheetTemplate.create!(name: "Fantasy héroïque", locale: "fr",
                                      character_fields: { "fields" => LEVELLED_FIELDS })
    @game_table = GameTableCreator.new(user: @user, attributes: { name: "Les Marches du Nord" },
                                       sheet_template: @levelled).call
    @game_table.reach_creation_step("settings")
    sign_in @user
  end

  test "a template with levels asks the starting level between minus and plus, then whether players choose theirs" do
    get edit_game_table_settings_path(@game_table)

    assert_response :success
    assert_select "ol[aria-label] > li[aria-current=step]", text: /Réglages/
    assert_select "[data-controller=number-stepper]" do
      assert_select "input[type=number]#game_table_starting_level[min='1'][max='20'][value='1']" \
                    "[aria-describedby='starting-level-hint']"
      assert_select "button[hidden][aria-label=?]", "Diminuer Niveau de départ"
      assert_select "button[hidden][aria-label=?]", "Augmenter Niveau de départ"
    end
    # The whole line is the label of the switch: a click anywhere on it turns it on or off
    assert_select "label[for=game_table_players_choose_level]", text: /Les joueurs choisissent leur niveau/ do
      assert_select "input[type=checkbox][role=switch]#game_table_players_choose_level:not([checked])"
    end
    assert_select "a[href=?]", edit_game_table_details_path(@game_table), text: "Retour"
  end

  test "the functions of the AI are announced, disabled, and send nothing" do
    get edit_game_table_settings_path(@game_table)

    assert_select "section[aria-labelledby=ai-settings-title]" do
      assert_select "h2", text: "Fonctions IA"
      assert_select "input[type=checkbox][role=switch][disabled]:not([name])", count: 4
      assert_select "span", text: "Bientôt", count: 4
      assert_select "span#ai-session_summary-label", text: "Résumé de séance"
    end
  end

  test "the rules of the game are announced, disabled, with the rule played today first, and send nothing" do
    get edit_game_table_settings_path(@game_table)

    assert_select "select[disabled]:not([name])", count: 5
    assert_select "select[aria-labelledby=rules-ability_method-label] option:first-child",
                  text: "Lancer de dés"
    assert_select "section[aria-labelledby=game-settings-title]" do
      assert_select "h2", text: "Partie"
      assert_select "input[type=checkbox][role=switch][disabled][aria-labelledby=rules-encumbrance-label]:not([name])"
    end
  end

  test "the switch is saved with the level" do
    patch game_table_settings_path(@game_table), params: { game_table: { starting_level: "2", players_choose_level: "1" } }

    assert @game_table.reload.players_choose_level
    assert_equal 2, @game_table.starting_level
  end

  test "continue saves the starting level and opens the summary" do
    patch game_table_settings_path(@game_table), params: { game_table: { starting_level: "3" } }

    assert_redirected_to game_table_summary_path(@game_table)
    assert_equal 3, @game_table.reload.starting_level
    assert_equal "summary", @game_table.resume_creation_step
  end

  test "a starting level out of bounds is refused" do
    patch game_table_settings_path(@game_table), params: { game_table: { starting_level: "25" } }

    assert_response :unprocessable_content
    assert_select "input#game_table_starting_level[aria-invalid=true][aria-describedby='starting-level-error starting-level-hint']"
    assert_select "#starting-level-error"
    assert_equal 1, @game_table.reload.starting_level
  end

  test "a template without levels asks no level, and continue still opens the summary" do
    @game_table.use_sheet_template(SheetTemplate.create!(name: "Horreur cosmique", locale: "fr"))
    @game_table.save!
    get edit_game_table_settings_path(@game_table)

    assert_select "input#game_table_starting_level", count: 0
    assert_select "h2", text: "Personnages", count: 0
    assert_select "h2", text: "Partie", count: 0
    assert_select "h2", text: "Fonctions IA"
    patch game_table_settings_path(@game_table)
    assert_redirected_to game_table_summary_path(@game_table)
  end

  test "only the game master of a draft reaches the settings" do
    other_user = User.create!(email: "other@example.com", username: "other", password: TEST_PASSWORD)
    sign_in other_user
    get edit_game_table_settings_path(@game_table)
    assert_response :not_found

    @game_table.finish_creation!
    sign_in @user
    get edit_game_table_settings_path(@game_table)
    assert_response :not_found
  end
end
