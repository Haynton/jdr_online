# The groups of choices of a class (CharacterSheets::ClassChoices) on the step of the skills, the window of a level
# gained and of the game room
module CharacterSheets
  module CharacterSheets::ClassChoicesHelper
    # What an option needs beside its summary: « Niveau 5 · Demande Pacte de la lame », nil when nothing
    def class_choice_requirements(group, option)
      parts = []
      parts << t("game_tables.character_steps.class_choices.min_level", level: option.min_level) if option.min_level > 1
      required = option.requires && group.options.find { |candidate| candidate.key == option.requires }
      parts << t("game_tables.character_steps.class_choices.requires", option: required.label) if required
      parts.join(" · ").presence
    end
  end
end
