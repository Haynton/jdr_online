# The help of a field in a bubble (decision of 27 November: under each field, the helps spread the fields of the window
# of a catalog entry apart): in a block given to with_help_bubbles, a field with a help shows a button (i) after its
# label, which opens its help over the fields below, without pushing them (help_bubble_controller.js; Escape or a click
# elsewhere closes it). Without JavaScript, the help stays under the field. Outside such a block (the character sheet),
# nothing changes
module CharacterSheets
  module HelpBubblesHelper
    LABEL_ROW_CLASSES = "mb-1.5 flex items-center gap-1".freeze
    LABEL_CLASSES = "text-[13px] font-semibold text-ink".freeze
    BUTTON_CLASSES = "flex size-5 shrink-0 cursor-pointer items-center justify-center rounded-full text-muted " \
                     "hover:bg-surface-raised hover:text-ink".freeze
    # Laid over the fields below by the controller, once it is there (written here in full, for Tailwind)
    BUBBLE_CLASSES = "absolute top-full left-0 z-30 mt-1 w-72 max-w-full rounded-lg border border-line bg-surface " \
                     "p-3 text-xs text-ink shadow-lg".freeze

    def with_help_bubbles
      previous = @sheet_help_bubbles
      @sheet_help_bubbles = true
      yield
    ensure
      @sheet_help_bubbles = previous
    end

    # Whether this help goes in a bubble: in a block of with_help_bubbles, for a field that has one
    def sheet_help_bubble?(hint)
      @sheet_help_bubbles.present? && hint.present?
    end

    # The field block that holds the bubble: placed relative to it, and watched by its controller
    def sheet_help_bubble_block_data(hint)
      return {} unless sheet_help_bubble?(hint)

      { controller: "help-bubble",
        action: "keydown@window->help-bubble#closeOnEscape click@window->help-bubble#closeOutside" }
    end

    def sheet_help_hint_id(field)
      "#{sheet_field_id(field)}_hint"
    end
  end
end
