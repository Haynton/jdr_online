module FieldTypes
  # An ability: a score in its tile, with its modifier worked out by its rule (modifier, SheetTemplate::MODIFIER_RULES)
  class Ability < Base
    include NumberChecks

    KEY = "ability".freeze
    OWN_PARAMETERS = %w[min max modifier].freeze
    REQUIRED_PARAMETERS = %w[modifier].freeze

    def partial
      "character_sheets/fields/ability"
    end

    def summary_group(_field)
      :tiles
    end

    def convert(typed_value, _field)
      integer_or_typed_value(typed_value)
    end

    def error_for(value, field, **)
      number_error(value, minimum: field["min"], maximum: field["max"], step: field["step"])
    end

    def summary_text(value, _field)
      delimited(value)
    end

    def minimum(field)
      field["min"]
    end
  end
end
