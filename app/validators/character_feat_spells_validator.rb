# Checks the origin feats of a player's character at its creation (decision of 27 November): the spells the origin feat
# of its background gives (Magic Initiate: a list the feat offers, an ability among its own, as many cantrips and level
# 1 spells as it gives, none it knows elsewhere, CharacterSheets::FeatSpells), and the feat its species lets pick (the
# human: one offered, with its skills and spells). On the step that asks them (each its own: checks_feat_spells,
# checks_species_feat) and when the character is done (a draft may wait); the spells of these feats are picked at the
# Spells step (checks_feat_spell_picks, CharacterFeatSpellPicks): the page of a feat checks its list and its ability,
# the Spells step its spells. The feats of the levels it starts above (CharacterLevelFeats), on their own step
# (checks_level_feats); a feat taken at a level gained is checked by LevelUp. An error on feats
class CharacterFeatSpellsValidator < ActiveModel::Validator
  # What the Spells step checks of a feat; the page of the feat checks the rest
  PICK_ERRORS = %i[cantrips spell spell_known].freeze
  # Which steps are checked now (a validator is shared: nothing kept on it)
  Steps = Data.define(:feat, :spells, :species, :levels)

  def validate(character)
    return unless character.pc?

    steps = steps_of(character)
    check_background_feat(character, steps) if steps.feat || steps.spells
    check_level_feats(character) if steps.levels
    return check_species_feat(character, steps) if steps.species

    check_species_feat_spells(character, steps) if steps.spells
    check_level_feat_spells(character, steps) if steps.spells
  end

  private

  def steps_of(character)
    completing = character.complete? && character.status_changed?
    Steps.new(feat: character.checks_feat_spells || completing, spells: character.checks_feat_spell_picks || completing,
              species: character.checks_species_feat || completing, levels: character.checks_level_feats || completing)
  end

  def check_background_feat(character, steps)
    given = character.origin_feat_spells
    return unless given

    spells = character.feat_spells
    known = spells.known_elsewhere(except: CharacterFeats::BACKGROUND_SOURCE)
    picks = character.origin_feat_picks
    errors = spells.errors_for(picks, given[:settings], known: known, partial: character.saving_draft)
    add_errors(character, errors, steps, feat_step: steps.feat)
  end

  # The feat the species lets pick (the human): one of those offered, its skills, its spells
  def check_species_feat(character, steps)
    return unless character.feat_choice_settings

    entry = character.species_feat_entry
    feat = character.species_feat_offers.find { |offered| offered.key == entry["key"] }
    return character.errors.add(:feats, :species_feat) unless feat

    check_feat_skills(character, feat, entry)
    check_species_feat_spells(character, steps)
  end

  # In a list no other feat took, none of them a spell it knows elsewhere
  def check_species_feat_spells(character, steps)
    entry = character.species_feat_entry
    settings = character.feat_list.find(entry["key"].to_s)&.effects&.dig("spell_picks")
    return unless settings

    source = CharacterFeats::SPECIES_SOURCE
    spells = character.feat_spells
    errors = spells.errors_for(entry, spells.open_settings(settings, source: source),
                               known: spells.known_elsewhere(except: source), partial: character.saving_draft)
    add_errors(character, errors, steps, feat_step: steps.species)
  end

  # The spells of the feats of the levels it starts above, at the Spells step: their list and ability are checked on
  # their own step (CreationFeat)
  def check_level_feat_spells(character, steps)
    spells = character.feat_spells
    character.feat_spell_decks.each do |deck|
      next unless deck.picks["source"].nil?

      errors = spells.errors_for(deck.picks, spells.open_settings(deck.settings, source: deck.source),
                                 known: spells.known_elsewhere(except: deck.source), partial: character.saving_draft)
      add_errors(character, errors, steps, feat_step: false)
    end
  end

  # The errors of the step that asks them: the page of the feat, the Spells step, or both once the character is done
  def add_errors(character, errors, steps, feat_step:)
    errors.each do |error|
      wanted = PICK_ERRORS.include?(error) ? steps.spells : feat_step
      character.errors.add(:feats, error) if wanted
    end
  end

  # As many skills as the feat gives, and only skills: a key of another bonus field (a saving throw) sent by hand is
  # refused, as at a level gained (LevelUpFeat#feat_skills_picked)
  def check_feat_skills(character, feat, entry)
    count = feat.effects.dig("skill_picks", "count").to_i
    skills = Array(entry["skills"])
    return if count.zero? || (skills.size == count && (skills - character.skill_choices.skill_keys).empty?)

    character.errors.add(:feats, :skills, count: count)
  end

  # The feats of the levels it starts above (CreationFeat: its points shared, its skills and spells picked), while it is
  # being made: once done, a feat of a level comes from a level gained (LevelUp)
  def check_level_feats(character)
    return unless character.draft? || character.status_changed?

    character.level_feat_errors.each do |level, message|
      character.errors.add(:feats, :level_feat, level: level, detail: message)
    end
  end

  # On the step that asks them (asked_here), or when the character is done
  def checked?(character, asked_here)
    asked_here || (character.complete? && character.status_changed?)
  end
end
