# A list drawn as cards (a list with icons: the class, the background, the species;
# character_sheets/sections/_option_cards): its options in cards with their emblem and name, the option picked
# explained under them (its description, what it brings, its features). Each card holds a real radio button, sent with
# the form; the page reads the option picked in a hidden field of the usual id (#character_sheet_<key>), kept in step
# by option_cards_controller.js, so that the effects, the calculation and the lists that depend on it follow the cards
# as they followed the select
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

    # The cards by line from a wide section (three under it): six for a list alone (the class); beside another list,
    # all of them on one line up to six (the backgrounds), else on two lines (the species)
    OPTION_CARD_COLUMNS = { 3 => "@2xl:grid-cols-3", 4 => "@2xl:grid-cols-4", 5 => "@2xl:grid-cols-5",
                            6 => "@2xl:grid-cols-6" }.freeze

    # A line of the sheet of the option picked: its label in a column of the same width on every line
    SHEET_ROW_CLASSES = %w[
      grid gap-4 border-b border-line py-1.5 last:border-b-0 [@media(max-height:820px)]:py-1
    ].join(" ").freeze
    SHEET_LABEL_COLUMN_CLASSES = { alone: "grid-cols-[9rem_minmax(0,1fr)] sm:grid-cols-[12rem_minmax(0,1fr)]",
                                   side_by_side: "grid-cols-[9rem_minmax(0,1fr)]" }.freeze

    # The lists of the section drawn as cards: those with icons
    def option_card_fields(fields)
      fields.select { |field| field["icons"] }
    end

    # The fields under a list drawn as cards: those that depend on it (options_from: the lineage of the species), and,
    # under the last of several lists, the fields that depend on none (the size, under the species: decision, alone
    # at the foot of the page it was far from what it goes with)
    def option_card_following_fields(fields, card_field)
      card_fields = option_card_fields(fields)
      following = fields.select { |field| field["options_from"] == card_field["key"] && !field["icons"] }
      following += option_card_other_fields(fields) if card_fields.size > 1 && card_field == card_fields.last
      following
    end

    # The fields of the section that depend on no list drawn as cards (the size)
    def option_card_other_fields(fields)
      card_keys = option_card_fields(fields).pluck("key")
      fields.reject { |field| field["icons"] || card_keys.include?(field["options_from"]) }
    end

    # After the lists, when there is a single one (the subclass is under the class, as it depends on it)
    def option_card_trailing_fields(fields)
      option_card_fields(fields).size > 1 ? [] : option_card_other_fields(fields)
    end

    def option_card_columns_classes(field, side_by_side)
      count = field["options"].to_a.size
      columns = if side_by_side
                  count <= 6 ? count : (count / 2.0).ceil
                else
                  [count, 6].min
                end
      OPTION_CARD_COLUMNS.fetch(columns.clamp(3, 6))
    end

    def option_card_sheet_row_classes(side_by_side)
      "#{SHEET_ROW_CLASSES} #{SHEET_LABEL_COLUMN_CLASSES.fetch(side_by_side ? :side_by_side : :alone)}"
    end

    def option_card_icon(field, option)
      partial = OptionIcons.partial(field.dig("icons", option))
      partial && render(partial, css_class: "size-6")
    end

    # The hidden field the page reads: no name (the radio buttons are sent), the effects of the options, and a change
    # sent when a card is picked (option_cards_controller.js)
    def option_cards_mirror(character, field)
      data = sheet_choice_effects_data(field).merge(option_cards_target: "mirror", field_key: field["key"])
      data[:action] = "change->character-sheet#applyEffects" if field["effects"]
      hidden_field_tag(nil, sheet_field_value(character, field), id: sheet_field_id(field), data: data)
    end
  end
end
