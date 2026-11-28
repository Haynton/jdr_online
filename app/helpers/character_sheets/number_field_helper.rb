# A number in a plain form (the window of a catalog entry, character_sheets/fields/_number_field): a field like the
# others, 40 px high under its label, its "−" and "+" inside it at both ends and its unit beside the value (decision
# of 27 November, after six tries: the box of a sheet broke the grid of the window beside the lists). The whole field
# carries the look of an input (FIELD_CLASSES), its focus and its error included, its number typed in the middle
module CharacterSheets
  module NumberFieldHelper
    FIELD_CLASSES = %w[
      flex h-10 w-full items-center rounded-lg border border-transparent bg-field text-sm text-ink
      hover:border-field-line focus-within:border-ink focus-within:ring-3 focus-within:ring-ink/10
      has-aria-invalid:border-error-ink has-aria-invalid:bg-error-bg has-aria-invalid:ring-1
      has-aria-invalid:ring-error-ink
    ].join(" ").freeze
    INPUT_CLASSES = [
      "h-full min-w-0 flex-1 border-0 bg-transparent px-1 font-semibold text-ink tabular-nums focus:outline-none",
      *FieldsHelper::NO_ARROWS_CLASSES
    ].join(" ").freeze
    # With a unit, the number and its unit meet in the middle (decision of 27 November: pushed against the "+", « kg »
    # was far from « 1,5 »): the number at the right of the left half, the unit at the left of the right half
    VALUE_ALIGN_CLASSES = { true => "text-right", false => "text-center" }.freeze
    UNIT_CLASSES = "min-w-0 flex-1 pl-1 text-left text-muted".freeze
    BUTTON_CLASSES = "flex h-full w-9 shrink-0 cursor-pointer items-center justify-center rounded-lg text-muted " \
                     "hover:text-ink".freeze
    # A step finer than half a unit (the weight of an item, to the gram) is for typing: "−" and "+" go by one
    FINE_STEP = 0.5

    # Its help and its error are under the field, not in a note of a box: the field is described by them
    def number_field_input(character, field)
      classes = "#{INPUT_CLASSES} #{VALUE_ALIGN_CLASSES.fetch(field['unit'].present?)}"
      options = sheet_number_options(character, field).merge(class: classes, data: { number_stepper_target: "input" })
      invalid = sheet_field_error(character, field).present?
      described_by = [("#{sheet_field_id(field)}_hint" if sheet_field_hint(field)),
                      ("#{sheet_field_id(field)}_error" if invalid)].compact
      options[:aria] = { invalid: (true if invalid), describedby: described_by.join(" ").presence }.compact
      number_field_tag(sheet_field_name(field), sheet_field_value(character, field), options)
    end

    # The stepper goes by the step of the field, or by one when its step is only there for typing decimals
    def number_field_stepper_data(field)
      step = field["step"]
      increment = step && step < FINE_STEP ? 1 : nil
      { controller: "number-stepper", number_stepper_increment_value: increment }.compact
    end
  end
end
