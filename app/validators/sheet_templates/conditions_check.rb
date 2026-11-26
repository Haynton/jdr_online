module SheetTemplates
  # The conditions of the template (character_fields.conditions, decision of 26 November: declared by the game, never
  # written in the code), when it declares them: a list where each condition has a key (unique), a label, a short rule
  # (description, shown when hovering it in the game room) and, for a condition that adds up like exhaustion, its
  # number of levels. The same list serves the characters of the players and the NPCs
  class ConditionsCheck < Check
    PARAMETERS = %w[key label description levels].freeze
    DESCRIPTION_MAX_LENGTH = 500
    LEVELS = (2..20)

    def call
      conditions = @sheet_template.character_fields.to_h["conditions"]
      return [] if conditions.nil?
      return [[:invalid_conditions, {}]] unless conditions.is_a?(Array) && conditions.all?(Hash)

      conditions.flat_map { |condition| condition_errors(condition) } + duplicate_errors(conditions)
    end

    private

    def condition_errors(condition)
      unknown_parameter_errors(condition) + key_errors(condition) + label_errors(condition) +
        description_errors(condition) + levels_errors(condition)
    end

    def unknown_parameter_errors(condition)
      (condition.keys - PARAMETERS).map do |parameter|
        [:unknown_condition_parameter, { condition: condition_name(condition), parameter: parameter }]
      end
    end

    def key_errors(condition)
      return [] if valid_key?(condition["key"])

      [[:invalid_condition_key, { key: condition["key"].to_s }]]
    end

    def label_errors(condition)
      return [] if valid_label?(condition["label"])

      [[:invalid_condition_label, { key: condition["key"].to_s, count: LABEL_MAX_LENGTH }]]
    end

    def description_errors(condition)
      description = condition["description"]
      return [] if description.nil?
      return [] if description.is_a?(String) && description.length <= DESCRIPTION_MAX_LENGTH

      [[:invalid_condition_description, { condition: condition_name(condition), count: DESCRIPTION_MAX_LENGTH }]]
    end

    def levels_errors(condition)
      levels = condition["levels"]
      return [] if levels.nil? || (levels.is_a?(Integer) && LEVELS.cover?(levels))

      [[:invalid_condition_levels, { condition: condition_name(condition), min: LEVELS.min, max: LEVELS.max }]]
    end

    def duplicate_errors(conditions)
      keys = conditions.pluck("key").compact
      keys.select { |key| keys.count(key) > 1 }.uniq.map { |key| [:duplicate_condition, { key: key }] }
    end

    # Its label as the game master wrote it, else its key
    def condition_name(condition)
      condition["label"].presence || condition["key"].to_s
    end
  end
end
