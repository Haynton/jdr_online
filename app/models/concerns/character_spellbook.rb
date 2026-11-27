# The spells of a player's character: those it chose (characters.spells), and the spellbook of a class that has one
# (decision of 27 November, SRD 5.2.1: the wizard): the level 1+ spells it knows, copied (characters.spellbook), among
# which its spells are prepared (CharacterSheets::Spellbook)
module CharacterSpellbook
  extend ActiveSupport::Concern

  # The spells this character may choose: its class, its level (CharacterSheets::SpellChoices)
  def spell_choices
    CharacterSheets::SpellChoices.new(self)
  end

  # A copy of each spell chosen (decision: the catalog changing never changes a character), and of those its options
  # always prepare and its feats give. A key not offered stays as a bare key, refused by CharacterSpellsValidator
  def choose_spells(spell_keys)
    choices = spell_choices
    chosen_spells = spell_keys.to_a.compact_blank.uniq.map do |spell_key|
      choices.copy_of(spell_key) || { "key" => spell_key }
    end
    self.spells = chosen_spells + choices.always_prepared.copies + feat_spells.copies
  end

  def spellbook_of_class
    CharacterSheets::Spellbook.new(self)
  end

  # The spells written in its spellbook, for a class that has one (a copy of each); nothing for another class
  def choose_spellbook(spellbook_keys)
    book = spellbook_of_class
    self.spellbook = book.any? ? book.copies_of(spellbook_keys) : []
  end

  # A class changed drops the spells its book can no longer hold, and the whole book of a class without one
  def keep_offered_spellbook
    book = spellbook_of_class
    self.spellbook = book.any? ? spellbook.select { |spell| book.group.keys.include?(spell["key"]) } : []
  end
end
