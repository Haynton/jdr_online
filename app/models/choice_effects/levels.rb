module ChoiceEffects
  # What the effects given level by level share ({ "3" => [...], "5" => [...] }: from the level of the character
  # named, the always prepared spells, the features)
  module Levels
    LEVELS = (1..20).map(&:to_s).freeze

    private

    def by_level?(value)
      value.is_a?(Hash) && (value.keys - LEVELS).empty? && value.values.all?(Array)
    end

    # The entries of every level up to level, in the order of the levels
    def up_to_level(value, level)
      value.to_h.select { |entry_level, _entries| entry_level.to_i <= level }
           .sort_by { |entry_level, _entries| entry_level.to_i }.flat_map(&:last)
    end
  end
end
