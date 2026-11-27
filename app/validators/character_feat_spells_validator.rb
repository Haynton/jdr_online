# Checks the origin feats of a player's character at its creation (decision of 27 November): the spells the origin feat
# of its background gives (Magic Initiate: a list the feat offers, an ability among its own, as many cantrips and level
# 1 spells as it gives, CharacterSheets::FeatSpells), and the feat its species lets pick (the human: one offered, with
# its skills and spells). On the step that asks them and when the character is done (a draft may wait); a feat taken
# at a level gained is checked by LevelUp. An error on feats
class CharacterFeatSpellsValidator < ActiveModel::Validator
  def validate(character)
    return unless character.pc? && checked?(character)

    check_background_feat(character)
    check_species_feat(character)
  end

  private

  def check_background_feat(character)
    given = character.origin_feat_spells
    return unless given

    errors = character.feat_spells.errors_for(character.origin_feat_picks, given[:settings])
    errors.each { |error| character.errors.add(:feats, error) }
  end

  # The feat the species lets pick (the human): one of those offered, its skills, its spells
  def check_species_feat(character)
    return unless character.feat_choice_settings

    entry = character.species_feat_entry
    feat = character.species_feat_offers.find { |offered| offered.key == entry["key"] }
    return character.errors.add(:feats, :species_feat) unless feat

    check_feat_skills(character, feat, entry)
    settings = feat.effects["spell_picks"]
    character.feat_spells.errors_for(entry, settings).each { |error| character.errors.add(:feats, error) } if settings
  end

  def check_feat_skills(character, feat, entry)
    count = feat.effects.dig("skill_picks", "count").to_i
    return if count.zero? || Array(entry["skills"]).size == count

    character.errors.add(:feats, :skills, count: count)
  end

  def checked?(character)
    character.checks_feat_spells || (character.complete? && character.status_changed?)
  end
end
