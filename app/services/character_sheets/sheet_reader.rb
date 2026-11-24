# What the computing rules read on a character sheet (ComputedRules): the modifiers of its abilities, the level typed,
# its threshold, the effects of the option chosen in a list, the proficiency bonus. The same reader is given to every
# rule, so that a rule says only how it works out its value. Its twin for the page is the reader given by
# character_sheet_controller.js to app/javascript/computed_rules
module CharacterSheets
  class SheetReader
    attr_reader :fields, :sheet

    # hit_point_rolls: the hit dice rolled for the levels after the first ([5, 3]), nil for their average,
    # HitPointMethods::Roll::NOT_ROLLED while a roll the table imposes is still to make
    # (Character#kept_hit_point_rolls)
    attr_reader :hit_point_rolls

    def initialize(fields:, sheet:, level_thresholds:, modifiers:, hit_point_rolls: nil)
      @fields = fields
      @sheet = sheet
      @level_thresholds = level_thresholds
      @modifiers = modifiers
      @hit_point_rolls = hit_point_rolls
    end

    # nil while the ability has no score
    def modifier(ability_key)
      @modifiers[ability_key]
    end

    # No level typed counts as level 1
    def typed_level(level_key)
      @sheet[level_key].is_a?(Integer) ? @sheet[level_key] : 1
    end

    # The threshold of the level typed: the last one at or under it
    def threshold_of_level(level_key)
      level = typed_level(level_key)
      @level_thresholds.reverse.find { |threshold| level >= threshold["level"] }
    end

    # The effects of the option chosen in the list list_key ({} before a choice)
    def class_effects(list_key)
      list = field(list_key)
      list&.dig("effects", @sheet[list_key].to_s) || {}
    end

    # The value of the computed field proficiency_key (the proficiency bonus of the level), 0 without that field
    def proficiency(proficiency_key)
      proficiency_field = field(proficiency_key)
      proficiency_field ? ComputedRules.of(proficiency_field).value(proficiency_field, self).to_i : 0
    end

    private

    def field(key)
      @fields.find { |candidate| candidate["key"] == key }
    end
  end
end
