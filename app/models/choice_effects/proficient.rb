module ChoiceEffects
  # The bonus fields ticked: the saving throws of a class, the skills of a background
  class Proficient < Base
    KEY = "proficient".freeze
    TARGET_TYPE = "bonus".freeze
    LIVE = true

    def target_keys(value)
      value.to_a
    end

    def facts(value, fields_by_key)
      labels = labels_of(value, fields_by_key)
      labels.any? ? [[fact_label(:proficient), labels.to_sentence]] : []
    end

    def apply(sheet, previous_value, picked_value, **)
      previous_value.to_a.each { |field_key| sheet[field_key] = false }
      picked_value.to_a.each { |field_key| sheet[field_key] = true }
    end
  end
end
