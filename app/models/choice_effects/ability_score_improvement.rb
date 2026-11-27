module ChoiceEffects
  # The levels at which an option raises the abilities (SRD 5.2.1: the Ability Score Improvement of a class, at 4, 8,
  # 12 and 16, more for the fighter and the rogue), and how: points to share (2) and at most on one ability (2: +2 to
  # one, or +1 to two). Asked when the character reaches one of those levels (LevelUp), never beyond the maximum of the
  # ability; the other feats a player may take instead come later
  class AbilityScoreImprovement < Base
    KEY = "ability_score_improvement".freeze
    PARAMETERS = %w[levels points max_per_ability].freeze

    def value_errors(value, **)
      return [] if valid?(value)

      [[:unknown_effect_value, { effect: KEY, value: value.to_s.truncate(60) }]]
    end

    private

    def valid?(value)
      value.is_a?(Hash) && (value.keys - PARAMETERS).empty? && PARAMETERS.all? { |parameter| value.key?(parameter) } &&
        levels?(value["levels"]) && positive_integer?(value["points"]) && positive_integer?(value["max_per_ability"])
    end

    def levels?(levels)
      levels.is_a?(Array) && levels.all? { |level| level.is_a?(Integer) && level.between?(2, 20) }
    end

    def positive_integer?(number)
      number.is_a?(Integer) && number.positive?
    end
  end
end
