module CreationStepBehaviors
  # The step offers the spells of the class at the level of the character (CharacterSheets::SpellChoices), and copies
  # those ticked into the character
  class ChoosesSpells < Base
    KEY = "chooses_spells".freeze

    def form_partial
      "game_tables/character_steps/spell_choices"
    end

    def summary_partial
      "character_sheets/summary/spells"
    end

    def fill(character, spell_keys: nil, spellbook_keys: nil, **)
      character.choose_spellbook(spellbook_keys)
      character.choose_spells(spell_keys)
    end

    # A class changed on another step drops the spells it does not offer, and the spellbook of a class without one
    def keep_offered(character)
      character.spells = character.spell_choices.keep_offered(character.spells)
      character.keep_offered_spellbook
    end
  end
end
