module FieldTypes
  # The starting equipment picked among the options of the list named in from (its starting_equipment effect: the
  # class, the background): { "option" => "a", "picks" => { "2" => "lute" } }. Drawn by the Equipment step, listed on
  # the summary by its own block; its check reads the option picked in the list (CharacterSheets::StartingEquipment)
  class EquipmentOption < Base
    KEY = "equipment_option".freeze
    OWN_PARAMETERS = %w[from].freeze

    def partial
      nil
    end

    def summary_group(_field)
      nil
    end

    # Its picks alone mean nothing: without an option picked, it is blank
    def blank?(typed_value)
      typed_value.to_h.stringify_keys["option"].blank?
    end

    # The option picked (a, b, c) and the items of your choice of that option only (the lists of every option are
    # sent: picks[a][2]), those not picked left out
    def convert(typed_value, _field)
      value = typed_value.to_h.stringify_keys
      option = value["option"].to_s
      picks = value["picks"].to_h.stringify_keys[option].to_h.stringify_keys.compact_blank
      { "option" => option, "picks" => picks }
    end

    def error_for(value, field, character:)
      CharacterSheets::StartingEquipment.new(character).error_for(field, value)
    end
  end
end
