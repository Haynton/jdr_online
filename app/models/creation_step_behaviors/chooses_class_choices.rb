module CreationStepBehaviors
  # The step offers the groups of choices of the class at the level of the character (CharacterSheets::ClassChoices:
  # invocations, metamagic...), and keeps those picked (decision of 27 November: at the step of the skills)
  class ChoosesClassChoices < Base
    KEY = "chooses_class_choices".freeze

    def form_partial
      "game_tables/character_steps/class_choices"
    end

    # Nothing in the block of its step: the options picked are with the features of the sheet, each with its summary
    # (CharacterSheets::Features, character_sheets/summary/_features)
    def summary_partial; end

    def fill(character, class_choices: nil, **)
      character.choose_class_choices(class_choices)
    end

    # A class changed on another step drops the groups it no longer gives
    def keep_offered(character)
      character.keep_offered_class_choices
    end
  end
end
