# Checks the spells of a player character against what its class and level offer (SpellChoices): only spells offered,
# and no more cantrips or prepared spells than allowed. The browser counts them as an aid; the server decides.
# Errors go on spells, shown at the top of the Spells step
class CharacterSpellsValidator < ActiveModel::Validator
  def validate(character)
    return unless character.pc? && character.game_table && character.spells.present?

    choices = character.spell_choices
    refused = character.spells.reject { |spell| choices.group_of(spell["key"]) }
    character.errors.add(:spells, :spell_not_offered, count: refused.size) if refused.any?
    choices.groups.each { |group| validate_group_size(character, group) }
  end

  private

  def validate_group_size(character, group)
    chosen_count = character.spells.count { |spell| group.keys.include?(spell["key"]) }
    return if chosen_count <= group.allowed_count

    character.errors.add(:spells, :"too_many_#{group.kind}", count: group.allowed_count)
  end
end
