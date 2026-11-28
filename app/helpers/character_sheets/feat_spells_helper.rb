# The spells a feat gives (Magic Initiate): the abilities offered to cast them, each with its modifier, the best
# recommended (decision, prototype "Création façon jeu"), and a book of spells (decision): a list that scrolls in its
# frame beside the page of the spell read
module CharacterSheets
  module FeatSpellsHelper
    # A spell already known by another way: faded, dashed, nothing to tick
    KNOWN_CARD_CLASSES = %w[
      relative flex cursor-not-allowed gap-3 rounded-[10px] border border-dashed border-line px-4 py-3 text-muted
      opacity-60
    ].join(" ").freeze

    # The book: the list and the page side by side from 1024 px, as high as the screen leaves under the band, the title,
    # the head of the feat, the line of the ability, the room above the bar and the bar of buttons (26.875 rem,
    # measured: it ends at the room above the bar), 15 rem at least, so that the page still holds at 1280 × 720 (the
    # page grows with its content: "the height left" has no bound); one under the other before, each of a limited
    # height. relative: what is hidden in it for screen readers (sr-only, absolute) stays in it, never lengthens
    # the page
    BOOK_CLASSES = %w[
      relative grid min-w-0 overflow-hidden rounded-[10px] border border-line bg-surface
      lg:h-[max(15rem,calc(100dvh-26.875rem))] lg:grid-cols-[20rem_minmax(0,1fr)] lg:grid-rows-[minmax(0,1fr)]
    ].join(" ").freeze

    # A spell of the list, one line: its box hidden in it (sr-only), a diamond, its name, its school on the right
    BOOK_ROW_CLASSES = %w[
      group/pick relative flex h-9 cursor-pointer items-center gap-2.5 px-4 text-sm text-ink transition-colors
      hover:bg-surface-raised has-checked:bg-primary-soft has-checked:text-primary-soft-ink
      has-focus-visible:outline-2 has-focus-visible:-outline-offset-2 has-focus-visible:outline-focus-ring
      has-disabled:cursor-not-allowed has-disabled:opacity-45 has-disabled:hover:bg-transparent
    ].join(" ").freeze

    # A spell known by another way, in the list: faded, its page still read
    BOOK_KNOWN_ROW_CLASSES = %w[
      flex h-9 cursor-default items-center gap-2.5 px-4 text-sm text-muted opacity-60 focus-visible:outline-2
      focus-visible:-outline-offset-2 focus-visible:outline-focus-ring
    ].join(" ").freeze

    FeatSpellAbility = Data.define(:key, :label, :modifier, :recommended)

    # The abilities the feat offers, in its order: label, modifier on the sheet (nil before a score), the highest one
    # recommended (none while no ability has a score)
    def feat_spell_abilities(character, settings)
      modifiers = character.computed_sheet_values[:modifiers]
      keys = Array(settings["abilities"])
      best = keys.select { |key| modifiers[key] }.max_by { |key| modifiers[key] }
      keys.map do |key|
        label = character.sheet_fields.find { |field| field["key"] == key }&.dig("label") || key
        FeatSpellAbility.new(key: key, label: label, modifier: modifiers[key], recommended: key == best)
      end
    end

    # The spell read when the book opens: the first one picked, else none (the page says how to read one)
    def feat_spell_first_read(groups, picks)
      picked_keys = Array(picks["cantrips"]) + Array(picks["spell"])
      groups.flat_map { |_kind, spells, _count| spells.to_a }.find { |spell| picked_keys.include?(spell.key) }
    end

    # « Donné par votre historique (Sage) », « Choisi grâce à votre espèce (Humain) », « Pris au niveau 4 »
    def feat_spell_row_origin(character, deck)
      scope = "game_tables.character_steps.feat_spells"
      return t("#{scope}.taken_at_level", level: deck.picks["level"]) if deck.picks["source"].nil?

      key = deck.source == CharacterFeats::BACKGROUND_SOURCE ? "given_by_background" : "chosen_through_species"
      t("#{scope}.#{key}", option: character.feat_origin("source" => deck.source))
    end
  end
end
