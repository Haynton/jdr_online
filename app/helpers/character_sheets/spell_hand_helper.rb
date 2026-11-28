# The hand of the Spells step (game_tables/character_steps/_spell_hand_cards): one packet of cards per part, unfolded
# on its own line with a click
module CharacterSheets
  module CharacterSheets::SpellHandHelper
    # The name of a packet and its count: the button that unfolds or folds it
    PACKET_NAME_CLASSES = "inline-flex cursor-pointer items-center gap-2 rounded text-xs font-semibold " \
                          "whitespace-nowrap text-ink hover:underline focus-visible:outline-2 " \
                          "focus-visible:outline-offset-2 focus-visible:outline-focus-ring".freeze
    # A card of a packet, placed by the controller: folded, the whole packet unfolds it; unfolded, hovered or focused it
    # lifts, and a click puts it back
    PACKET_CARD_CLASSES = "absolute bottom-0 block cursor-pointer rounded-[14px] motion-safe:transition " \
                          "motion-safe:duration-150 hover:z-20 hover:-translate-y-2 focus-visible:z-20 " \
                          "focus-visible:-translate-y-2 focus-visible:outline-2 focus-visible:outline-focus-ring".freeze
  end
end
