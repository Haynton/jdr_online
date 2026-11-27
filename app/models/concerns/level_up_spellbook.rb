# The spells a wizard writes in its spellbook at a level gained (decision of 27 November, SRD 5.2.1: « Whenever you gain
# a Wizard level after 1, add two Wizard spells of your choice to your spellbook », of a level for which it has spell
# slots): as many as its class says (per_level), among the spells of the group it prepares from at its new level, not
# written yet nor known otherwise. Part of LevelUp; LevelUpApplier writes them
module LevelUpSpellbook
  extend ActiveSupport::Concern

  included do
    attr_reader :spellbook_keys

    validate :spellbook_keys_picked, if: :spellbook_additions?
  end

  def spellbook_keys=(keys)
    @spellbook_keys = Array(keys).compact_blank.uniq
  end

  # Its spellbook at the new level (CharacterSheets::Spellbook)
  def new_spellbook
    @new_spellbook ||= future_character.spellbook_of_class
  end

  def spellbook_additions?
    new_spellbook.any? && spellbook_count.positive?
  end

  def spellbook_count
    new_spellbook.settings["per_level"].to_i
  end

  # The spells it may write: those of its levels with spell slots, not in its book yet nor known otherwise
  def spellbook_candidates
    known = character.feat_spells.known_elsewhere.keys
    new_spellbook.group.spells.reject { |spell| new_spellbook.include?(spell.key) || known.include?(spell.key) }
  end

  # The copies of the spells written at this level
  def spellbook_additions
    spellbook_additions? ? new_spellbook.copies_of(spellbook_keys) : []
  end

  private

  def spellbook_keys_picked
    allowed = spellbook_candidates.map(&:key)
    return if Array(spellbook_keys).size == spellbook_count && (Array(spellbook_keys) - allowed).empty?

    errors.add(:spellbook_keys, :not_picked, count: spellbook_count, label: new_spellbook.label)
  end
end
