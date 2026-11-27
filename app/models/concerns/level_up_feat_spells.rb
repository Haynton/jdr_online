# The spells of a feat taken at a level gained (Magic Initiate, decision of 27 November): one card per list
# (CharacterSheets::FeatCards), the lists its other feats took left out, and spells it knows already refused. Part of
# LevelUpFeat
module LevelUpFeatSpells
  extend ActiveSupport::Concern

  included do
    validate :feat_spells_picked, if: -> { feat_level? && spell_settings }
  end

  # The spells picked for a feat that gives some (Magic Initiate): its list, and what was picked in that list only
  # (the blocks of the other lists, sent without JavaScript, are left out)
  def feat_spells=(picks)
    @feat_spells_sent = picks
  end

  def feat_spell_picks
    CharacterSheets::FeatSpells.picks_from(@feat_spells_sent, list: CharacterSheets::FeatCards.split(feat_key).last)
  end

  # The feats it may take as cards, one per list for a feat that gives spells
  def feat_cards
    CharacterSheets::FeatCards.new(character, source: feat_source).cards(offered_feats)
  end

  # What a feat gives to pick in spells ({ "lists", "cantrips", "level_one", "abilities" }), only the lists no feat it
  # took has, nil for none
  def spell_settings(for_feat = feat)
    settings = for_feat&.effects&.dig("spell_picks")
    settings && character.feat_spells.open_settings(settings, source: feat_source)
  end

  # The spells it knows already, never picked again for the feat ({ key => where it comes from })
  def known_spells
    @known_spells ||= character.feat_spells.known_elsewhere(except: feat_source)
  end

  def feat_source
    CharacterSheets::FeatSpells.source_of("level" => level)
  end

  private

  def feat_spells_picked
    errors_found = character.feat_spells.errors_for(feat_spell_picks.to_h, spell_settings, known: known_spells)
    errors_found.each { |error| errors.add(:feat_spells, error) }
  end
end
