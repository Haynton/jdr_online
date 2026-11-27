module CreationStepBehaviors
  # The step asks the origin feats of the creation (decision of 27 November, at the step of the skills): the spells the
  # origin feat of the background gives (Magic Initiate of the acolyte and the sage), and the origin feat the species
  # lets pick (the human) with what it asks
  class ChoosesOriginFeats < Base
    KEY = "chooses_origin_feats".freeze

    def form_partial
      "game_tables/character_steps/origin_feats"
    end

    # The spells show in the block of the spells of the summary
    def summary_partial; end

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
