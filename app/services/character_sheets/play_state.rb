# What the rules read about a character beside its sheet (CharacterSheets::SheetReader): the hit dice rolled for the
# levels after the first (Character#kept_hit_point_rolls: nil for their average, HitPointMethods::Roll::NOT_ROLLED while
# a roll the table imposes is still to make), and the values of what it wears and holds (Equippable: its armour, its
# shield; Character#equipped_item_properties)
module CharacterSheets
  PlayState = Data.define(:hit_point_rolls, :equipped_items) do
    def initialize(hit_point_rolls: nil, equipped_items: [])
      super
    end
  end
end
