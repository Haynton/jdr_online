# The skills a character picks, and their check when the table limits them to what the class offers
# (GameTable#limit_skill_choices, step Settings): only on the step that asks the skills (CharacterSkillChoicesValidator)
module CharacterSkillChoices
  extend ActiveSupport::Concern

  included do
    # Set by a step that asks the skills (fill_step): only there are they checked, so that a class changed on another
    # step never stops that step
    attr_accessor :checks_skill_choices

    validates_with CharacterSkillChoicesValidator
  end

  def skill_choices
    CharacterSheets::SkillChoices.new(fields: sheet_fields, sheet: sheet)
  end
end
