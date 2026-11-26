module FieldTypes
  # A value worked out from the others by one of the rules of ComputedRules (app/models/computed_rules), in a box:
  # never stored, never typed
  class Computed < Base
    KEY = "computed".freeze
    OWN_PARAMETERS = %w[rule based_on level_from class_from proficiency bonus_from].freeze
    REQUIRED_PARAMETERS = %w[rule].freeze
    REFERENCES = {
      "based_on" => "ability", "level_from" => "number", "class_from" => "choice", "proficiency" => "computed",
      "bonus_from" => "number"
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

    # The sentence of its rule ("10 + le modificateur de Dextérité..."), nil for a rule the registry does not know
    def calculation_key(field)
      "sheet_templates.calculations.rules.#{field['rule']}" if ComputedRules.find(field["rule"])
    end
  end
end
