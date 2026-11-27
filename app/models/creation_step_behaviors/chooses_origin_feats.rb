module CreationStepBehaviors
  # The step asks the origin feats of the creation (decision of 27 November, a step « Dons » of its own): the origin
  # feat of the background (Magic Initiate of the acolyte and the sage, with its spells), and the origin feat the
  # species lets pick (the human) with what it asks. Shown only when the table plays the origin feats and an option
  # picked gives one
  class ChoosesOriginFeats < Base
    KEY = "chooses_origin_feats".freeze

    def form_partial
      "game_tables/character_steps/origin_feats"
    end

    def summary_partial
      "character_sheets/summary/origin_feats"
    end

    def shown?(game_table, picked_effects)
      game_table.origin_feats && picked_effects.any? do |effects|
        effects.key?(ChoiceEffects::OriginFeat::KEY) || effects.key?(ChoiceEffects::FeatChoice::KEY)
      end
    end

    def fill(character, feat_spells: nil, species_feat: nil, **)
      character.checks_feat_spells = true
      character.choose_origin_feat_spells(feat_spells)
      character.choose_species_feat(species_feat) if character.feat_choice_settings
    end

    # A background or a species changed on another step drops what it no longer gives
    def keep_offered(character)
      character.keep_offered_origin_feat_spells
      character.keep_offered_species_feat
    end
  end
end
