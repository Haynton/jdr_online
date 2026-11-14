module Dev
  class ComponentsController < ApplicationController
    COLOR_SWATCHES = [
      { name: "page", css_class: "bg-page" },
      { name: "surface", css_class: "bg-surface" },
      { name: "surface-raised", css_class: "bg-surface-raised" },
      { name: "field", css_class: "bg-field" },
      { name: "line", css_class: "bg-line" },
      { name: "primary", css_class: "bg-primary" },
      { name: "primary-soft", css_class: "bg-primary-soft" },
      { name: "logo-bg", css_class: "bg-logo-bg" }
    ].freeze

    ICON_NAMES = %w[sun moon plus link eye eye_off log_out check x chevron_down].freeze

    skip_before_action :authenticate_user!

    def show
      @color_swatches = COLOR_SWATCHES
      @icon_names = ICON_NAMES
    end
  end
end
