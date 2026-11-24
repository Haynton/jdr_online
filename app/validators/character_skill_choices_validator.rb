# Checks the skills ticked on a character being made when its table limits them (GameTable#limit_skill_choices):
# no more than the options picked offer (the class: 3 for a ranger), and only among those they offer, the skills
# another option gives staying ticked (the background). Only on the step that asks the skills, while the character is
# made (Character#checks_skill_choices). Errors go on each skill refused, so that a draft saved in the background keeps
# its skills from before (Character#save_draft_step)
class CharacterSkillChoicesValidator < ActiveModel::Validator
  def validate(character)
    return unless checked?(character)

    choices = character.skill_choices
    return unless choices.offered?

    add_not_offered_errors(character, choices)
    add_too_many_errors(character, choices)
  end

  private

  def checked?(character)
    character.checks_skill_choices && character.pc? && character.draft? && character.game_table&.limit_skill_choices
  end

  def add_not_offered_errors(character, choices)
    labels = character.sheet_fields.to_h { |field| [field["key"], field["label"]] }
    choices.not_offered_keys.each do |key|
      character.errors.add(:"sheet.#{key}", :skill_not_offered, skill: labels[key])
    end
  end

  def add_too_many_errors(character, choices)
    return unless choices.too_many?

    choices.chosen_keys.each do |key|
      character.errors.add(:"sheet.#{key}", :too_many_skills, count: choices.allowed_count)
    end
  end
end
