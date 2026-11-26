module ChoiceEffects
  # The weapon masteries an option gives (decision of 26 November, SRD 5.2.1: the barbarian, the fighter, the paladin,
  # the ranger, the rogue): how many kinds of weapons, at each level of the character (counts, 20 numbers), and whether
  # only melee weapons count (melee_only: the barbarian). Read by CharacterSheets::WeaponMasteries
  class WeaponMastery < Base
    KEY = "weapon_mastery".freeze
    PARAMETERS = %w[counts melee_only].freeze

    def value_errors(value, **)
      return [] if valid?(value)

      [[:unknown_effect_value, { effect: KEY, value: value.to_s.truncate(60) }]]
    end

    def facts(value, _fields_by_key)
      return [] unless valid?(value)

      count = value["counts"].first
      [[fact_label(:weapon_mastery), I18n.t("game_tables.choice_summaries.weapon_mastery_value", count: count)]]
    end

    private

    def valid?(value)
      value.is_a?(Hash) && (value.keys - PARAMETERS).empty? &&
        ChoiceEffects::Spellcasting.level_table?(value["counts"]) && [nil, true, false].include?(value["melee_only"])
    end
  end
end
