module FieldTypes
  # A yes-or-no value: a switch on its own line. The check box sends "1" when checked, the hidden field before it "0":
  # unchecked is a value too
  class Boolean < Base
    KEY = "boolean".freeze

    def partial
      "character_sheets/fields/switch"
    end

    def flow_group(_field)
      :switches
    end

    def kept_when_blank?
      true
    end

    # A conversion, not a question: it turns the "1" or "0" sent by the check box into true or false
    def convert(typed_value, _field) # rubocop:disable Naming/PredicateMethod
      typed_value == "1"
    end

    def error_for(value, _field, **)
      [:inclusion] unless [true, false].include?(value)
    end

    def summary_text(value, _field)
      I18n.t(value ? "answer_yes" : "answer_no", scope: "game_tables.character_steps.summary")
    end
  end
end
