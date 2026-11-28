# The Spells step of the creation as a game of cards (decision of 28 November, the prototype « Sorts en cartes »): one
# row of cards per group of spells, filtered by what the player wants to do (the field of the spells the template
# marks « browse »: the intents), each card in the tone of its school, its big card read in a window, the spells
# picked in a hand at the foot. The browser follows the counts and the hand (spell_hand_controller.js), the server
# decides (CharacterSpellsValidator)
module CharacterSheets
  module CharacterSheets::SpellCardsHelper
    SCOPE = "game_tables.character_steps.spell_cards".freeze
    # One tone per option of the school, in its order (card-tone-1 to 8, application.css): written whole for Tailwind
    TONE_CLASSES = %w[
      [--tone:var(--color-card-tone-1)] [--tone:var(--color-card-tone-2)] [--tone:var(--color-card-tone-3)]
      [--tone:var(--color-card-tone-4)] [--tone:var(--color-card-tone-5)] [--tone:var(--color-card-tone-6)]
      [--tone:var(--color-card-tone-7)] [--tone:var(--color-card-tone-8)]
    ].freeze
    # The card and the link under it lift together (decision): the hover is on the whole of them. relative: the hidden
    # name of « Lire la carte » (sr-only, absolute) stays in its row, which clips it (it widened the page sideways)
    CARD_PLACE_CLASSES = "group/card relative flex w-41 shrink-0 snap-start flex-col items-center gap-0.5 " \
                         "motion-safe:transition motion-safe:duration-150 hover:-translate-y-1 " \
                         "data-faded:opacity-40 data-faded:hover:translate-y-0".freeze
    # Its lines in the tone of its school at 55 %, gold once picked (--line-art, read by the frame and the corners)
    CARD_CLASSES = "group/face relative flex h-[200px] w-full cursor-pointer flex-col items-center overflow-hidden " \
                   "rounded-[14px] border border-line bg-surface px-3.5 pt-3.5 text-center text-ink " \
                   "[--line-art:color-mix(in_srgb,var(--tone)_55%,transparent)] " \
                   "group-hover/card:border-field-line has-checked:border-chosen-line has-checked:bg-primary-soft " \
                   "has-checked:[--line-art:var(--color-brass)] has-disabled:cursor-not-allowed " \
                   "has-[:disabled:checked]:cursor-default has-focus-visible:outline-2 " \
                   "has-focus-visible:outline-offset-2 has-focus-visible:outline-focus-ring".freeze
    MARK_CLASSES = "grid grid-cols-[0.75rem_minmax(0,1fr)] items-start gap-1.5 text-[10.5px] leading-tight " \
                   "text-muted group-has-checked/face:text-primary-soft-ink".freeze
    TAG_CLASSES = "rounded border border-line bg-surface px-1 text-[9.5px] leading-4 font-bold text-muted".freeze
    # The link under the card: no ring after a click (spell_card_dialog_controller.js quiets it), one from the keys
    READ_LINK_CLASSES = "h-5.5 cursor-pointer rounded-md px-2 text-xs font-semibold text-muted underline-offset-3 " \
                        "hover:text-ink hover:underline".freeze
    INTENT_PILL_CLASSES = "inline-flex h-7.5 shrink-0 cursor-pointer items-center gap-1.5 rounded-full border " \
                          "border-line px-3 text-sm font-medium text-ink hover:border-field-line " \
                          "aria-pressed:border-chosen-line aria-pressed:bg-primary-soft aria-pressed:font-bold " \
                          "aria-pressed:text-primary-soft-ink".freeze
    # 6 px above the cards: room to lift on hover inside the row, which hides what overflows it; relative: the cards
    # measure their place from the row (the marks scroll to them)
    CARD_ROW_CLASSES = "no-scrollbar relative mt-0.5 flex snap-x snap-mandatory gap-3 overflow-x-auto px-0.5 pt-1.5 " \
                       "pb-0.5".freeze
    # A part to pick at the Spells step, as an underlined tab: its name, its count; pressed, a gold line under it
    PART_PILL_CLASSES = "group/pill -mb-px inline-flex h-9 cursor-pointer items-center gap-2 border-b-2 " \
                        "border-transparent text-sm font-semibold whitespace-nowrap text-muted hover:text-ink " \
                        "aria-pressed:border-brass aria-pressed:text-ink".freeze
    LEVEL_PILL_CLASSES = "h-6 cursor-pointer rounded-full border border-line px-2 text-[11px] font-semibold " \
                         "whitespace-nowrap text-muted hover:border-field-line aria-pressed:border-chosen-line " \
                         "aria-pressed:bg-primary-soft aria-pressed:text-primary-soft-ink".freeze
    # The search field of the step, a pill as high as the intents beside it (the style of the fields, rounder)
    SEARCH_CLASSES = "h-8 w-full rounded-full border border-line bg-field pr-3 pl-9 text-sm text-ink " \
                     "placeholder:text-muted focus:border-ink focus:outline-none".freeze
    MARKS = [%w[casting_time shared/icons/hourglass], %w[range shared/icons/target],
             %w[duration shared/icons/clock]].freeze
    # The corners mirrored from one drawing: top left, top right, bottom left, bottom right
    CORNER_CLASSES = {
      small: ["top-2.5 left-2.5", "top-2.5 right-2.5 -scale-x-100", "bottom-2.5 left-2.5 -scale-y-100",
              "bottom-2.5 right-2.5 -scale-100"],
      big: ["top-3 left-3", "top-3 right-3 -scale-x-100", "bottom-3 left-3 -scale-y-100", "bottom-3 right-3 -scale-100"]
    }.freeze

    # The field of the spells the template marks to browse them by (the intents), nil when it has none
    def spell_browse_field(character)
      spell_fields_of(character).find { |field| field["browse"] }
    end

    # The tone of the school of a spell: the place of its school among the options of the field
    def spell_card_tone(spell, character)
      options = Array(spell_fields_of(character).find { |field| field["key"] == "school" }&.dig("options"))
      TONE_CLASSES[options.index(spell.properties["school"]).to_i % TONE_CLASSES.size]
    end

    # [["Soigner", 12], ["Attaquer", 30]...]: each value of the field, with the number of cards it shows
    def spell_intent_pills(field, spells)
      field["options"].map do |value|
        [value, spells.count { |spell| spell_intents(spell, field).include?(value) }]
      end
    end

    def spell_intents(spell, field)
      field ? Array(spell.properties[field["key"]]) : []
    end

    # [[label, value, icon], ...]: what it takes to cast it, its range, its duration, each value whole
    def spell_card_marks(spell)
      MARKS.filter_map do |key, icon|
        value = spell.properties[key].to_s
        value = value.split(",").first if key == "casting_time"
        [t("#{SCOPE}.marks.#{key}"), value, icon] if value.present?
      end
    end

    # The box the card toggles counts for its group (pick), or for the spellbook of a wizard (book)
    def spell_card_place_data(spell, field, book: nil)
      { spell_hand_target: "card", intents: spell_intents(spell, field).join("|"), name: spell.name,
        search: spell_search_name(spell), school: spell.properties["school"],
        take_label: (t("#{SCOPE}.write_in_book", label: book.label) if book),
        drop_label: (t("#{SCOPE}.remove_from_book", label: book.label) if book) }.compact
    end

    # « 2 à choisir », « Main pleine », « Trop de sorts : 4 sur 3 », as spell_hand_controller.js writes it
    def spell_cards_left(chosen, allowed)
      return t("#{SCOPE}.over", chosen: chosen, allowed: allowed) if chosen > allowed
      return t("#{SCOPE}.full") if chosen == allowed

      t("#{SCOPE}.left", count: allowed - chosen)
    end

    # « Agrandissement/<wbr>Rapetissement »: a name of one long word may break after its slashes (each part escaped)
    def spell_card_name(spell)
      safe_join(spell.name.split("/"), safe_join(["/", tag.wbr]))
    end

    # « Niv. 2 » on a card of a group whose spells are of several levels (the prepared spells, from the level 3)
    def spell_card_level(spell, group)
      return unless group&.several_levels && group.spells.map(&:level).uniq.size > 1

      t("#{SCOPE}.level_short", level: spell.level)
    end

    # « Évocation · Niveau 2 » on the big card
    def spell_card_kind(spell)
      level = spell.level.zero? ? t("#{SCOPE}.cantrip") : t("#{SCOPE}.level", level: spell.level)
      [spell.properties["school"], level].compact_blank.join(" · ")
    end

    private

    def spell_fields_of(character)
      CatalogEntry.declared_fields(character.game_table, "spell_fields")
    end
  end
end
