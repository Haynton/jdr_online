module ChoiceEffects
  # How many bonus fields to pick (count) among a list (from): the skills a class offers. The page marks them and
  # counts those ticked (character_sheet_controller.js#showSkillChoices). When the option changes (another class), the
  # skills picked in its list are unticked (decision of 27 November: what a choice of the first step offered goes with
  # it), but those another option picked gives (the skills of the background)
  class SkillChoices < Base
    KEY = "skill_choices".freeze
    TARGET_TYPE = "bonus".freeze

    def target_keys(value)
      value.to_h["from"].to_a
    end

    def apply(sheet, previous_value, _picked_value, fields:, **)
      given = given_skills(sheet, fields)
      (previous_value.to_h["from"].to_a - given).each { |field_key| sheet.delete(field_key) }
    end

    def facts(value, _fields_by_key)
      count = value.to_h["count"]
      return [] unless count

      [[fact_label(:skill_choices), I18n.t("game_tables.choice_summaries.skill_choices_value", count: count)]]
    end

    private

    # The skills the options picked give (proficient): never unticked here
    def given_skills(sheet, fields)
      fields.select { |field| field["effects"].is_a?(Hash) }.flat_map do |field|
        field["effects"][sheet[field["key"]].to_s].to_h["proficient"].to_a
      end
    end
  end
end
