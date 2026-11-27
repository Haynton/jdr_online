module ChoiceEffects
  # The expertise an option gives (decision of 26 November, SRD 5.2.1: the rogue, the bard, the ranger, the wizard
  # scholar): from a level of the character, a count of skills it is proficient in whose proficiency bonus counts twice,
  # chosen at the step of the skills; from: the skills it may pick among (the wizard), any of its proficient skills
  # otherwise. Counted and checked by CharacterSheets::ExpertiseChoices
  class ExpertiseChoices < Base
    KEY = "expertise_choices".freeze
    TARGET_TYPE = "bonus".freeze
    PARAMETERS = %w[level count from].freeze

    def target_keys(value)
      Array(value).flat_map { |entry| entry.is_a?(Hash) ? Array(entry["from"]) : [] }
    end

    def value_errors(value, **)
      return [] if value.is_a?(Array) && value.all? { |entry| valid_entry?(entry) }

      [[:unknown_effect_value, { effect: KEY, value: value.to_s.truncate(60) }]]
    end

    def facts(value, _fields_by_key)
      entries = Array(value).select { |entry| valid_entry?(entry) }
      return [] if entries.empty?

      texts = entries.map do |entry|
        I18n.t("game_tables.choice_summaries.expertise_value", level: entry["level"], count: entry["count"])
      end
      [[fact_label(:expertise), texts.to_sentence]]
    end

    private

    def valid_entry?(entry)
      entry.is_a?(Hash) && (entry.keys - PARAMETERS).empty? && entry["level"].is_a?(Integer) &&
        entry["level"].between?(1, 20) && entry["count"].is_a?(Integer) && entry["count"].positive? &&
        (entry["from"].nil? || entry["from"].is_a?(Array))
    end
  end
end
