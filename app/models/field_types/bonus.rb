module FieldTypes
  # The bonus of an ability (based_on), plus a proficiency (proficiency: the key of a computed field) when the player
  # ticks it: a tight row (saving throws, skills). The sheet only stores the tick, true or false, or "expertise": the
  # proficiency counts twice (decision of 26 November, ChoiceEffects::ExpertiseChoices; its box sends "2", after the
  # "1" of the proficiency, so it wins)
  class Bonus < Base
    KEY = "bonus".freeze
    OWN_PARAMETERS = %w[based_on proficiency].freeze
    REQUIRED_PARAMETERS = %w[based_on].freeze
    REFERENCES = { "based_on" => "ability", "proficiency" => "computed" }.freeze
    EXPERTISE = "expertise".freeze

    # Ticked, with or without expertise
    def self.proficient?(value)
      [true, EXPERTISE].include?(value)
    end

    def self.expertise?(value)
      value == EXPERTISE
    end

    # How many times the proficiency bonus counts: 0, 1, or 2 with expertise
    def self.proficiency_factor(value)
      return 2 if expertise?(value)

      proficient?(value) ? 1 : 0
    end

    def partial
      "character_sheets/fields/bonus"
    end

    def summary_group(_field)
      :rows
    end

    def kept_when_blank?
      true
    end

    # The modifier of its ability, and the proficiency when the box is ticked, if it has one
    def calculation_key(field)
      return "sheet_templates.calculations.bonus_with_proficiency" if field["proficiency"]

      "sheet_templates.calculations.bonus"
    end

    # A conversion, not a question: it turns the "1" or "0" sent by the check box into true or false
    def convert(typed_value, _field)
      return EXPERTISE if typed_value == "2"

      typed_value == "1"
    end

    def error_for(value, _field, **)
      [:inclusion] unless [true, false, EXPERTISE].include?(value)
    end
  end
end
