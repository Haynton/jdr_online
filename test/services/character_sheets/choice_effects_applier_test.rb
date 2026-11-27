require "test_helper"

class ChoiceEffectsApplierTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "species", "type" => "choice", "effects" => {
      "Nain" => { "proficient" => ["history"], "set" => { "speed" => 9, "size" => "Moyenne" } },
      "Tieffelin" => { "set" => { "speed" => 9 } }
    } }
  ].freeze

  test "a new option takes back the effects of the one before and applies its own" do
    applier = CharacterSheets::ChoiceEffectsApplier.new(fields: FIELDS, previous_sheet: { "species" => "Nain", "history" => true })

    sheet = applier.call("species" => "Tieffelin", "history" => true, "size" => "Moyenne", "speed" => 9)

    assert_equal({ "species" => "Tieffelin", "history" => false, "speed" => 9 }, sheet)
  end

  test "the bonus placed on an ability the new background does not raise is taken off" do
    fields = [{ "key" => "background", "type" => "choice", "effects" => { "Sage" => {}, "Soldat" => {} } },
              { "key" => "ability_bonuses", "type" => "ability_bonuses", "from" => "background" }]
    applier = CharacterSheets::ChoiceEffectsApplier.new(fields: fields, previous_sheet: { "background" => "Sage" })

    assert_equal({ "background" => "Soldat" },
                 applier.call("background" => "Soldat", "ability_bonuses" => { "intelligence" => 2 }))
  end

  test "an option that did not change applies nothing: what was changed by hand stays" do
    applier = CharacterSheets::ChoiceEffectsApplier.new(fields: FIELDS, previous_sheet: { "species" => "Nain" })

    assert_equal({ "species" => "Nain", "history" => false, "speed" => 12 },
                 applier.call("species" => "Nain", "history" => false, "speed" => 12))
  end

  test "another class unticks the skills picked in the list of the old one, keeps those of the background, and its expertise" do
    fields = [{ "key" => "class", "type" => "choice", "effects" => {
                "Barbare" => { "skill_choices" => { "count" => 2, "from" => %w[intimidation nature survival] } },
                "Roublard" => { "skill_choices" => { "count" => 4, "from" => %w[stealth acrobatics] },
                                "expertise_choices" => [{ "level" => 1, "count" => 2 }] }
              } },
              { "key" => "background", "type" => "choice", "effects" => { "Soldat" => { "proficient" => %w[intimidation] } } }]
    sheet = { "class" => "Barbare", "background" => "Soldat", "intimidation" => true, "nature" => true, "survival" => true }
    applier = CharacterSheets::ChoiceEffectsApplier.new(fields: fields, previous_sheet: sheet)
    assert_equal({ "class" => "Roublard", "background" => "Soldat", "intimidation" => true },
                 applier.call(sheet.merge("class" => "Roublard")))

    rogue = { "class" => "Roublard", "background" => "Soldat", "stealth" => "expertise", "intimidation" => true }
    applier = CharacterSheets::ChoiceEffectsApplier.new(fields: fields, previous_sheet: rogue)
    assert_equal({ "class" => "Barbare", "background" => "Soldat", "intimidation" => true },
                 applier.call(rogue.merge("class" => "Barbare")))
  end
end
