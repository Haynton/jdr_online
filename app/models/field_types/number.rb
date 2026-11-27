module FieldTypes
  # A number in a box ("− 30 +"), within its bounds; with a step under 1, decimals typed with a point or a comma (10,5).
  # With labels, a name for each value from its min (the level of a spell: "Cantrip", "Level 1"...), it is a list of
  # those names instead (decision: "− 0 +" did not say that 0 is a cantrip); the value stays the number
  class Number < Base
    include NumberChecks

    KEY = "number".freeze
    OWN_PARAMETERS = %w[min max step labels unit from_table initial_from].freeze
    # In a plain form (the window of a catalog entry): a field like the others, with its "−" and "+" inside it and its
    # unit (decision of 27 November: the box of a sheet broke the grid of the window, beside the lists)
    FORM_PARTIAL = "character_sheets/fields/number_field".freeze
    REFERENCES = { "initial_from" => "computed" }.freeze

    def partial
      "character_sheets/fields/stat"
    end

    def partial_for(field)
      field["labels"] ? INPUT_PARTIAL : partial
    end

    def flow_group(field)
      field["labels"] ? :lists : super
    end

    def form_partial_for(field)
      field["labels"] ? INPUT_PARTIAL : FORM_PARTIAL
    end

    def form_flow_group(_field)
      :lists
    end

    def list_choices(field)
      return unless field["labels"]

      field["labels"].each_with_index.map { |label, index| [label, field["min"].to_i + index] }
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

    def summary_text(value, field)
      label = field["labels"]&.at(value.to_i - field["min"].to_i) if value.is_a?(Integer)
      label || delimited(value)
    end

    def minimum(field)
      field["min"]
    end

    # Beside the name, a number says what it counts: its abbreviation, or its label ("Bonus magique +1", "CA +2")
    def listed_text(value, field)
      name = field["abbreviation"] || field["label"]
      "#{name} #{summary_text(value, field)}"
    end
  end
end
