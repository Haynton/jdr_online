# A list drawn as cards (a list with icons, the class: character_sheets/sections/_option_cards): its options in cards
# with their emblem and name on the left, the option picked explained on the right (its description, what it brings,
# its features). Each card holds a real radio button, sent with the form; the page reads the option picked in a hidden
# field of the usual id (#character_sheet_<key>), kept in step by option_cards_controller.js, so that the effects, the
# calculation and the lists that depend on it follow the cards as they followed the select
module CharacterSheets
  module OptionCardsHelper
    # The card: a border all around, no background at rest; picked, the border chosen-line and the tonal gold, no
    # shadow (decision). Its height follows the height of the screen (decision: the step holds in it without
    # scrolling, down to 1280 × 720)
    OPTION_CARD_CLASSES = %w[
      flex h-[clamp(4rem,9vh,5.5rem)] cursor-pointer flex-col items-center justify-center gap-2 rounded-[10px] border
      border-line px-1 text-center text-muted transition-colors hover:border-field-line hover:bg-surface
      has-checked:border-chosen-line has-checked:bg-primary-soft has-checked:text-primary-soft-ink
      has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-focus-ring
    ].join(" ").freeze

    def option_card_icon(field, option)
      partial = OptionIcons.partial(field.dig("icons", option))
      partial && render(partial, css_class: "size-6")
    end

    # The hidden field the page reads: no name (the radio buttons are sent), the effects of the options, and a change
    # sent when a card is picked (option_cards_controller.js)
    def option_cards_mirror(character, field)
      data = sheet_choice_effects_data(field).merge(option_cards_target: "mirror")
      data[:action] = "change->character-sheet#applyEffects" if field["effects"]
      hidden_field_tag(nil, sheet_field_value(character, field), id: sheet_field_id(field), data: data)
    end
  end
end
