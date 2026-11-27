module AbilityMethods
  # What every method says of itself: its key, the settings a template gives it, the errors of those settings, and the
  # errors of the scores a player typed (none by default: the scores stay free)
  class Base
    # Every method has a type, a label and a help, written by the template, and may say in a few words what the player
    # does (summary: « Valeurs fixes à placer : 15, 14… », shown under the choice of the way)
    COMMON_PARAMETERS = %w[type label help summary].freeze
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

    # The button at the right of the tray of the abilities step: "Start again" (the placements taken back) by default
    def tray_action_partial
      "character_sheets/ability_methods/start_again"
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

    # The scores typed placed from given values (an array, the results of a roll): each one of the values, each value
    # placed as often as it is there. outside, taken: the error types of a score not among them, of a value taken
    def placement_errors(scores, values, outside:, taken:)
      refused = scores.reject { |_ability, score| values.include?(score) }
      refused.map { |ability, _score| [[ability], outside, { values: values.join(", ") }] } +
        placed_too_often_errors(scores.except(*refused.keys), values, taken)
    end

    # A value typed more often than given: every ability holding it is refused
    def placed_too_often_errors(scores, values, taken)
      scores.group_by { |_ability, score| score }.filter_map do |value, holders|
        next if holders.size <= values.count(value)

        [holders.map(&:first), taken, { value: value }]
      end
    end
  end
end
