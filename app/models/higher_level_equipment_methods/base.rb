module HigherLevelEquipmentMethods
  # What every way says of itself: its key, the settings a template gives it, and what a character of a level gets
  # beside its normal starting equipment (its tier: gold, gold rolled, magic items by rarity), nil for nothing
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

    def tier_for(_method, _level)
      nil
    end
  end
end
