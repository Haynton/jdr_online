module CreationStepBehaviors
  # The step asks the feats of the creation (decision of 27 November, a step « Dons » of its own): the origin feat of
  # the background (Magic Initiate of the acolyte and the sage, with its spells), the origin feat the species lets pick
  # (the human) with what it asks, and the feats of the levels a character starts above (CharacterLevelFeats: level 4,
  # 8...). Shown when the table plays the origin feats and an option picked gives one, or when the level of the
  # character reaches a level of its class that improves the abilities
  class ChoosesOriginFeats < Base
    KEY = "chooses_origin_feats".freeze

    def form_partial
      "game_tables/character_steps/origin_feats"
    end

    def summary_partial
      "character_sheets/summary/origin_feats"
    end

    def shown?(game_table, picked_effects, sheet = {})
      origin_feats?(game_table, picked_effects) || level_feats?(game_table, picked_effects, sheet)
    end

    def fill(character, feat_spells: nil, species_feat: nil, level_feats: nil, **)
      character.checks_feat_spells = true
      character.choose_origin_feat_spells(feat_spells)
      character.choose_species_feat(species_feat) if character.feat_choice_settings
      character.choose_level_feats(level_feats)
    end

    # A background, a species, a class or a level changed on another step drops what it no longer gives
    def keep_offered(character)
      character.keep_offered_origin_feat_spells
      character.keep_offered_species_feat
      character.keep_offered_level_feats
    end

    private

    def origin_feats?(game_table, picked_effects)
      game_table.origin_feats && picked_effects.any? do |effects|
        effects.key?(ChoiceEffects::OriginFeat::KEY) || effects.key?(ChoiceEffects::FeatChoice::KEY)
      end
    end

    # A level of the improvement of the class picked reached by the level of the sheet (the table's otherwise)
    def level_feats?(game_table, picked_effects, sheet)
      level = level_of(game_table, sheet)
      picked_effects.any? do |effects|
        declared = effects[ChoiceEffects::AbilityScoreImprovement::KEY].to_h
        (Array(declared["levels"]) + Array(declared["epic_levels"])).any? { |improved| improved.to_i <= level }
      end
    end

    def level_of(game_table, sheet)
      field = game_table.character_sheet_fields.find { |candidate| candidate["from_table"] == "starting_level" }
      typed = field && sheet.to_h[field["key"]]
      typed.is_a?(Integer) ? typed : game_table.starting_level
    end
  end
end
