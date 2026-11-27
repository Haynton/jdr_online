require "test_helper"

# The skills chosen share out between the options picked, each taking its own in its list: a human ranger takes 3 of
# the list of the ranger and 1 of every skill
class SkillChoicesTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "class", "type" => "choice", "options" => %w[Rôdeur],
      "effects" => { "Rôdeur" => { "skill_choices" => { "count" => 3, "from" => %w[athletics insight stealth survival] } } } },
    { "key" => "species", "type" => "choice", "options" => %w[Humain],
      "effects" => { "Humain" => { "skill_choices" => { "count" => 1,
                                                        "from" => %w[arcana athletics history insight stealth survival] } } } }
  ].freeze

  def choices(*ticked)
    CharacterSheets::SkillChoices.new(fields: FIELDS, sheet: { "class" => "Rôdeur", "species" => "Humain" }
                                                     .merge(ticked.index_with(true)))
  end

  test "the options add their counts" do
    assert_equal 4, choices.allowed_count
    assert_equal "Rôdeur : 3, Humain : 1", choices.offers_text
  end

  test "three skills of the ranger and one of any list fit" do
    assert choices("athletics", "stealth", "survival", "arcana").fit_offers?
    assert choices("arcana", "athletics", "insight", "stealth").fit_offers?
  end

  test "two skills outside the list of the ranger do not fit" do
    assert_not choices("arcana", "history", "stealth").fit_offers?
  end
end
