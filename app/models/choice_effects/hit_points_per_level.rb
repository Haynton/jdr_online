module ChoiceEffects
  # Hit points added at each level of the character (the draconic resilience of the sorcerer: +1 a level), read by
  # the rule hit_points_by_level
  class HitPointsPerLevel < Base
    KEY = "hit_points_per_level".freeze

    def value_errors(value, **)
      value.is_a?(Integer) ? [] : [[:unknown_effect_value, { effect: KEY, value: value.to_s }]]
    end

    def facts(value, _fields_by_key)
      return [] unless value.is_a?(Integer)

      [[fact_label(:hit_points_per_level), I18n.t("game_tables.choice_summaries.hit_points_per_level_value",
                                                  points: value)]]
    end
  end
end
