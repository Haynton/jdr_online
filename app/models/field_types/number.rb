module FieldTypes
  # A number in a box ("− 30 +"), within its bounds; with a step under 1, decimals typed with a point or a comma (10,5)
  class Number < Base
    include NumberChecks

    KEY = "number".freeze
    OWN_PARAMETERS = %w[min max step from_table].freeze

    def partial
      "character_sheets/fields/stat"
    end

    def boxed?
      true
    end

    def summary_group(_field)
      :boxes
    end

    # A whole value stays an integer (9, not 9.0)
    def convert(typed_value, field)
      return integer_or_typed_value(typed_value) unless decimal_step?(field["step"])

      number = Float(typed_value.to_s.strip.tr(",", "."), exception: false)
      return typed_value unless number

      number == number.to_i ? number.to_i : number
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
