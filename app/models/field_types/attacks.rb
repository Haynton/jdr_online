module FieldTypes
  # The attacks of an NPC or a monster, one line each (decision: lines rather than one text, so that the game room can
  # roll them later): its name, its bonus to hit, its damage ("1d6+2 tranchants"), its reach or range. Stored as an
  # array of { "name", "to_hit", "damage", "range" }, in the order typed
  class Attacks < Base
    KEY = "attacks".freeze
    PARTS = %w[name to_hit damage range].freeze
    MAX_ATTACKS = 20
    MAX_TEXT_LENGTH = 100
    TO_HIT_BOUNDS = (-20..100)

    def partial
      "character_sheets/fields/attacks"
    end

    def flow_group(_field)
      :attacks
    end

    # Not on the summary of a player character
    def summary_group(_field)
      nil
    end

    # Every line removed is a value too: no attacks left
    def kept_when_blank?
      true
    end

    # The lines as the form sends them ({ "0" => { "name" => …, … } }, by position), the blank ones left out. A bonus
    # that is not a whole number is kept as typed, so that the check refuses it
    def convert(typed_value, _field)
      lines = typed_value.respond_to?(:values) ? typed_value.values : Array(typed_value)
      lines.filter_map { |line| attack_line(line) }
    end

    def error_for(value, _field, **)
      return [:invalid] unless value.is_a?(Array) && value.all?(Hash)
      return [:too_many_attacks, { count: MAX_ATTACKS }] if value.size > MAX_ATTACKS

      value.lazy.filter_map { |attack| attack_error(attack) }.first
    end

    private

    def attack_line(line)
      parts = line.to_h.stringify_keys.slice(*PARTS).transform_values { |part| part.to_s.strip }
      return if parts.values.all?(&:blank?)

      to_hit = parts["to_hit"].delete_prefix("+")
      parts.merge("to_hit" => Integer(to_hit, 10, exception: false) || parts["to_hit"].presence).compact_blank
    end

    def attack_error(attack)
      return [:attack_without_name] if attack["name"].blank?
      return [:attack_bonus_not_integer] unless attack["to_hit"].nil? || TO_HIT_BOUNDS.cover?(attack["to_hit"])
      return [:invalid] unless (attack.keys - PARTS).empty?

      [:too_long, { count: MAX_TEXT_LENGTH }] if attack.values_at("name", "damage", "range").compact.any? do |text|
        text.to_s.length > MAX_TEXT_LENGTH
      end
    end
  end
end
