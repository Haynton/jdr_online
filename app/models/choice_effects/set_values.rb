module ChoiceEffects
  # Values written in fields of the sheet: the speed and size of a species (key set; the class is not named Set, which
  # would hide the Set of Ruby in this module)
  class SetValues < Base
    KEY = "set".freeze
    LIVE = true

    def target_keys(value)
      value.to_h.keys
    end

    # Under the label of the fields written
    def facts(value, fields_by_key)
      value.to_h.filter_map do |field_key, written_value|
        label = fields_by_key.dig(field_key, "label")
        [label, readable(written_value)] if label
      end
    end

    # A field the option before had filled, and the new one does not, is emptied
    def apply(sheet, previous_value, picked_value, **)
      (previous_value.to_h.keys - picked_value.to_h.keys).each { |field_key| sheet.delete(field_key) }
      sheet.merge!(picked_value.to_h)
    end

    private

    # A number with the separator of the language (10,5 in French)
    def readable(written_value)
      written_value.is_a?(Numeric) ? ActiveSupport::NumberHelper.number_to_delimited(written_value) : written_value
    end
  end
end
