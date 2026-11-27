# What the rules read about a character beside its sheet (CharacterSheets::SheetReader): the hit dice rolled for the
# levels after the first (Character#kept_hit_point_rolls: nil for their average, HitPointMethods::Roll::NOT_ROLLED while
# a roll the table imposes is still to make), and the values of what it wears and holds (Equippable: its armour, its
# shield; Character#equipped_item_properties), the effects of its fighting styles (Defense: a bonus to the armour
# class while armoured), and what its feats give (CharacterFeats: the points they add to the abilities, kept apart from
# the score typed like the bonus of the background; their other effects, the proficiency to the initiative of Alert)
module CharacterSheets
  PlayState = Data.define(:hit_point_rolls, :equipped_items, :fighting_style_effects, :ability_increases,
                          :feat_effects) do
    def initialize(hit_point_rolls: nil, equipped_items: [], fighting_style_effects: {}, ability_increases: {},
                   feat_effects: {})
      super
    end
  end
end
