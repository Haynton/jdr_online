module CreationStepBehaviors
  # The step asks the feats of the levels a character starts above (CharacterLevelFeats: level 4, 8...), on a step of
  # their own (decision of 28 November: under the origin feat, they made a page of 5 600 px), one level at a time.
  # Shown when the level of the character reaches a level of its class that improves the abilities. Its summary is in
  # the block of the feats (ChoosesOriginFeats)
  class ChoosesLevelFeats < Base
    KEY = "chooses_level_feats".freeze

    def form_partial
      "game_tables/character_steps/level_feats"
    end

    def summary_partial
      nil
    end

    def shown?(game_table, picked_effects, sheet = {})
      level = level_of(game_table, sheet)
      picked_effects.any? do |effects|
        declared = effects[ChoiceEffects::AbilityScoreImprovement::KEY].to_h
        (Array(declared["levels"]) + Array(declared["epic_levels"])).any? { |improved| improved.to_i <= level }
      end
    end

    def fill(character, level_feats: nil, **)
      character.checks_level_feats = true
      character.choose_level_feats(level_feats)
    end

    # A class or a level changed on another step drops the feats of the levels it no longer reaches
    def keep_offered(character)
      character.keep_offered_level_feats
    end

    private

    # The level of the sheet when the players choose it, the table's otherwise
    def level_of(game_table, sheet)
      field = game_table.character_sheet_fields.find { |candidate| candidate["from_table"] == "starting_level" }
      typed = field && sheet.to_h[field["key"]]
      typed.is_a?(Integer) ? typed : game_table.starting_level
    end
  end
end
