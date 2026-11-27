require "test_helper"

# The expertise of a character: how many its class gives at its level, among which skills, and the server refusing
# more, or a skill it may not give expertise to
class ExpertiseChoicesTest < ActiveSupport::TestCase
  SKILLS = %w[arcana stealth athletics].freeze
  FIELDS = [
    { "key" => "class", "label" => "Classe", "type" => "choice", "options" => %w[Roublard Magicien],
      "effects" => {
        "Roublard" => { "skill_choices" => { "count" => 3, "from" => SKILLS },
                        "expertise_choices" => [{ "level" => 1, "count" => 1 }, { "level" => 6, "count" => 1 }] },
        "Magicien" => { "skill_choices" => { "count" => 3, "from" => SKILLS },
                        "expertise_choices" => [{ "level" => 2, "count" => 1, "from" => ["arcana"] }] }
      } },
    { "key" => "level", "label" => "Niveau", "type" => "number", "from_table" => "starting_level" },
    { "key" => "dexterity", "label" => "Dextérité", "type" => "ability", "modifier" => "half_above_ten" },
    { "key" => "proficiency_bonus", "label" => "Maîtrise", "type" => "computed", "rule" => "proficiency_by_level",
      "level_from" => "level" }
  ] + SKILLS.map do |key|
    { "key" => key, "label" => key.capitalize, "type" => "bonus", "based_on" => "dexterity",
      "proficiency" => "proficiency_bonus" }
  end

  setup do
    game_table = GameTable.new(name: "La Crypte", template_snapshot: {
                                 "character_fields" => { "fields" => FIELDS },
                                 "level_thresholds" => [{ "level" => 1, "experience" => 0, "proficiency_bonus" => 2 }]
                               })
    @character = Character.new(kind: :pc, status: :draft, name: "Vex", game_table: game_table,
                               sheet: { "class" => "Roublard", "level" => 1, "dexterity" => 16 })
  end

  test "the class gives expertise from its levels, on any skill or only on those it names" do
    assert_equal [1, true], [choices.allowed_count, choices.offered?("stealth")]

    @character.sheet = @character.sheet.merge("level" => 6)
    assert_equal 2, choices.allowed_count

    @character.sheet = @character.sheet.merge("class" => "Magicien", "level" => 2)
    assert_equal [1, true, false], [choices.allowed_count, choices.offered?("arcana"), choices.offered?("stealth")]
  end

  test "an expertise doubles the proficiency bonus of its skill" do
    @character.sheet = @character.sheet.merge("stealth" => "expertise", "athletics" => true)
    values = @character.computed_sheet_values[:values]

    assert_equal [3 + 4, 3 + 2, 3], values.values_at("stealth", "athletics", "arcana")
  end

  test "the server refuses more expertise than the class gives, and a skill it may not take" do
    @character.checks_skill_choices = true
    @character.sheet = @character.sheet.merge("stealth" => "expertise", "athletics" => "expertise")

    @character.validate
    assert @character.errors.of_kind?(:"sheet.stealth", :too_many_expertise)

    @character.sheet = @character.sheet.merge("class" => "Magicien", "level" => 2, "athletics" => true,
                                              "stealth" => "expertise")
    @character.errors.clear
    @character.validate
    assert @character.errors.of_kind?(:"sheet.stealth", :expertise_not_offered)
  end

  private

  def choices
    CharacterSheets::ExpertiseChoices.new(@character)
  end
end
