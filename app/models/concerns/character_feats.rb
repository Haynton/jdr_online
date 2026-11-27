# The feats of a player's character (decision of 27 November): the origin feat of its background and those it took
# (characters.feats, at a level gained: LevelUp; the origin feat of the human, at its creation), read by
# CharacterSheets::Feats. Their points to the abilities and their effects reach the rules through the play state of
# the sheet (Character#computed_sheet_values)
module CharacterFeats
  extend ActiveSupport::Concern

  def feat_list
    CharacterSheets::Feats.new(self)
  end

  # What its feats give the rules (CharacterSheets::PlayState): their points to the abilities, their effects
  def feat_play_values
    return {} unless pc?

    feats = feat_list
    { ability_increases: feats.ability_increases.to_h, feat_effects: feats.rule_effects }
  end

  # The effects of the fighting styles its feats give, with those of the style picked of its class
  def fighting_style_effects_with_feats(class_style_effects)
    return class_style_effects unless pc?

    class_style_effects.merge(feat_list.rule_effects.except("initiative_proficiency"))
  end
end
