require "test_helper"

class ChoiceEffectsApplierTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "species", "type" => "choice", "effects" => {
      "Nain" => { "proficient" => ["history"], "set" => { "speed" => 9, "size" => "Moyenne" } },
      "Tieffelin" => { "set" => { "speed" => 9 } }
    } }
  ].freeze

  test "a new option takes back the effects of the one before and applies its own" do
    applier = ChoiceEffectsApplier.new(fields: FIELDS, previous_sheet: { "species" => "Nain", "history" => true })

    sheet = applier.call("species" => "Tieffelin", "history" => true, "size" => "Moyenne", "speed" => 9)

    assert_equal({ "species" => "Tieffelin", "history" => false, "speed" => 9 }, sheet)
  end

  test "an option that did not change applies nothing: what was changed by hand stays" do
    applier = ChoiceEffectsApplier.new(fields: FIELDS, previous_sheet: { "species" => "Nain" })

    assert_equal({ "species" => "Nain", "history" => false, "speed" => 12 },
                 applier.call("species" => "Nain", "history" => false, "speed" => 12))
  end
end
