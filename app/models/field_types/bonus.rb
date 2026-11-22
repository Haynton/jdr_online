module FieldTypes
  # The bonus of an ability (based_on), plus a proficiency (proficiency: the key of a computed field) when the player
  # ticks it: a tight row (saving throws, skills). The sheet only stores the tick, true or false
  class Bonus < Base
    KEY = "bonus".freeze
    OWN_PARAMETERS = %w[based_on proficiency].freeze
    REQUIRED_PARAMETERS = %w[based_on].freeze
    REFERENCES = { "based_on" => "ability", "proficiency" => "computed" }.freeze

    def partial
      "character_sheets/fields/bonus"
    end

    def summary_group(_field)
      :rows
    end

    def kept_when_blank?
      true
    end

    # A conversion, not a question: it turns the "1" or "0" sent by the check box into true or false
    def convert(typed_value, _field) # rubocop:disable Naming/PredicateMethod
      typed_value == "1"
    end

    def error_for(value, _field, **)
      [:inclusion] unless [true, false].include?(value)
    end
  end
end
