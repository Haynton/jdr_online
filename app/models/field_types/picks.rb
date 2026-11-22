module FieldTypes
  # Several options of a list (the languages), count at most, stored as an array; granted: options always known,
  # shown and never stored (the Common tongue)
  class Picks < Base
    KEY = "picks".freeze
    OWN_PARAMETERS = %w[options count granted].freeze

    def partial
      "character_sheets/fields/picks"
    end

    def flow_group(_field)
      :picks
    end

    # The check boxes of the options picked; the hidden field before them sends "" so that none picked is a value too
    def convert(typed_value, _field)
      Array(typed_value).compact_blank.map(&:to_s)
    end

    def error_for(value, field, **)
      return [:inclusion] unless value.is_a?(Array) && (value - field["options"].to_a).empty?

      [:too_many_picks, { count: field["count"] }] if field["count"] && value.size > field["count"]
    end

    # The options always known, then those picked: "Commun et Elfique"
    def summary_text(value, field)
      (field["granted"].to_a + Array(value)).to_sentence
    end
  end
end
