module AbilityMethods
  # What every method says of itself: its key, the settings a template gives it, the errors of those settings, and the
  # errors of the scores a player typed (none by default: the scores stay free)
  class Base
    # Every method has a type, a label and a help, written by the template
    COMMON_PARAMETERS = %w[type label help].freeze
    OWN_PARAMETERS = [].freeze
    REQUIRED_PARAMETERS = [].freeze

    def key
      self.class::KEY
    end

    def parameters
      COMMON_PARAMETERS + self.class::OWN_PARAMETERS
    end

    def required_parameters
      self.class::REQUIRED_PARAMETERS
    end

    # What the guide of the abilities step shows under "Your scores" (its path in full: a search finds it)
    def guide_partial
      self.class::GUIDE_PARTIAL
    end

    # Its results are placed on the abilities from a list in each tile (ability_roll_controller.js)
    def places_results?
      false
    end

    # The errors of its own settings in a template, as [error type, options] (SheetTemplates::AbilityMethodsCheck).
    # ability_count: how many abilities the sheet has
    def settings_errors(_method, **)
      []
    end

    # The errors of the scores typed ({ "strength" => 15, ... }, only those typed), as [ability keys, error type,
    # options]: no key for an error of all the scores (CharacterAbilityMethodValidator)
    def score_errors(_scores, _method)
      []
    end

    private

    def positive_integer?(value)
      value.is_a?(Integer) && value.positive?
    end
  end
end
