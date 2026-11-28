# What the computing rules read on a character sheet (ComputedRules): the modifiers of its abilities, the level typed,
# its threshold, the effects of the option chosen in a list, the proficiency bonus. The same reader is given to every
# rule, so that a rule says only how it works out its value. Its twin for the page is the reader given by
# character_sheet_controller.js to app/javascript/computed_rules
module CharacterSheets
  class SheetReader
    attr_reader :fields, :sheet

    # play_state: what the rules read beside the sheet (CharacterSheets::PlayState: the hit dice rolled, what the
    # character wears)
    def initialize(fields:, sheet:, level_thresholds:, modifiers:, play_state: PlayState.new)
      @fields = fields
      @sheet = sheet
      @level_thresholds = level_thresholds
      @modifiers = modifiers
      @play_state = play_state
    end

    # The hit dice rolled for the levels after the first ([5, 3]), nil for their average
    def hit_point_rolls
      @play_state.hit_point_rolls
    end

    # The values of the items the character wears and holds (its armour, its shield), [] for none
    def equipped_items
      @play_state.equipped_items
    end

    # The effects of its fighting style ({ "armored_armor_class_bonus" => 1 }), {} for none
    def fighting_style_effects
      @play_state.fighting_style_effects
    end

    # The effects of its feats ({ "initiative_proficiency" => true }), {} for none
    def feat_effects
      @play_state.feat_effects
    end

    # What its magic items give ({ "armor_class_bonus" => 1, "abilities" => { "constitution" => 19 } }), {} for none
    def magic_effects
      @play_state.magic_effects
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

    # The effects of the option chosen in the list list_key ({} before a choice), with those of the options chosen in
    # the lists that depend on it (options_from: the subclass adds to its class, the unarmoured defense of the
    # draconic sorcerer)
    def class_effects(list_key)
      [list_key, *refining_list_keys(list_key)].reduce({}) do |effects, key|
        effects.merge(field(key)&.dig("effects", @sheet[key].to_s) || {})
      end
    end

    # The whole number typed in number_key, 0 without that field or a number
    def typed_number(number_key)
      @sheet[number_key].is_a?(Integer) ? @sheet[number_key] : 0
    end

    # The value of the computed field proficiency_key (the proficiency bonus of the level), 0 without that field
    def proficiency(proficiency_key)
      proficiency_field = field(proficiency_key)
      proficiency_field ? ComputedRules.of(proficiency_field).value(proficiency_field, self).to_i : 0
    end

    private

    def refining_list_keys(list_key)
      @fields.select { |candidate| candidate["options_from"] == list_key }.pluck("key")
    end

    def field(key)
      @fields.find { |candidate| candidate["key"] == key }
    end
  end
end
