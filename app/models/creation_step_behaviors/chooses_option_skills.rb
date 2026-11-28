module CreationStepBehaviors
  # The step asks the skills an option of a list that depends on another offers to pick (CharacterOptionSkills: the
  # College of Lore of the bard), on a step of its own after the skills of the class (decision of 28 November). Shown
  # when such a list, asked at this level, has an option picked that offers some. The skills show on the sheet of the
  # summary, ticked, as the others
  class ChoosesOptionSkills < Base
    KEY = "chooses_option_skills".freeze

    def form_partial
      "game_tables/character_steps/option_skills"
    end

    def summary_partial
      nil
    end

    def shown?(game_table, _picked_effects, sheet = {})
      game_table.character_sheet_fields.any? do |field|
        field["options_from"] && field.dig("effects", sheet.to_h[field["key"]].to_s, "skill_choices") &&
          FieldTypes.of(field).asked_on?(field, sheet.to_h)
      end
    end

    def fill(character, option_skills: nil, **)
      character.checks_option_skills = true
      character.choose_option_skills(option_skills)
    end

    # A class, a subclass or a level changed on another step drops the skills it no longer offers
    def keep_offered(character)
      character.keep_offered_option_skills
    end
  end
end
