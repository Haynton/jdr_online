module SheetTemplates
  # The creation steps of a character (character_fields.creation_steps, CharacterCreationSteps), when the template
  # declares them: a key used once, sections that exist, every field asked at creation in a step, one step (and only
  # one) that asks the name, a known effect for a step that depends on one, only the settings a step knows
  class StepsCheck < Check
    # Its own settings, then the behaviors it may turn on (CreationStepBehaviors)
    INTRO_MAX_LENGTH = 200

    STEP_PARAMETERS = (
      %w[key label intro sections asks_name only_with_effect summary_only] + CreationStepBehaviors.keys
    ).freeze

    def call
      steps = @sheet_template.character_fields.to_h["creation_steps"]
      return [] if steps.blank?

      duplicate_errors(steps) + steps.flat_map { |step| step_errors(step, step["label"] || step["key"]) } +
        coverage_errors(steps) + name_errors(steps)
    end

    private

    def duplicate_errors(steps)
      steps.pluck("key").tally.select { |_key, count| count > 1 }.keys.map { |key| [:duplicate_step, { step: key }] }
    end

    def step_errors(step, name)
      unknown_sections = step["sections"].to_a - character_fields.pluck("section")
      section_errors = unknown_sections.map { |section| [:unknown_section, { step: name, section: section }] }
      parameter_errors = (step.keys - STEP_PARAMETERS).map do |parameter|
        [:unknown_step_parameter, { step: name, parameter: parameter }]
      end
      section_errors + parameter_errors + effect_errors(step, name) + step_name_errors(step, name)
    end

    # Its key is a part of the address of its page (/steps/character), its label is shown in the band of the steps
    def step_name_errors(step, name)
      errors = []
      errors << [:invalid_step_key, { step: name, key: step["key"].to_s }] unless valid_key?(step["key"])
      errors << [:invalid_step_label, { step: name, count: LABEL_MAX_LENGTH }] unless valid_label?(step["label"])
      errors << [:invalid_step_intro, { step: name, count: INTRO_MAX_LENGTH }] unless valid_intro?(step["intro"])
      errors
    end

    # The sentence under the title of the step, written by the template in its words: optional, one paragraph
    def valid_intro?(intro)
      intro.nil? || (intro.is_a?(String) && intro.strip.present? && intro.length <= INTRO_MAX_LENGTH &&
        !intro.match?(CONTROL_CHARACTERS))
    end

    def effect_errors(step, name)
      effect = step["only_with_effect"]
      return [] if effect.nil? || SheetTemplate::CHOICE_EFFECTS.include?(effect)

      [[:unknown_step_effect, { step: name, effect: effect }]]
    end

    # Every field the player fills at creation (not one given by the table, nor one of the game) is in a step
    def coverage_errors(steps)
      step_sections = steps.flat_map { |step| step["sections"].to_a }
      asked = character_fields.reject { |field| field["at_creation"] == false || field["from_table"] }
      asked.reject { |field| step_sections.include?(field["section"]) }
           .map { |field| [:field_without_step, { field: field["label"] || field["key"] }] }
    end

    def name_errors(steps)
      steps.one? { |step| step["asks_name"] } ? [] : [[:name_step_count, {}]]
    end
  end
end
