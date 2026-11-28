require "test_helper"

# A level the game master gives a player's character, and the choices the player makes for it, with the heroic fantasy
# of the SRD 5.2.1: the hit points (average or roll), the subclass at level 3, the ability improvement of the class,
# the expertise; one level at a time
class LevelUpTest < ActiveSupport::TestCase
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    @game_table = GameTable.new(name: "La Crypte", starting_level: 3)
    @game_table.use_sheet_template(template)
    @game_table.save!
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    participation = @game_table.participations.create!(user: player, role: :player)
    # A fighter of level 3: 10 + 2, then twice 6 + 2 (Constitution 14) = 28 hit points
    @character = participation.create_character!(
      game_table: @game_table, kind: :pc, status: :complete, name: "Brunhild",
      sheet: { "class" => "Guerrier", "subclass" => "Champion", "level" => 3, "strength" => 15, "constitution" => 14,
               "hp" => { "current" => 20, "max" => 28 } }
    )
  end

  test "the game master gives one level at a time, never beyond the last" do
    assert_equal 4, @character.grant_level
    assert_equal 4, @character.level_up_to
    assert_nil @character.grant_level

    @character.update!(level_up_to: nil, sheet: @character.sheet.merge("level" => 20))
    assert_nil @character.grant_level
  end

  test "level 4 of a fighter asks the ability improvement; the average raises the hit points and the level" do
    @character.update!(level_up_to: 4)
    level_up = LevelUp.new(character: @character, ability_increases: { "strength" => "2" })

    assert_equal [%w[average], 2, nil, 0], [level_up.hit_point_choices, level_up.improvement["points"],
                                            level_up.subclass_field, level_up.expertise_count]
    assert_equal 8, level_up.save
    @character.reload
    assert_equal [4, 15, { "current" => 28, "max" => 36 }, nil],
                 [@character.sheet["level"], @character.sheet["strength"], @character.sheet["hp"], @character.level_up_to]
    # The +2 is kept with the feat, apart from the score typed, and counts in the score
    assert_equal [{ "key" => "ability-score-improvement", "level" => 4, "abilities" => { "strength" => 2 } }],
                 @character.feats
    assert_equal 17, @character.computed_sheet_values[:scores]["strength"]
    assert_equal "level_reached", @game_table.chat_messages.last.event_key
  end

  test "the improvement shares exactly its points, never above the maximum of an ability" do
    @character.update!(level_up_to: 4, sheet: @character.sheet.merge("strength" => 19))

    assert_not LevelUp.new(character: @character, ability_increases: { "strength" => "1" }).valid?
    level_up = LevelUp.new(character: @character, ability_increases: { "strength" => "2" })
    assert_not level_up.valid?
    assert level_up.errors.of_kind?(:ability_increases, :above_maximum)
    assert LevelUp.new(character: @character, ability_increases: { "strength" => "1", "constitution" => "1" }).valid?
  end

  test "level 3 asks the subclass of the class, among its own" do
    @character.update!(level_up_to: 3, sheet: @character.sheet.except("subclass").merge("level" => 2))
    level_up = LevelUp.new(character: @character, subclass: "Voie du Berserker")

    assert_equal ["Champion"], level_up.subclass_options.map(&:last)
    assert_not level_up.valid?
    level_up.subclass = "Champion"
    assert level_up.save
    assert_equal "Champion", @character.reload.sheet["subclass"]
  end

  test "a table that rolls rolls the hit die, kept with the levels before" do
    @game_table.update!(rules: { "hit_point_method" => "roll" })
    @character.update!(level_up_to: 4, hit_point_rolls: { "sides" => 10, "results" => [7, 3] })
    level_up = LevelUp.new(character: @character, ability_increases: { "strength" => "2" })

    assert_equal %w[roll], level_up.hit_point_choices
    level_up.save
    results = @character.reload.hit_point_rolls["results"]
    assert_equal [7, 3], results.first(2)
    assert_includes 1..10, results.last
    assert_equal "level_reached_rolled", @game_table.chat_messages.last.event_key
  end

  test "the rogue picks the expertise of its level among its proficient skills" do
    @character.update!(level_up_to: 6, sheet: @character.sheet.merge("class" => "Roublard", "subclass" => "Voleur",
                                                                       "level" => 5, "stealth" => true,
                                                                       "acrobatics" => true, "athletics" => false))
    level_up = LevelUp.new(character: @character, expertise_keys: ["athletics"])

    assert_equal 2, level_up.expertise_count
    assert_equal %w[acrobatics stealth], level_up.expertise_candidates.pluck("key").sort
    assert_not level_up.valid?
    level_up.expertise_keys = %w[acrobatics stealth]
    assert level_up.save
    assert_equal FieldTypes::Bonus::EXPERTISE, @character.reload.sheet["stealth"]
  end
end
