# Checks the spells of a player character against what its class and level offer (CharacterSheets::SpellChoices): only
# spells offered, and no more spells in a group (cantrips, prepared spells) than allowed. The browser counts them as an
# aid; the server decides. The spells always prepared (copied by the server, from the subclass) and those of a feat
# (Magic Initiate) count in no group, and a spell is never known twice.
# Errors go on spells, shown at the top of the Spells step
class CharacterSpellsValidator < ActiveModel::Validator
  def validate(character)
    return unless character.pc? && character.game_table && character.spells.present?

    choices = character.spell_choices
    refused = character.spells.reject { |spell| given?(spell) || choices.group_of(spell["key"]) }
    character.errors.add(:spells, :spell_not_offered, count: refused.size) if refused.any?
    choices.groups.each { |group| validate_group_size(character, group) }
    validate_known_once(character)
  end

  private

  # Copied by the server, never picked in a group: always prepared by an option, or given by a feat
  def given?(spell)
    spell["always_prepared"] || spell[CharacterSheets::FeatSpells::MARK]
  end

  # A spell known twice (picked for its class and given by a feat) wastes a pick
  def validate_known_once(character)
    copies_by_key = character.spells.group_by { |spell| spell["key"] }.values
    copies_by_key.select { |copies| copies.size > 1 }.each do |copies|
      character.errors.add(:spells, :spell_known_twice, spell: copies.first["name"])
    end
  end

  def validate_group_size(character, group)
    chosen_count = character.spells.count do |spell|
      !spell[CharacterSheets::FeatSpells::MARK] && group.keys.include?(spell["key"])
    end
    return if chosen_count <= group.allowed_count

    character.errors.add(:spells, :too_many_spells, group: group.label, count: group.allowed_count)
  end
end
