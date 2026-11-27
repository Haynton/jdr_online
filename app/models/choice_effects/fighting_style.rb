module ChoiceEffects
  # The fighting style an option gives (SRD 5.2.1: the fighter from level 1, the paladin and the ranger from level 2):
  # from which level, and among which styles (keys of character_fields.fighting_styles, checked by
  # SheetTemplates::FightingStylesCheck). Read by CharacterSheets::WeaponMasteries
  class FightingStyle < Base
    KEY = "fighting_style".freeze
    PARAMETERS = %w[level options].freeze

    def value_errors(value, **)
      return [] if valid?(value)

      [[:unknown_effect_value, { effect: KEY, value: value.to_s.truncate(60) }]]
    end

    def facts(value, _fields_by_key)
      return [] unless valid?(value)

      [[fact_label(:fighting_style), I18n.t("game_tables.choice_summaries.features_level", level: value["level"]),
        value["level"]]]
    end

    private

    def valid?(value)
      value.is_a?(Hash) && (value.keys - PARAMETERS).empty? && value["level"].is_a?(Integer) &&
        value["level"].between?(1, 20) && value["options"].is_a?(Array) && value["options"].all?(String)
    end
  end
end
