module FieldTypes
  # The bonus of an option (the background, rules of 2024) spread on the abilities it raises: +2 and +1, or +1 to each,
  # stored apart from the scores ({ "intelligence" => 2 }) and added to them. Drawn by the abilities section, shown on
  # the summary in the scores of the tiles. Its check reads the other values of the sheet: the option picked, the scores
  class AbilityBonuses < Base
    KEY = "ability_bonuses".freeze
    OWN_PARAMETERS = %w[from].freeze
    REQUIRED_PARAMETERS = %w[from].freeze
    REFERENCES = { "from" => "choice" }.freeze

    def partial
      nil
    end

    def summary_group(_field)
      nil
    end

    # One choice (0, 1 or 2) per ability raised; a bonus of 0 is left out
    def convert(typed_value, _field)
      bonuses = typed_value.to_h.transform_values { |bonus| Integer(bonus.to_s, 10, exception: false) || bonus }
      bonuses.reject { |_ability_key, bonus| bonus.is_a?(Integer) && bonus.zero? }
    end

    # Only the abilities the option picked raises, spread as +2 and +1 or +1 to each (or a part of it, while the player
    # places them), and no score past the maximum of its ability once raised
    def error_for(bonuses, field, character:)
      return [:invalid] unless spread_allowed?(bonuses, raised_abilities(character, field))

      raised_too_high = bonuses.keys.find do |ability_key|
        raised_score(character, ability_key, bonuses) > ability_maximum(character, ability_key)
      end
      [:ability_bonus_too_high, { count: ability_maximum(character, raised_too_high) }] if raised_too_high
    end

    private

    def spread_allowed?(bonuses, raised_abilities)
      return false unless bonuses.is_a?(Hash) && (bonuses.keys - raised_abilities).empty?
      return false unless bonuses.values.all? { |bonus| [1, 2].include?(bonus) }

      bonuses.values.sum <= 3 && bonuses.values.count(2) <= 1
    end

    # The abilities that the option picked in the list named by from raises (ability_bonus_choices of its effects)
    def raised_abilities(character, field)
      list = character.sheet_fields.find { |candidate| candidate["key"] == field["from"] }
      list&.dig("effects", character.sheet[field["from"]].to_s, "ability_bonus_choices").to_a
    end

    def raised_score(character, ability_key, bonuses)
      character.sheet[ability_key].to_i + bonuses[ability_key]
    end

    def ability_maximum(character, ability_key)
      character.sheet_fields.find { |field| field["key"] == ability_key }&.dig("max") || Float::INFINITY
    end
  end
end
