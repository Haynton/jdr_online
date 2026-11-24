module MapLayouts
  # Checks how a map is made (the key "mode" of its layout: drawn, or played on a picture of one's own) and how its
  # picture sits under the grid (the key "picture"): its width in cells (its height follows its proportions), its
  # offset in units of the map (24 per cell) and its opacity. Both may be missing: a map drawn, its picture never
  # set. Gives the first error, [type, options], or nil
  class PictureCheck
    MODES = %w[draw picture].freeze
    SETTING_KEYS = %w[cells_wide offset_x offset_y opacity].freeze
    CELLS_WIDE = (1..200)
    # Far enough to move a picture off the grid by its whole width, no further
    OFFSETS = (-10_000..10_000)
    OPACITIES = (0.1..1)

    def initialize(layout)
      @mode = layout["mode"]
      @settings = layout["picture"]
    end

    def call
      return [:unknown_mode, { mode: @mode }] unless @mode.nil? || MODES.include?(@mode)
      return if @settings.nil?

      [:invalid_picture, {}] unless well_formed_settings?
    end

    private

    def well_formed_settings?
      @settings.is_a?(Hash) && @settings.keys.sort == SETTING_KEYS.sort &&
        within?("cells_wide", CELLS_WIDE) && within?("offset_x", OFFSETS) && within?("offset_y", OFFSETS) &&
        within?("opacity", OPACITIES)
    end

    def within?(key, bounds)
      value = @settings[key]
      value.is_a?(Numeric) && bounds.cover?(value)
    end
  end
end
