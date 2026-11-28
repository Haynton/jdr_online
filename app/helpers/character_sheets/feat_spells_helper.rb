# The spells a feat gives to pick (Magic Initiate, CharacterSheets::FeatSpells): a spell the character already knows
# elsewhere (its class, another feat) stays in its list, its box disabled, with where it comes from (decision of
# 27 November: a spell hidden would leave the player wondering where it went)
module CharacterSheets
  module FeatSpellsHelper
    KNOWN_CARD_CLASSES = "flex cursor-not-allowed gap-3 rounded-lg border border-dashed border-line px-3 py-2.5".freeze
  end
end
