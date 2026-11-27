require "test_helper"

# The feats of the heroic fantasy (SRD 5.2.1): those a character may take at a level that improves its abilities (their
# level, their ability minimum, the effect they need, an epic boon at 19), and what they do once taken: points to the
# abilities kept apart, the proficiency to the initiative of Alert, the fighting style of a fighting style feat
class FeatsTest < ActiveSupport::TestCase
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_features.fr.json")).call
    @game_table = GameTable.new(name: "La Crypte", starting_level: 4)
    @game_table.use_sheet_template(template)
    @game_table.save!
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    @participation = @game_table.participations.create!(user: player, role: :player)
  end

  test "a level 4 offers the improvement, the grappler with 13 in Strength, fighting styles to a class that has some" do
    fighter = build_character("class" => "Guerrier", "subclass" => "Champion", "strength" => 13, "dexterity" => 10)
    keys = fighter.feat_list.offered(level: 4).map(&:key)
    assert_includes keys, "ability-score-improvement"
    assert_includes keys, "grappler"
    assert_includes keys, "defense"
    assert_not_includes keys, "boon-of-fate"

    wizard = build_character("class" => "Magicien", "strength" => 8, "dexterity" => 12)
    keys = wizard.feat_list.offered(level: 4).map(&:key)
    assert_not_includes keys, "grappler"
    assert_not_includes keys, "defense"
    assert_includes wizard.feat_list.offered(level: 19, epic: true).map(&:key), "boon-of-spell-recall"
  end

  test "a feat taken adds its points apart from the score, and is not offered again unless it repeats" do
    character = build_character("class" => "Guerrier", "strength" => 15, "dexterity" => 13,
                                "feats" => [{ "key" => "grappler", "level" => 4, "abilities" => { "strength" => 1 } }])
    assert_equal [15, 16], [character.sheet["strength"], character.computed_sheet_values[:scores]["strength"]]
    assert_not_includes character.feat_list.offered(level: 8).map(&:key), "grappler"
    assert_includes character.feat_list.offered(level: 8).map(&:key), "ability-score-improvement"
  end

  test "Alert adds the proficiency to the initiative, a fighting style feat its effect" do
    criminal = build_character("class" => "Roublard", "background" => "Criminel", "dexterity" => 14)
    assert_equal 2 + 2, criminal.computed_sheet_values[:values]["initiative"]

    fighter = build_character("class" => "Guerrier", "feats" => [{ "key" => "archery", "level" => 4 }])
    assert_equal 2, fighter.fighting_style_effects["ranged_attack_bonus"]
  end

  test "the level up takes a feat with its points, or the skills of Skilled" do
    character = build_character("class" => "Guerrier", "subclass" => "Champion", "level" => 3, "strength" => 13)
    character.update_columns(level_up_to: 4)
    level_up = LevelUp.new(character: character, feat_key: "grappler", ability_increases: { "strength" => "1" })
    assert level_up.save, level_up.errors.full_messages.to_sentence
    assert_equal [{ "key" => "grappler", "level" => 4, "abilities" => { "strength" => 1 } }], character.reload.feats

    character.update_columns(level_up_to: 5, feats: [], sheet: character.sheet.merge("level" => 3))
    character.update_columns(level_up_to: 4)
    level_up = LevelUp.new(character: character.reload, feat_key: "skilled", feat_skill_keys: %w[arcana])
    assert_not level_up.valid?
    level_up.feat_skill_keys = %w[arcana history nature]
    assert level_up.save, level_up.errors.full_messages.to_sentence
    assert_equal [true, true, true], character.reload.sheet.values_at("arcana", "history", "nature")
  end

  private

  def build_character(values)
    @participation.character&.destroy
    feats = values.delete("feats") || []
    @participation.reload.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Vex",
                                            sheet: { "level" => 4 }.merge(values), feats: feats)
  end
end
