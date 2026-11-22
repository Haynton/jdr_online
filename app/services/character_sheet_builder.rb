# Turns what a player typed in the sheet form (always text) into the values of characters.sheet, by field type:
# numbers become integers, a resource its current value and maximum, a check box true or false.
# A blank field is left out: the sheet only keeps what was filled in. A value that cannot be converted is kept
# as typed, so that CharacterSheetValidator refuses it and the form shows it again under its error
class CharacterSheetBuilder
  def initialize(fields:, submitted_values:)
    @fields = fields
    @submitted_values = submitted_values.to_h.stringify_keys
  end

  # Check boxes (a boolean, the proficiency of a bonus) are always kept: unchecked is a value too.
  # A computed field is never stored (CharacterSheetCalculator)
  CHECK_BOX_TYPES = %w[boolean bonus].freeze

  def call
    @fields.each_with_object({}) do |field, sheet|
      typed_value = @submitted_values[field["key"]]
      next if field["type"] == "computed"
      next if typed_value.blank? && CHECK_BOX_TYPES.exclude?(field["type"])

      sheet[field["key"]] = convert(field["type"], typed_value)
    end
  end

  private

  def convert(type, typed_value)
    case type
    when "number", "ability", "experience" then integer_or_typed_value(typed_value)
    when "resource" then full_resource(typed_value)
    # The check box sends "1" when checked, the hidden field before it "0". For a bonus, it is its proficiency
    when *CHECK_BOX_TYPES then typed_value == "1"
    else typed_value.to_s.strip
    end
  end

  def integer_or_typed_value(typed_value)
    Integer(typed_value.to_s.strip, 10, exception: false) || typed_value
  end

  # At creation, the player gives the maximum: the character starts full
  def full_resource(typed_value)
    maximum = Integer(typed_value.to_s.strip, 10, exception: false)
    maximum ? { "current" => maximum, "max" => maximum } : typed_value
  end
end
