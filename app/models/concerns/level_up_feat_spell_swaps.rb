# The spell of a feat changed at a level gained (decision of 27 November, SRD 5.2.1, Magic Initiate: « whenever you gain
# a new level, you can replace one of the spells you chose for this feat with a different spell of the same level from
# the chosen spell list »): for each feat taken that gave spells, one of them may be replaced, never by a spell the
# character knows already. Optional: nothing picked keeps the spells. Part of LevelUp; LevelUpApplier writes the change
module LevelUpFeatSpellSwaps
  extend ActiveSupport::Concern

  # A feat whose spells may change: where it comes from, its entry (characters.feats), the spells its list offers
  Swappable = Data.define(:source, :label, :entry, :offer) do
    def spell_keys
      (Array(entry["cantrips"]) + Array(entry["spell"])).compact_blank
    end

    # The spells of the feat, by name (the list to pick the one to replace from)
    def spells
      (offer.cantrips + offer.spells).select { |spell| spell_keys.include?(spell.key) }
    end

    # The spells of the same level as the one it replaces: a cantrip for a cantrip, a level 1 spell for a level 1 one
    def same_level_as(spell_key)
      Array(entry["cantrips"]).include?(spell_key) ? offer.cantrips : offer.spells
    end
  end

  included do
    attr_reader :feat_spell_swaps

    validate :feat_spell_swaps_allowed
  end

  # { source => { "from" => key, "to" => key } }, only the feats where a spell to replace was picked
  def feat_spell_swaps=(swaps)
    @feat_spell_swaps = swaps.to_h.to_h { |source, swap| [source.to_s, swap.to_h.stringify_keys.slice("from", "to")] }
                             .select { |_source, swap| swap["from"].present? }
  end

  def swappable_feats
    @swappable_feats ||= character.feat_list.taken_entries.filter_map do |entry|
      next if entry["spell_list"].blank?

      Swappable.new(source: CharacterSheets::FeatSpells.source_of(entry), label: character.feat_entry_label(entry),
                    entry: entry, offer: character.feat_spells.offer(entry["spell_list"]))
    end
  end

  # The spells of the feats taken, with the swaps made (characters.feats)
  def feats_with_swaps
    Array(character.feats).map do |entry|
      swap = feat_spell_swaps.to_h[CharacterSheets::FeatSpells.source_of(entry)]
      swap ? swapped_entry(entry, swap) : entry
    end
  end

  private

  def swapped_entry(entry, swap)
    replace = ->(keys) { keys.map { |key| key == swap["from"] ? swap["to"] : key } }
    entry.merge("cantrips" => replace.call(Array(entry["cantrips"])), "spell" => replace.call([entry["spell"]]).first)
         .compact
  end

  # The spell replaced is one of the feat's, the new one of the same level in its list, not known yet
  def feat_spell_swaps_allowed
    known = character.feat_spells.known_elsewhere
    feat_spell_swaps.to_h.each do |source, swap|
      feat = swappable_feats.find { |swappable| swappable.source == source }
      next if feat && swap_allowed?(feat, swap, known)

      errors.add(:feat_spell_swaps, :not_allowed)
    end
  end

  def swap_allowed?(feat, swap, known)
    feat.spell_keys.include?(swap["from"]) && feat.same_level_as(swap["from"]).map(&:key).include?(swap["to"]) &&
      known.exclude?(swap["to"])
  end
end
