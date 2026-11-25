module FieldTypes
  # A text: one line when it is short (short: true), a text area otherwise
  class Text < Base
    KEY = "text".freeze
    OWN_PARAMETERS = %w[short].freeze
    MAX_LENGTH = 2000

    def flow_group(field)
      field["short"] ? :lists : :texts
    end

    def summary_group(field)
      field["short"] ? :facts : :texts
    end

    def describes_character?(_field)
      true
    end

    def error_for(value, _field, **)
      return [:invalid] unless value.is_a?(String)

      [:too_long, { count: MAX_LENGTH }] if value.length > MAX_LENGTH
    end
  end
end
