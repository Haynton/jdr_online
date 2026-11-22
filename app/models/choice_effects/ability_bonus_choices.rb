module ChoiceEffects
  # The abilities a background raises (rules of 2024: +2 and +1, or +1 to each), placed by the player in an
  # ability_bonuses field
  class AbilityBonusChoices < Base
    KEY = "ability_bonus_choices".freeze
    TARGET_TYPE = "ability".freeze

    def target_keys(value)
      value.to_a
    end

    def facts(value, fields_by_key)
      labels = labels_of(value, fields_by_key)
      return [] if labels.empty?

      [[fact_label(:ability_bonus),
        I18n.t("game_tables.choice_summaries.ability_bonus_value", abilities: labels.to_sentence)]]
    end

    # A bonus placed on an ability the new background does not raise means nothing: it is taken off (emptied when none
    # is left). One the new background raises stays: picked on the same page, it belongs to it
    def apply(sheet, _previous_value, picked_value, list_key:, fields:)
      fields.select { |field| field["type"] == "ability_bonuses" && field["from"] == list_key }.each do |bonus_field|
        kept_bonuses = sheet[bonus_field["key"]].to_h.slice(*picked_value.to_a)
        kept_bonuses.empty? ? sheet.delete(bonus_field["key"]) : sheet[bonus_field["key"]] = kept_bonuses
      end
    end
  end
end
