module ComputedRules
  # The proficiency_bonus, in the level_thresholds of the template, of the level typed in the field level_from
  # (nothing typed is level 1). Reads as a bonus: +2
  class ProficiencyByLevel < Base
    KEY = "proficiency_by_level".freeze
    REQUIRED_PARAMETERS = %w[level_from].freeze

    def value(field, reader)
      reader.threshold_of_level(field["level_from"])&.dig("proficiency_bonus")
    end
  end
end
