# The box of a number, a resource or a computed value (character_sheets/fields/_stat), the same wherever it is on the
# character sheet (decision: one look per type), and the switch of a yes-or-no value (character_sheets/fields/_switch)
module CharacterSheets
  module StatsHelper
    # The name at the top of a box: two lines at most, room kept for two, so that the values below line up
    STAT_LABEL_CLASSES = %w[
      line-clamp-2 min-h-[2lh] w-full text-center text-[11px] leading-tight font-semibold tracking-wider text-muted
      uppercase
    ].join(" ").freeze
    # The track and the knob of shared/_switch, drawn by the check box before them (peer-checked:) instead of
    # aria-checked: same look, 44 x 24 px, knob of 20 px
    SWITCH_TRACK_CLASSES = %w[
      block h-6 w-11 rounded-full bg-field-line transition-colors duration-150 peer-checked:bg-primary
      peer-focus-visible:outline-2 peer-focus-visible:outline-offset-2 peer-focus-visible:outline-focus-ring
      motion-reduce:transition-none
    ].join(" ").freeze
    SWITCH_KNOB_CLASSES = %w[
      pointer-events-none absolute top-0.5 left-0.5 size-5 rounded-full bg-white shadow-sm transition-transform
      duration-150 peer-checked:translate-x-5 peer-checked:bg-primary-ink motion-reduce:transition-none
    ].join(" ").freeze

    # A computed value is shown large; a number, a resource or an experience sits between "−" and "+"
    def sheet_stat_computed?(field)
      field["type"] == "computed"
    end

    def stat_label_classes
      STAT_LABEL_CLASSES
    end

    def switch_track_classes
      SWITCH_TRACK_CLASSES
    end

    def switch_knob_classes
      SWITCH_KNOB_CLASSES
    end
  end
end
