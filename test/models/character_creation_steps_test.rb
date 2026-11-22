require "test_helper"

class CharacterCreationStepsTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "class", "type" => "choice", "section" => "Classe",
      "effects" => { "Mage" => { "spellcasting" => {} }, "Guerrier" => {} } },
    { "key" => "level", "type" => "number", "section" => "Classe", "from_table" => "starting_level" },
    { "key" => "spell_notes", "type" => "text", "section" => "Sorts" },
    { "key" => "backstory", "type" => "text", "section" => "Identité" }
  ].freeze
  STEPS = [
    { "key" => "class", "label" => "Classe", "sections" => ["Classe"] },
    { "key" => "spells", "label" => "Sorts", "sections" => ["Sorts"], "only_with_effect" => "spellcasting" },
    { "key" => "description", "label" => "Description", "sections" => ["Identité"], "asks_name" => true }
  ].freeze

  setup do
    @game_table = GameTable.new(template_snapshot: { "character_fields" => { "creation_steps" => STEPS,
                                                                             "fields" => FIELDS } })
  end

  test "the steps of the template come in order, the summary last, a field given by the table in none" do
    steps = CharacterCreationSteps.new(game_table: @game_table, sheet: {})

    assert_equal %w[class description summary], steps.all.map(&:key)
    assert_equal ["class"], steps.first.field_keys
    assert steps.find("description").asks_name
  end

  test "a step shown only with an effect comes when an option picked has it" do
    steps = CharacterCreationSteps.new(game_table: @game_table, sheet: { "class" => "Mage" })

    assert_equal %w[class spells description summary], steps.all.map(&:key)
    assert_equal steps.find("spells"), steps.after(steps.first)
    assert_nil steps.before(steps.first)
  end

  test "the steps keep the order of the template, the ones not shown counted" do
    steps = CharacterCreationSteps.new(game_table: @game_table, sheet: {})

    assert_operator steps.rank("spells"), :<, steps.rank("description")
    assert_equal(-1, steps.rank(nil))
  end

  test "a draft resumes at the furthest step reached, or the one before when that step is gone" do
    steps = CharacterCreationSteps.new(game_table: @game_table, sheet: { "class" => "Guerrier" })

    assert_equal "class", steps.furthest_reached("spells").key
    assert_equal "description", steps.furthest_reached("description").key
    assert_equal "class", steps.furthest_reached(nil).key
  end

  test "a step with nothing to fill in is a block of the summary only, not a page" do
    steps_with_combat = STEPS + [{ "key" => "combat", "label" => "Combat", "sections" => ["Identité"],
                                   "summary_only" => true }]
    @game_table.template_snapshot = { "character_fields" => { "creation_steps" => steps_with_combat,
                                                              "fields" => FIELDS } }
    steps = CharacterCreationSteps.new(game_table: @game_table, sheet: {})

    assert_not_includes steps.all.map(&:key), "combat"
    assert_includes steps.summary_blocks.map(&:key), "combat"
  end

  test "a template without steps asks everything, with the name, in one step" do
    @game_table.template_snapshot = { "character_fields" => { "fields" => FIELDS } }
    steps = CharacterCreationSteps.new(game_table: @game_table, sheet: {})

    assert_equal %w[sheet summary], steps.all.map(&:key)
    assert_equal %w[class spell_notes backstory], steps.first.field_keys
    assert steps.first.asks_name
  end
end
