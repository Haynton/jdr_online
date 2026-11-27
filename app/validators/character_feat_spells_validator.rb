# Checks the origin feats of a player's character at its creation (decision of 27 November): the spells the origin feat
# of its background gives (Magic Initiate: a list the feat offers, an ability among its own, as many cantrips and level
# 1 spells as it gives, none it knows elsewhere, CharacterSheets::FeatSpells), and the feat its species lets pick (the
# human: one offered, with its skills and spells). On the step that asks them and when the character is done (a draft
# may wait); a feat taken at a level gained is checked by LevelUp. An error on feats
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

    spells = character.feat_spells
    known = spells.known_elsewhere(except: CharacterFeats::BACKGROUND_SOURCE)
    errors = spells.errors_for(character.origin_feat_picks, given[:settings], known: known)
    errors.each { |error| character.errors.add(:feats, error) }
  end

  # The feat the species lets pick (the human): one of those offered, its skills, its spells
  def check_species_feat(character)
    return unless character.feat_choice_settings

    entry = character.species_feat_entry
    feat = character.species_feat_offers.find { |offered| offered.key == entry["key"] }
    return character.errors.add(:feats, :species_feat) unless feat

    check_feat_skills(character, feat, entry)
    check_species_feat_spells(character, feat, entry)
  end

  # In a list no other feat took, none of them a spell it knows elsewhere
  def check_species_feat_spells(character, feat, entry)
    settings = feat.effects["spell_picks"]
    return unless settings

    source = CharacterFeats::SPECIES_SOURCE
    spells = character.feat_spells
    errors = spells.errors_for(entry, spells.open_settings(settings, source: source),
                               known: spells.known_elsewhere(except: source))
    errors.each { |error| character.errors.add(:feats, error) }
  end

  # As many skills as the feat gives, and only skills: a key of another bonus field (a saving throw) sent by hand is
  # refused, as at a level gained (LevelUpFeat#feat_skills_picked)
  def check_feat_skills(character, feat, entry)
    count = feat.effects.dig("skill_picks", "count").to_i
    skills = Array(entry["skills"])
    return if count.zero? || (skills.size == count && (skills - character.skill_choices.skill_keys).empty?)

    character.errors.add(:feats, :skills, count: count)
  end

  def checked?(character)
    character.checks_feat_spells || (character.complete? && character.status_changed?)
  end
end
