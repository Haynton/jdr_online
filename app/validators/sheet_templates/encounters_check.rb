module SheetTemplates
  # The budget of a combat encounter (character_fields.encounters, decision of 27 November, SRD 5.2.1): the field of
  # the NPCs whose value gives a creature its experience points (rating_from: a list, the challenge rating), the
  # points of each of its options (xp_by_rating), the difficulties (a key, a label, a help each) and, for each level
  # from 1 to 20, the points each character adds to the budget of each difficulty (budget_by_level)
  class EncountersCheck < Check
    PARAMETERS = %w[label help rating_from xp_by_rating difficulties budget_by_level].freeze
    LEVELS = 20
    DIFFICULTIES = (1..5)

    def call
      encounters = @sheet_template.character_fields.to_h["encounters"]
      return [] if encounters.nil?
      return [[:invalid_encounters, {}]] unless encounters.is_a?(Hash)

      parameter_errors(encounters) + label_errors(encounters) + rating_errors(encounters) +
        difficulty_errors(encounters)
    end

    private

    def parameter_errors(encounters)
      (encounters.keys - PARAMETERS).map { |parameter| [:unknown_encounters_parameter, { parameter: parameter }] }
    end

    def label_errors(encounters)
      valid_label?(encounters["label"]) ? [] : [[:invalid_encounters_label, { count: LABEL_MAX_LENGTH }]]
    end

    # A list of the sheet of the NPCs, each value of the experience points one of its options
    def rating_errors(encounters)
      field = fields_of("npc_fields").find { |candidate| candidate["key"] == encounters["rating_from"] }
      return [[:invalid_encounters_rating, {}]] unless field && field["type"] == "choice"

      valid_points?(encounters["xp_by_rating"], Array(field["options"])) ? [] : [[:invalid_encounters_xp, {}]]
    end

    def valid_points?(points, options)
      points.is_a?(Hash) && (points.keys - options).empty? && points.values.all? { |value| whole?(value, 0) }
    end

    # One to five difficulties, then one line per level with a number for each of them
    def difficulty_errors(encounters)
      difficulties = encounters["difficulties"]
      return [[:invalid_encounters_difficulties, {}]] unless valid_difficulties?(difficulties)
      return [] if valid_budget?(encounters["budget_by_level"], difficulties.size)

      [[:invalid_encounters_budget, { count: difficulties.size }]]
    end

    def valid_difficulties?(difficulties)
      difficulties.is_a?(Array) && DIFFICULTIES.cover?(difficulties.size) &&
        difficulties.all? { |difficulty| difficulty.is_a?(Hash) && valid_difficulty?(difficulty) }
    end

    def valid_difficulty?(difficulty)
      valid_key?(difficulty["key"]) && valid_label?(difficulty["label"])
    end

    def valid_budget?(rows, count)
      rows.is_a?(Array) && rows.size == LEVELS &&
        rows.all? { |row| row.is_a?(Array) && row.size == count && row.all? { |value| whole?(value, 1) } }
    end

    def whole?(value, minimum)
      value.is_a?(Integer) && value >= minimum
    end
  end
end
