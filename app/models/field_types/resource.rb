module FieldTypes
  # A resource: its current value and its maximum ("PV 8 / 12"), in a box. At creation the player gives the maximum,
  # and the character starts full
  class Resource < Base
    KEY = "resource".freeze
    OWN_PARAMETERS = %w[max initial_from receives_damage absorbs_damage_for].freeze

    def partial
      "character_sheets/fields/stat"
    end

    def boxed?
      true
    end

    def summary_group(_field)
      :boxes
    end

    def convert(typed_value, _field)
      maximum = Integer(typed_value.to_s.strip, 10, exception: false)
      maximum ? { "current" => maximum, "max" => maximum } : typed_value
    end

    def error_for(value, _field, **)
      return [:not_an_integer] unless value.is_a?(Hash) && value.values_at("current", "max").all?(Integer)
      return [:greater_than_or_equal_to, { count: 0 }] if value["max"].negative?

      [:invalid] unless value["current"].between?(0, value["max"])
    end

    # Read by its maximum
    def summary_text(value, _field)
      value.is_a?(Hash) ? ActiveSupport::NumberHelper.number_to_delimited(value["max"]) : nil
    end

    def initial_value(value)
      { "current" => value, "max" => value }
    end

    def fixed_hint
      "game_tables.characters.new.resource_hint"
    end
  end
end
