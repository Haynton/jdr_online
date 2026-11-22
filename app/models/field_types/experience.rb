module FieldTypes
  # Experience points, in a box, from 0
  class Experience < Base
    include NumberChecks

    KEY = "experience".freeze

    def partial
      "character_sheets/fields/stat"
    end

    def boxed?
      true
    end

    def summary_group(_field)
      :boxes
    end

    def convert(typed_value, _field)
      integer_or_typed_value(typed_value)
    end

    def error_for(value, _field, **)
      number_error(value, minimum: 0)
    end

    def summary_text(value, _field)
      delimited(value)
    end
  end
end
