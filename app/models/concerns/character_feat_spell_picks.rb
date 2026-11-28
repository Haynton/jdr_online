# The spells of the feats of its origin, picked at the Spells step (decision of 28 November, Anthony's request): the
# page of the feats only takes the feat, its list and the ability to cast them; the spells come with those of its class,
# one row of cards per feat (Magic Initiate of the background, of the species). They stay while the feat and its list
# stay, and go with them. The feats of the levels it starts above keep their spells on their page (CreationFeat)
module CharacterFeatSpellPicks
  extend ActiveSupport::Concern

  PICKED_KEYS = %w[cantrips spell].freeze
  # The feats whose spells are picked at the Spells step: those of the background and of the species
  PICKED_AT_SPELLS = %w[background species].freeze

  # A feat with spells to pick: where it comes from (background, species), the feat, its list, its settings (how many
  # cantrips, level 1 spells), what was picked
  Deck = Data.define(:source, :feat, :list, :settings, :picks)

  included do
    # Set by the Spells step: the spells of the feats are checked there (CharacterFeatSpellsValidator)
    attr_accessor :checks_feat_spell_picks
  end

  # Whether one of its feats has spells to pick at the Spells step (the step shows even for a class without spells)
  def self.feat_spells_to_pick?(feats)
    Array(feats).any? { |entry| PICKED_AT_SPELLS.include?(entry["source"]) && entry["spell_list"].present? }
  end

  def feat_spell_decks
    Array(feats).filter_map do |entry|
      next unless PICKED_AT_SPELLS.include?(entry["source"]) && entry["spell_list"].present?

      feat = feat_list.find(entry["key"])
      settings = feat&.effects&.dig("spell_picks")
      next unless settings

      Deck.new(source: entry["source"], feat: feat, list: entry["spell_list"], settings: settings, picks: entry)
    end
  end

  # What the Spells step sent: { "background" => { "cantrips" => [...], "spell" => "..." }, "species" => { ... } }
  def choose_feat_spell_picks(picks)
    picks = picks.to_h.stringify_keys
    self.feats = Array(feats).map do |entry|
      sent = picks[entry["source"]]
      next entry unless sent && entry["spell_list"].present?

      entry.except(*PICKED_KEYS).merge(picked_feat_spells(sent))
    end
    sync_feat_spells
  end

  # Its spells: those it picked for its class, then a copy of those of its feats
  def sync_feat_spells
    self.spells = spells.to_a.reject { |spell| spell[CharacterSheets::FeatSpells::MARK] } + feat_spells.copies
  end

  private

  # What a page of the feats sent, with the spells picked before when the feat and its list are the same
  def with_kept_spell_picks(entry, previous)
    return entry unless previous["key"] == entry["key"] && previous["spell_list"] == entry["spell_list"]

    entry.reverse_merge(previous.slice(*PICKED_KEYS))
  end

  def picked_feat_spells(sent)
    sent = sent.to_h.stringify_keys
    { "cantrips" => Array(sent["cantrips"]).compact_blank.uniq, "spell" => Array(sent["spell"]).compact_blank.first }
      .compact_blank
  end
end
