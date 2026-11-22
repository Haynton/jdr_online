module ChoiceEffects
  # The abilities a background raises, placed by the player in an ability_bonuses field by its rule (rules of 2024: +2
  # and +1, or +1 to each)
  class AbilityBonusChoices < Base
    KEY = "ability_bonus_choices".freeze
    TARGET_TYPE = "ability".freeze

    def target_keys(value)
      value.to_a
    end

    def facts(value, fields_by_key)
      labels = labels_of(value, fields_by_key)
      return [] if labels.empty?

      [[fact_label(:ability_bonus), with_rule(labels.to_sentence, fields_by_key)]]
    end

    # The abilities, then the rule in the words of the game (the help of the ability_bonuses field), when it has one
    def with_rule(abilities, fields_by_key)
      rule = fields_by_key.values.find { |field| field["type"] == "ability_bonuses" }&.dig("help")
      return abilities if rule.blank?

      I18n.t("game_tables.choice_summaries.ability_bonus_value", abilities: abilities, rule: rule.delete_suffix("."))
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
