# Turns what a player typed in the sheet form (always text) into the values of characters.sheet, by field type:
# numbers become integers, a resource its current value and maximum, a check box true or false.
# A blank field is left out: the sheet only keeps what was filled in. A value that cannot be converted is kept
# as typed, so that CharacterSheetValidator refuses it and the form shows it again under its error
module CharacterSheets
  class Builder
    def initialize(fields:, submitted_values:)
      @fields = fields
      @submitted_values = submitted_values.to_h.stringify_keys
    end

    # Each field converted by its type (FieldTypes): a computed one is never stored, a blank one is left out (a check
    # box is never blank: unchecked is a value too)
    def call
      @fields.each_with_object({}) do |field, sheet|
        type = FieldTypes.of(field)
        typed_value = @submitted_values[field["key"]]
        next if !type.stored? || type.blank?(typed_value)

        sheet[field["key"]] = type.convert(typed_value, field)
      end
    end
  end
end
