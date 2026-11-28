# Works out the values of a character sheet that the player does not type, by the rules the template picked from
# closed lists (never a formula): the modifier of an ability (ModifierRules), the computed fields (ComputedRules: the
# proficiency bonus of the level, the initiative, the hit dice...), and the bonuses of the saving throws and skills
# (ability modifier, plus the proficiency when ticked).
# Nothing here is stored: the sheet keeps what the player typed, so a computed value is never out of date.
# character_sheet_controller.js works them out the same way while the player types: changing one means changing both
module CharacterSheets
  class Calculator
    # play_state: what the rules read beside the sheet (the hit dice rolled, what the character wears, the effects of
    # its fighting style: CharacterSheets::PlayState)
    def initialize(fields:, sheet:, level_thresholds:, play_state: PlayState.new)
      @fields = fields
      @play_state = play_state
      @sheet = sheet.to_h
      @level_thresholds = level_thresholds.to_a.sort_by { |threshold| threshold["level"] }
    end

    # scores: by ability key, the score raised by the bonus of the background (ability_bonuses), nil until typed;
    # modifiers: worked out from those scores; values: the computed and bonus fields, by key
    def call
      scores = ability_scores
      modifiers = ability_modifiers(scores)
      computed_values = computed_field_values(modifiers)
      { scores: scores, modifiers: modifiers, values: computed_values.merge(bonus_values(modifiers, computed_values)) }
    end

    private

    def ability_fields
      @fields.select { |field| field["type"] == "ability" }
    end

    # The score typed, plus the bonus placed on it and the points of its feats (both kept apart, decisions); a magic
    # item that sets the ability to a score (Amulet of Health: 19) raises it to that score, never lowers it
    def ability_scores
      ability_fields.to_h do |field|
        key = field["key"]
        score = @sheet[key]
        next [key, nil] unless score.is_a?(Integer)

        raised = score + ability_bonuses[key].to_i + @play_state.ability_increases[key].to_i
        [key, [raised, magic_scores[key].to_i].max]
      end
    end

    def magic_scores
      @play_state.magic_effects.to_h["abilities"].to_h
    end

    def ability_bonuses
      @ability_bonuses ||= begin
        bonus_field = @fields.find { |field| field["type"] == "ability_bonuses" }
        bonus_field ? @sheet[bonus_field["key"]].to_h : {}
      end
    end

    def ability_modifiers(scores)
      ability_fields.to_h { |field| [field["key"], ModifierRules.modifier(scores[field["key"]], field["modifier"])] }
    end

    # Each computed field by its rule (ComputedRules), which reads the sheet through a SheetReader
    def computed_field_values(modifiers)
      reader = SheetReader.new(fields: @fields, sheet: @sheet, level_thresholds: @level_thresholds,
                               modifiers: modifiers, play_state: @play_state)
      @fields.select { |field| field["type"] == "computed" }
             .to_h { |field| [field["key"], ComputedRules.of(field).value(field, reader)] }
    end

    # nil while the ability has no score: a bonus cannot be worked out yet
    def bonus_values(modifiers, computed_values)
      @fields.select { |field| field["type"] == "bonus" }.to_h do |field|
        modifier = modifiers[field["based_on"]]
        factor = FieldTypes::Bonus.proficiency_factor(@sheet[field["key"]])
        proficiency = factor * computed_values[field["proficiency"]].to_i
        [field["key"], modifier && (modifier + proficiency)]
      end
    end
  end
end
