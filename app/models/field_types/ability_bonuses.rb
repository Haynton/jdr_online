module FieldTypes
  # The bonus of an option (the background) spread on the abilities it raises, by the rule of the template: total
  # points in all, max_per_ability at most on one ability (rules of 2024: 3 and 2, that is +2 and +1, or +1 to each),
  # its help saying it in the words of the game. Stored apart from the scores ({ "intelligence" => 2 }) and added to
  # them. Drawn by the abilities section, shown on the summary in the scores of the tiles. Its check reads the other
  # values of the sheet: the option picked, the scores
  class AbilityBonuses < Base
    KEY = "ability_bonuses".freeze
    OWN_PARAMETERS = %w[from total max_per_ability].freeze
    REQUIRED_PARAMETERS = %w[from total max_per_ability].freeze
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

    # The choices of one ability: +0 up to max_per_ability
    def choices(field)
      (0..field["max_per_ability"].to_i).to_a
    end

    # More than total points, or more than max_per_ability on one ability
    def too_much?(bonuses, field)
      bonuses.values.sum > field["total"].to_i || bonuses.values.any? { |bonus| bonus > field["max_per_ability"].to_i }
    end

    # Only the abilities the option picked raises, spread by the rule of the field (or a part of it, while the player
    # places them), and no score past the maximum of its ability once raised
    def error_for(bonuses, field, character:)
      return [:invalid] unless spread_allowed?(bonuses, field, raised_abilities(character, field))

      raised_too_high = bonuses.keys.find do |ability_key|
        raised_score(character, ability_key, bonuses) > ability_maximum(character, ability_key)
      end
      [:ability_bonus_too_high, { count: ability_maximum(character, raised_too_high) }] if raised_too_high
    end

    private

    def spread_allowed?(bonuses, field, raised_abilities)
      return false unless bonuses.is_a?(Hash) && (bonuses.keys - raised_abilities).empty?
      return false unless bonuses.values.all? { |bonus| bonus.is_a?(Integer) && bonus.positive? }

      !too_much?(bonuses, field)
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
