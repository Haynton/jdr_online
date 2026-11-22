# The summary of the options picked in the lists that have descriptions (class, species, background), beside them on
# the first step of the creation (character_sheets/sections/_described_choices): not everyone knows what a druid or an
# acolyte is. Each option: its description, written in the template, then what it brings, read from its effects
module CharacterSheets
  module CharacterSheets::ChoiceSummariesHelper
    # The lists of the section whose options have a description
    def described_choice_fields(fields)
      fields.select { |field| field["descriptions"] }
    end

    # The option picked shows from the start (without JavaScript too); described_choices_controller.js follows the list
    def choice_option_hidden?(character, field, option)
      character.sheet[field["key"]] != option
    end

    def choice_picked?(character, field)
      field["options"].include?(character.sheet[field["key"]])
    end

    # [label, text] for each effect of an option that a player can read (the others are kept for the next steps)
    def choice_option_facts(field, option, all_fields)
      effects = field.dig("effects", option).to_h
      fields_by_key = all_fields.index_by { |candidate| candidate["key"] }
      [
        hit_die_fact(effects), proficient_fact(effects, fields_by_key), skill_choices_fact(effects),
        spellcasting_fact(effects, fields_by_key), ability_bonus_fact(effects, fields_by_key),
        origin_feat_fact(effects), *set_facts(effects, fields_by_key)
      ].compact
    end

    private

    def hit_die_fact(effects)
      [choice_fact_label(:hit_die), "d#{effects['hit_die']}"] if effects["hit_die"]
    end

    def proficient_fact(effects, fields_by_key)
      labels = effects["proficient"].to_a.filter_map { |field_key| fields_by_key.dig(field_key, "label") }
      [choice_fact_label(:proficient), labels.to_sentence] if labels.any?
    end

    def skill_choices_fact(effects)
      count = effects.dig("skill_choices", "count")
      [choice_fact_label(:skill_choices), t("game_tables.choice_summaries.skill_choices_value", count: count)] if count
    end

    def spellcasting_fact(effects, fields_by_key)
      ability = fields_by_key.dig(effects.dig("spellcasting", "ability"), "label")
      [choice_fact_label(:spellcasting), ability] if ability
    end

    def ability_bonus_fact(effects, fields_by_key)
      labels = effects["ability_bonus_choices"].to_a.filter_map { |field_key| fields_by_key.dig(field_key, "label") }
      return if labels.empty?

      value = t("game_tables.choice_summaries.ability_bonus_value", abilities: labels.to_sentence)
      [choice_fact_label(:ability_bonus), value]
    end

    def origin_feat_fact(effects)
      [choice_fact_label(:origin_feat), effects.dig("origin_feat", "name")] if effects.dig("origin_feat", "name")
    end

    # The values the option writes in other fields (speed, size), under the label of those fields
    def set_facts(effects, fields_by_key)
      effects["set"].to_h.filter_map do |field_key, value|
        label = fields_by_key.dig(field_key, "label")
        [label, value.is_a?(Numeric) ? number_with_delimiter(value) : value] if label
      end
    end

    def choice_fact_label(fact)
      t("game_tables.choice_summaries.facts.#{fact}")
    end
  end
end
