module HitPointMethods
  # What every way says of itself: its key, the settings a template gives it (a label and a help, nothing more), and
  # whether the player rolls dice for it
  class Base
    COMMON_PARAMETERS = %w[type label help].freeze
    REQUIRED_PARAMETERS = [].freeze

    def key
      self.class::KEY
    end

    def parameters
      COMMON_PARAMETERS
    end

    def required_parameters
      REQUIRED_PARAMETERS
    end

    def settings_errors(_method, **)
      []
    end

    def rolls_dice?
      false
    end
  end
end
