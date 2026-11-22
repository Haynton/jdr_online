module FieldTypes
  # A value worked out from the others by one of SheetTemplate::COMPUTED_RULES, in a box: never stored, never typed
  class Computed < Base
    KEY = "computed".freeze
    OWN_PARAMETERS = %w[rule based_on level_from class_from proficiency internal summary_only].freeze

    def partial
      "character_sheets/fields/stat"
    end

    def boxed?
      true
    end

    def summary_group(_field)
      :boxes
    end

    def stored?
      false
    end
  end
end
