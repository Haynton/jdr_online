# Checks the spells of a player character against what its class and level offer (CharacterSheets::SpellChoices): only
# spells offered, and no more spells in a group (cantrips, prepared spells) than allowed. The browser counts them as an
# aid; the server decides. The spells always prepared (copied by the server, from the subclass) and those of a feat
# (Magic Initiate) count in no group, and a spell is never known twice. A wizard prepares among the spells of its book.
# Errors go on spells, shown at the top of the Spells step
class CharacterSpellsValidator < ActiveModel::Validator
  def validate(character)
    return unless checked?(character)

    choices = character.spell_choices
    refused = character.spells.reject { |spell| given?(spell) || choices.group_of(spell["key"]) }
    character.errors.add(:spells, :spell_not_offered, count: refused.size) if refused.any?
    choices.groups.each { |group| validate_group_size(character, group) }
    validate_known_once(character)
    validate_spellbook(character)
  end

  private

  def checked?(character)
    character.pc? && character.game_table && (character.spells.present? || character.spellbook.present?)
  end

  # Copied by the server, never picked in a group: always prepared by an option, or given by a feat
  def given?(spell)
    spell["always_prepared"] || spell[CharacterSheets::FeatSpells::MARK]
  end

  # The spells written in the book of a wizard, and those prepared among them (CharacterSheets::Spellbook)
  def validate_spellbook(character)
    book = character.spellbook_of_class
    return unless book.any?

    book.errors.each { |type, options| character.errors.add(:spells, type, **options) }
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
