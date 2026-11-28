module AbilityMethods
  # The same values for everyone (15, 14, 13, 12, 10 and 8), one per ability: a score typed is one of them, and each
  # value is placed once. A score not typed yet is fine, the player places them one by one
  class StandardArray < Base
    KEY = "standard_array".freeze
    GUIDE_PARTIAL = "character_sheets/ability_methods/standard_array".freeze
    OWN_PARAMETERS = %w[values].freeze
    REQUIRED_PARAMETERS = %w[values].freeze

    def places_results?
      true
    end

    def settings_errors(method, ability_count:)
      values = method["values"]
      valid = values.is_a?(Array) && values.size == ability_count && values.all? { |value| positive_integer?(value) }
      return [] if valid

      [[:invalid_standard_array, { method: method["label"], count: ability_count }]]
    end

    def score_errors(scores, method)
      placement_errors(scores, method["values"], outside: :not_in_standard_array, taken: :standard_array_value_taken)
    end
  end
end
