require "test_helper"

class CreationStepBehaviorsTest < ActiveSupport::TestCase
  test "a declared step turns on the behaviors set to true" do
    assert_equal %w[chooses_spells], CreationStepBehaviors.of({ "chooses_spells" => true }).map(&:key)
    assert_empty CreationStepBehaviors.of({ "chooses_spells" => false })
  end

  test "every behavior draws partials that exist" do
    CreationStepBehaviors.all.each do |behavior|
      [behavior.form_partial, behavior.summary_partial].each do |partial|
        directory, name = File.split(partial)
        assert_predicate Rails.root.join("app/views/#{directory}/_#{name}.html.erb"), :exist?, partial
      end
    end
  end

  test "a step may only use the settings of a step and the behaviors of the registry" do
    assert_includes SheetTemplates::StepsCheck::STEP_PARAMETERS, "chooses_equipment"
    assert_includes SheetTemplates::StepsCheck::STEP_PARAMETERS, "asks_name"
  end
end
