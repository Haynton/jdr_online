module FieldTypes
  # One option of a list. Its options may have a description (described_choices) and effects on the sheet
  # (SheetTemplate::CHOICE_EFFECTS)
  class Choice < Base
    KEY = "choice".freeze
    OWN_PARAMETERS = %w[options descriptions effects].freeze
    REQUIRED_PARAMETERS = %w[options].freeze

    def flow_group(_field)
      :lists
    end

    def error_for(value, field, **)
      [:inclusion] unless field["options"].include?(value)
    end
  end
end
