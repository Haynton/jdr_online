module ChoiceEffects
  # The levels at which an option raises the abilities (SRD 5.2.1: the Ability Score Improvement of a class, at 4, 8,
  # 12 and 16, more for the fighter and the rogue), and how: points to share (2) and at most on one ability (2: +2 to
  # one, or +1 to two). At those levels the player may take another feat instead (character_fields.feats, decision of
  # 27 November), and at its epic_levels (19: the Epic Boon) an epic boon too. Asked by LevelUp
  class AbilityScoreImprovement < Base
    KEY = "ability_score_improvement".freeze
    PARAMETERS = %w[levels epic_levels points max_per_ability].freeze
    REQUIRED_PARAMETERS = %w[levels points max_per_ability].freeze

    def value_errors(value, **)
      return [] if valid?(value)

      [[:unknown_effect_value, { effect: KEY, value: value.to_s.truncate(60) }]]
    end

    private

    def valid?(value)
      value.is_a?(Hash) && (value.keys - PARAMETERS).empty? && REQUIRED_PARAMETERS.all? { |key| value.key?(key) } &&
        levels?(value["levels"]) && levels?(value.fetch("epic_levels", [])) &&
        positive_integer?(value["points"]) && positive_integer?(value["max_per_ability"])
    end

    def levels?(levels)
      levels.is_a?(Array) && levels.all? { |level| level.is_a?(Integer) && level.between?(2, 20) }
    end

    def positive_integer?(number)
      number.is_a?(Integer) && number.positive?
    end
  end
end
