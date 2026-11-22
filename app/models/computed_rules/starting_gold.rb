module ComputedRules
  # The gold of the starting equipment options picked (equipment_option fields, CharacterSheets::StartingEquipment), a
  # plain number. Its field is internal (shown nowhere): it fills the gold of the sheet once the character is complete,
  # so the page never works it out (no JavaScript twin)
  class StartingGold < Base
    KEY = "starting_gold".freeze
    LIVE = false

    def value(_field, reader)
      CharacterSheets::StartingEquipment.gold_from(fields: reader.fields, sheet: reader.sheet)&.to_s
    end
  end
end
