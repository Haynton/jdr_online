module FieldTypes
  # What a field type may say about itself, with the behavior of most types. A type changes only what differs.
  # The unknown type (a key the registry does not know) is this class itself: it refuses any value
  class Base
    # The settings every field may have; a type adds its own (OWN_PARAMETERS). The template editor will ask them, and
    # the validator of the template refuses any other (SheetTemplateValidator: a typo like maxx never passes)
    COMMON_PARAMETERS = %w[
      key label type section help required at_creation visible_to_others abbreviation summary_only internal column
    ].freeze
    OWN_PARAMETERS = [].freeze
    # The settings without which the type does not work
    REQUIRED_PARAMETERS = [].freeze
    # The settings that name another field of the same sheet, and the type that field must have
    REFERENCES = {}.freeze
    KEY = nil

    def key
      self.class::KEY
    end

    def parameters
      COMMON_PARAMETERS + self.class::OWN_PARAMETERS
    end

    def required_parameters
      self.class::REQUIRED_PARAMETERS
    end

    # { "based_on" => "ability" }: based_on must name a field of type ability
    def references
      self.class::REFERENCES
    end

    # Its look on a step (character_sheets/fields), nil when a section or a step draws it itself
    def partial
      "character_sheets/fields/input"
    end

    # Its group in a free layout (CharacterSheets::LayoutHelper::FLOW_GROUPS)
    def flow_group(_field)
      :boxes
    end

    # A box keeps its help out of it: the help goes under the row of its section, as a note
    def boxed?
      false
    end

    # Its group on the summary sheet (CharacterSheets::SummaryHelper::SUMMARY_GROUPS), nil when it is not shown there
    def summary_group(_field)
      :facts
    end

    # A computed value is worked out every time, never stored
    def stored?
      true
    end

    # A check box sends a value when unticked too: it is kept even blank
    def kept_when_blank?
      false
    end

    # Nothing typed: the field is left out of the sheet
    def blank?(typed_value)
      typed_value.blank? && !kept_when_blank?
    end

    # What the form sent (always text) to the value of the sheet. A value that cannot be converted is kept as typed,
    # so that the check refuses it and the form shows it again under its error
    def convert(typed_value, _field)
      typed_value.to_s.strip
    end

    # nil when the value fits its field, otherwise the type of the error and its options ([:too_long, { count: 2000 }]).
    # The callers pass character: (the character whose sheet it is; none for a catalog entry): a type that reads the
    # other values of the sheet names it (the bonus of the background, the equipment), the others ignore it (**)
    def error_for(_value, _field, **)
      [:invalid]
    end

    # The value as read on the summary sheet
    def summary_text(value, _field)
      value
    end

    # The value it starts the game with, from what was worked out at creation (initial_from)
    def initial_value(value)
      value
    end

    # The lowest value of its field of input
    def minimum(_field)
      0
    end

    # A help of its own, said whatever the template (a translation key), nil for the help of the template
    def fixed_hint
      nil
    end
  end
end
