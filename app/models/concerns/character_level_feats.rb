# The feats a player's character takes at its creation when it starts above level 1 (decision of 27 November): one per
# level of its class that improves the abilities, up to its level (level 8: those of levels 4 and 8), each picked on
# the step « Dons des niveaux » as at a level gained (CreationFeat), its spells at the Spells step. Kept in
# characters.feats like a feat taken at a level gained
# ({ "key", "level", "abilities", "skills", spells }), so that the rules read them the same way. Part of CharacterFeats
module CharacterLevelFeats
  extend ActiveSupport::Concern

  # The improvement its class declares ({ "levels", "epic_levels", "points", "max_per_ability" }), nil before a class
  def ability_score_improvement
    field = sheet_fields.find { |candidate| candidate["rule"] == ComputedRules::HitPointsByLevel::KEY }
    return unless field

    reader = CharacterSheets::SheetReader.new(fields: sheet_fields, sheet: sheet, level_thresholds: [], modifiers: {})
    reader.class_effects(field["class_from"])["ability_score_improvement"]
  end

  # The levels whose feat it takes at its creation, in order (the later ones are gained in the game room, LevelUp)
  def creation_feat_levels
    declared = ability_score_improvement.to_h
    levels = Array(declared["levels"]) + Array(declared["epic_levels"])
    levels.select { |level| level.to_i <= current_level }.map(&:to_i).uniq.sort
  end

  # One form a level, from what was kept for it
  def creation_feats
    creation_feat_levels.map { |level| CreationFeat.from_entry(self, level, level_feat_entry(level)) }
  end

  def level_feat_entry(level)
    Array(feats).find { |entry| entry["source"].nil? && entry["level"].to_i == level }
  end

  # The feats picked on the step, by level ({ "4" => { feat_key:, ability_increases: } }): what each asks, its skills
  # ticked on the sheet (those of the feat picked before unticked), its spells copied
  def choose_level_feats(params)
    params = params.to_h.stringify_keys
    previous = level_feat_entries.index_by { |entry| entry["level"].to_i }
    untick_skills(level_feat_entries.flat_map { |entry| Array(entry["skills"]) })
    self.feats = Array(feats) - level_feat_entries
    creation_feat_levels.each { |level| add_level_feat(level, params[level.to_s], previous[level].to_h) }
    tick_skills(level_feat_entries.flat_map { |entry| Array(entry["skills"]) })
    sync_feat_spells
  end

  # A class or a level changed on another step drops the feats of the levels it no longer gives
  def keep_offered_level_feats
    dropped = level_feat_entries.reject { |entry| creation_feat_levels.include?(entry["level"].to_i) }
    return if dropped.empty?

    untick_skills(dropped.flat_map { |entry| Array(entry["skills"]) })
    self.feats = Array(feats) - dropped
    sync_feat_spells
  end

  # The errors of each feat of its creation, for CharacterFeatSpellsValidator
  def level_feat_errors
    creation_feats.flat_map do |form|
      form.valid? ? [] : form.errors.map { |error| [form.level, error.message] }
    end
  end

  private

  # The feats taken through a level, not through an option (the background, the species)
  def level_feat_entries
    Array(feats).select { |entry| entry["source"].nil? && entry["level"] }
  end

  # Each feat read on the character as it is when its level comes: with the feats of the levels before it. Its spells,
  # picked at the Spells step, stay while the feat and its list stay
  def add_level_feat(level, picks, previous)
    entry = CreationFeat.new(character: self, level: level, **level_feat_attributes(picks)).feat_entry
    self.feats = feats + [with_kept_spell_picks(entry, previous)] if entry
  end

  def level_feat_attributes(picks)
    picks.to_h.stringify_keys.slice("feat_key", "ability_increases", "feat_skill_keys", "feat_spells").symbolize_keys
  end
end
