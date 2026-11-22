module FieldTypes
  # A value worked out from the others by one of the rules of ComputedRules (app/models/computed_rules), in a box:
  # never stored, never typed
  class Computed < Base
    KEY = "computed".freeze
    OWN_PARAMETERS = %w[rule based_on level_from class_from proficiency].freeze
    REQUIRED_PARAMETERS = %w[rule].freeze
    REFERENCES = {
      "based_on" => "ability", "level_from" => "number", "class_from" => "choice", "proficiency" => "computed"
    }.freeze

    def partial
      "character_sheets/fields/stat"
    end

    def boxed?
      true
    end

    def summary_group(_field)
      :boxes
    end

    def stored?
      false
    end
  end
end
