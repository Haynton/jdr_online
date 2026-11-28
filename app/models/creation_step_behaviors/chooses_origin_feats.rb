module CreationStepBehaviors
  # The step asks the origin feat of the background (decision of 27 November, a step « Dons » of its own: Magic
  # Initiate of the acolyte and the sage, with its list); the feat the species lets pick (ChoosesSpeciesFeat) and the
  # feats of the levels a character starts above (ChoosesLevelFeats) have their own steps. Shown when the table plays
  # the origin feats and an option picked gives one
  class ChoosesOriginFeats < Base
    KEY = "chooses_origin_feats".freeze

    def form_partial
      "game_tables/character_steps/origin_feats"
    end

    def summary_partial
      "character_sheets/summary/origin_feats"
    end

    def shown?(game_table, picked_effects, _sheet = {})
      origin_feats?(game_table, picked_effects)
    end

    def fill(character, feat_spells: nil, **)
      character.checks_feat_spells = true
      character.choose_origin_feat_spells(feat_spells)
    end

    # A background changed on another step drops what it no longer gives
    def keep_offered(character)
      character.keep_offered_origin_feat_spells
    end

    private

    def origin_feats?(game_table, picked_effects)
      game_table.origin_feats && picked_effects.any? { |effects| effects.key?(ChoiceEffects::OriginFeat::KEY) }
    end
  end
end
