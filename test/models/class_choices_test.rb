require "test_helper"

# The groups of choices of the heroic fantasy classes (SRD 5.2.1): the invocations of the warlock (their level, the
# pact they require), the metamagic of the sorcerer, the land of the circle and its spells, checked by the server, and
# asked again at a level gained (with the skills of the College of Lore)
class ClassChoicesTest < ActiveSupport::TestCase
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_spells.fr.json")).call
    @game_table = GameTable.new(name: "La Crypte", starting_level: 1)
    @game_table.use_sheet_template(template)
    @game_table.save!
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    @participation = @game_table.participations.create!(user: player, role: :player)
  end

  test "a warlock picks as many invocations as its level gives, those of its level, a pact before what needs it" do
    groups = warlock(level: 1).class_choice_groups.groups
    assert_equal [%w[eldritch_invocations 1]], groups.map { |group| [group.key, group.allowed_count.to_s] }
    assert_not_includes groups.first.offered_keys, "agonizing-blast"

    character = warlock(level: 5, class_choices: { "eldritch_invocations" => ["pact-of-the-blade"] })
    offered = character.class_choice_groups.groups.first
    assert_equal 5, offered.allowed_count
    assert_includes offered.offered_keys, "thirsting-blade"
    assert_not_includes warlock(level: 5).class_choice_groups.groups.first.offered_keys, "thirsting-blade"
  end

  test "the server refuses too many options, an option not offered, and the same option twice" do
    character = warlock(level: 1, class_choices: { "eldritch_invocations" => %w[eldritch-mind armor-of-shadows] })
    assert character.tap(&:validate).errors.of_kind?(:class_choices, :too_many)

    character = warlock(level: 1, class_choices: { "eldritch_invocations" => ["witch-sight"] })
    assert character.tap(&:validate).errors.of_kind?(:class_choices, :not_offered)

    character = warlock(level: 5, class_choices: { "eldritch_invocations" => %w[eldritch-mind eldritch-mind] })
    assert character.tap(&:validate).errors.of_kind?(:class_choices, :repeated)
  end

  test "a sorcerer picks two metamagic options from level 2, and none at level 1" do
    assert_empty build_character(1, "Ensorceleur").class_choice_groups.groups
    assert_equal [2], build_character(2, "Ensorceleur").class_choice_groups.groups.map(&:allowed_count)
  end

  test "the land of a circle druid always prepares its spells, and they change with the land" do
    druid = build_character(3, "Druide", "subclass" => "Cercle de la Terre")
    druid.choose_class_choices({ "land_type" => ["arid"] })
    assert_equal %w[blur burning-hands fire-bolt], druid.spells.select { |spell| spell["always_prepared"] }.pluck("key").sort

    druid.choose_class_choices({ "land_type" => ["polar"] })
    assert_equal %w[fog-cloud hold-person ray-of-frost],
                 druid.spells.select { |spell| spell["always_prepared"] }.pluck("key").sort
  end

  test "a level gained asks the new invocations, and the skills of the College of Lore once it is picked" do
    character = warlock(level: 4, class_choices: { "eldritch_invocations" => %w[eldritch-mind armor-of-shadows pact-of-the-blade] })
    character.update!(level_up_to: 5)
    level_up = LevelUp.new(character: character, ability_increases: {})
    assert_equal [5], level_up.class_choice_groups_to_pick.map(&:allowed_count)
    assert_not level_up.valid?

    level_up.class_choices = { "eldritch_invocations" => %w[eldritch-mind armor-of-shadows pact-of-the-blade
                                                            thirsting-blade devils-sight] }
    assert level_up.save, level_up.errors.full_messages.to_sentence
    assert_includes character.reload.class_choices["eldritch_invocations"], "thirsting-blade"

    bard = build_character(2, "Barde")
    bard.update!(level_up_to: 3)
    level_up = LevelUp.new(character: bard, subclass: "Collège du Savoir")
    assert_equal 3, level_up.skill_count
    assert_not level_up.valid?
    level_up.skill_keys = %w[arcana history nature]
    assert level_up.save
    assert_equal [true, true, true], bard.reload.sheet.values_at("arcana", "history", "nature")
  end

  private

  def warlock(level:, class_choices: {})
    subclass = level >= 3 ? { "subclass" => "Protecteur fiélon" } : {}
    build_character(level, "Occultiste", subclass).tap { |character| character.class_choices = class_choices }
  end

  def build_character(level, class_option, sheet = {})
    @participation.character&.destroy
    @participation.reload.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Vex",
                                            sheet: { "class" => class_option, "level" => level }.merge(sheet))
  end
end
