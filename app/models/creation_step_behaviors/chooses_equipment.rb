module CreationStepBehaviors
  # The step offers the starting equipment of the class and the background (CharacterSheets::StartingEquipment). The
  # choices are fields of the sheet (equipment_option), saved with the others: on its own step, what was sent is
  # checked (CharacterSheetValidator), never dropped without a word
  class ChoosesEquipment < Base
    KEY = "chooses_equipment".freeze

    def form_partial
      "game_tables/character_steps/equipment_choices"
    end

    def summary_partial
      "character_sheets/summary/equipment"
    end

    # A class changed on another step drops an equipment choice it does not offer
    def keep_offered(character)
      character.sheet = CharacterSheets::StartingEquipment.new(character).keep_offered(character.sheet)
    end
  end
end
