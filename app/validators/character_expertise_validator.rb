# Checks the expertise ticked on a character being made (decision of 26 November): no more than its class gives at its
# level, and only on a skill it may give expertise to (CharacterSheets::ExpertiseChoices). Only on the step that asks
# the skills, while the character is made (Character#checks_skill_choices), as the skills themselves. Errors go on each
# skill refused, so that a draft saved in the background keeps its expertise from before (Character#save_draft_step)
class CharacterExpertiseValidator < ActiveModel::Validator
  def validate(character)
    return unless character.checks_skill_choices && character.pc? && character.draft?

    choices = CharacterSheets::ExpertiseChoices.new(character)
    picked = choices.picked_keys(character.skill_choices.skill_keys)
    labels = character.sheet_fields.to_h { |field| [field["key"], field["label"]] }
    picked.reject { |key| choices.offered?(key) }.each do |key|
      character.errors.add(:"sheet.#{key}", :expertise_not_offered, skill: labels[key])
    end
    add_too_many_errors(character, picked, choices.allowed_count)
  end

  private

  def add_too_many_errors(character, picked, allowed_count)
    return if picked.size <= allowed_count

    picked.each { |key| character.errors.add(:"sheet.#{key}", :too_many_expertise, count: allowed_count) }
  end
end
