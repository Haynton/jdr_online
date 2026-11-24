# The spell slots shown on the Spells step and the summary (character_sheets/summary/_spell_slots)
module CharacterSheets
  module CharacterSheets::SpellSlotsHelper
    # The spell slots of the character at its level, by its class (CharacterSheets::SpellSlots), nil without
    def character_spell_slots(character)
      CharacterSheets::SpellSlots.new(character).call
    end
  end
end
