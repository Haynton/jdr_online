require "test_helper"

# A character created above level 1 takes, at the step of the feats, the feats of the levels its class improves (the
# fighter at level 8: those of levels 4 and 6, then 8), as at a level gained: the Ability Score Improvement by default,
# its points counted in the scores; a class or a level that no longer gives a level drops its feat
class CreationLevelFeatsTest < ActionDispatch::IntegrationTest
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_features.fr.json")).call
    @game_table = GameTable.new(name: "La Crypte", starting_level: 6, status: GameTable::READY_STATUS,
                                origin_feats: false)
    @game_table.use_sheet_template(template)
    @game_table.save!
    @player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD, locale: "fr")
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(
      game_table: @game_table, kind: :pc, status: :draft, creation_step: "feats",
      sheet: { "class" => "Guerrier", "subclass" => "Champion", "background" => "Soldat", "level" => 6,
               "strength" => 15, "constitution" => 14 }
    )
  end

  test "a fighter of level 6 takes the feats of levels 4 and 6, even when the table plays no origin feats" do
    sign_in @player
    get game_table_character_step_path(@game_table, "feats")

    assert_select "legend", text: "Don du niveau 4"
    assert_select "legend", text: "Don du niveau 6"
    assert_select "input[name='character[level_feats][4][feat_key]'][value=?][checked]", "ability-score-improvement"

    patch game_table_character_step_path(@game_table, "feats"),
          params: { character: { level_feats: { "4" => { feat_key: "ability-score-improvement",
                                                         ability_increases: { "strength" => "2" } },
                                                "6" => { feat_key: "ability-score-improvement",
                                                         ability_increases: { "strength" => "1",
                                                                              "constitution" => "1" } } } } }
    @character.reload
    assert_equal [4, 6], @character.feats.pluck("level")
    assert_equal [18, 15], @character.computed_sheet_values[:scores].values_at("strength", "constitution")
  end

  test "points not shared are refused, with the level in the message" do
    sign_in @player
    patch game_table_character_step_path(@game_table, "feats"),
          params: { character: { level_feats: { "4" => { feat_key: "ability-score-improvement",
                                                         ability_increases: { "strength" => "1" } } } } }

    assert_response :unprocessable_content
    assert_select "#level_feat_4_ability_increases_error"
  end

  test "a lower level drops the feats of the levels it no longer reaches" do
    improvement = "ability-score-improvement"
    @character.update!(feats: [{ "key" => improvement, "level" => 4, "abilities" => { "strength" => 2 } },
                               { "key" => improvement, "level" => 6, "abilities" => { "strength" => 1 } }])
    @character.sheet = @character.sheet.merge("level" => 5)
    @character.keep_offered_level_feats

    assert_equal [4], @character.feats.pluck("level")
  end

  test "a character of level 3 has no feat of a level to take" do
    @character.update!(sheet: @character.sheet.merge("level" => 3))

    assert_empty @character.creation_feats
  end
end
