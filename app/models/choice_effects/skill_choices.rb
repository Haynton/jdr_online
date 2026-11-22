module ChoiceEffects
  # How many bonus fields to pick (count) among a list (from): the skills a class offers. The page marks them and
  # counts those ticked (character_sheet_controller.js#showSkillChoices)
  class SkillChoices < Base
    KEY = "skill_choices".freeze
    TARGET_TYPE = "bonus".freeze

    def target_keys(value)
      value.to_h["from"].to_a
    end

    def facts(value, _fields_by_key)
      count = value.to_h["count"]
      return [] unless count

      [[fact_label(:skill_choices), I18n.t("game_tables.choice_summaries.skill_choices_value", count: count)]]
    end
  end
end
