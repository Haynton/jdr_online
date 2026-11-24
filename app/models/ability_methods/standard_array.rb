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
      values = method["values"]
      outside = scores.reject { |_ability, score| values.include?(score) }
      outside_errors = outside.map do |ability, _score|
        [[ability], :not_in_standard_array, { values: values.join(", ") }]
      end
      outside_errors + placed_too_often_errors(scores.except(*outside.keys), values)
    end

    private

    # A value typed more often than the array has it: every ability holding it is refused
    def placed_too_often_errors(scores, values)
      scores.group_by { |_ability, score| score }.filter_map do |value, holders|
        next if holders.size <= values.count(value)

        [holders.map(&:first), :standard_array_value_taken, { value: value }]
      end
    end
  end
end
