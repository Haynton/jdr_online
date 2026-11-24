module StartingEquipmentMethods
  # What every way says of itself: its key, the settings a template gives it (a label and a help), and the options of
  # a list it keeps (CharacterSheets::StartingEquipment). A list it would leave without any option keeps them all
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

    def offered_options(options)
      kept = options.select { |option| keeps?(option) }
      kept.presence || options
    end

    private

    def keeps?(_option)
      true
    end

    def with_items?(option)
      option["items"].present?
    end
  end
end
