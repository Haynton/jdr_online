module CreationStepBehaviors
  # The step asks the origin feat the species lets pick (the human: its trait « Doué », effect feat_choice), with what
  # the feat picked asks (its skills, its spells), on a page of its own after the feats of the background (decision of
  # 28 November: with the book of spells of the background, the page was too long). Shown when the table plays the
  # origin feats and the species picked has that effect. Its summary is in the block of the feats (ChoosesOriginFeats)
  class ChoosesSpeciesFeat < Base
    KEY = "chooses_species_feat".freeze

    def form_partial
      "game_tables/character_steps/species_feat"
    end

    def summary_partial
      nil
    end

    def shown?(game_table, picked_effects, _sheet = {})
      game_table.origin_feats && picked_effects.any? { |effects| effects.key?(ChoiceEffects::FeatChoice::KEY) }
    end

    def fill(character, species_feat: nil, **)
      character.checks_species_feat = true
      character.choose_species_feat(species_feat) if character.feat_choice_settings
    end

    # A species changed on another step drops the feat it no longer lets pick
    def keep_offered(character)
      character.keep_offered_species_feat
    end
  end
end
