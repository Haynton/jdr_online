module ComputedRules
  # The modifier of the ability based_on (the initiative: the modifier of Dexterity). Reads as a bonus: +2
  class AbilityModifier < Base
    KEY = "ability_modifier".freeze
    REQUIRED_PARAMETERS = %w[based_on].freeze

    def value(field, reader)
      reader.modifier(field["based_on"])
    end
  end
end
