module FieldTypes
  # The checks and conversions shared by the numbers (number, ability, experience): an integer, or a multiple of a step
  # under 1 (half metres: 10.5), within the bounds of the field
  module NumberChecks
    private

    def number_error(value, minimum:, maximum: nil, step: nil)
      return (decimal_step?(step) ? [:invalid] : [:not_an_integer]) unless allowed_number?(value, step)
      return [:greater_than_or_equal_to, { count: minimum }] if minimum && value < minimum

      [:less_than_or_equal_to, { count: maximum }] if maximum && value > maximum
    end

    def allowed_number?(value, step)
      return value.is_a?(Integer) unless decimal_step?(step)

      value.is_a?(Numeric) && ((value / step.to_f).round(6) % 1).zero?
    end

    def decimal_step?(step)
      step.to_f.positive? && step.to_f < 1
    end

    def integer_or_typed_value(typed_value)
      Integer(typed_value.to_s.strip, 10, exception: false) || typed_value
    end

    # A number with the separator of the language (10,5)
    def delimited(value)
      value.nil? ? nil : ActiveSupport::NumberHelper.number_to_delimited(value)
    end
  end
end
