# The feat of a level a player's character starts above (decision of 27 November: created at level 4, it has taken the
# feat of its level 4, as if it had gained it). The same choice as at a level gained (LevelUpFeat: the Ability Score
# Improvement by default, or another feat it may take, with its points, skills and spells), read on the character as it
# was before that level: without the feats of this level and the later ones, so that its own feat is offered again and
# the scores shown do not count its points twice. Built by CharacterLevelFeats, on the step « Dons des niveaux »; the
# spells of a feat that gives some are picked at the Spells step
class CreationFeat
  include ActiveModel::Model
  include LevelUpFeat

  attr_reader :character, :level

  # Its messages are those of a level gained (activemodel.errors.models.level_up)
  def self.lookup_ancestors
    [self, LevelUp]
  end

  def initialize(character:, level:, **attributes)
    @level = level
    @character = character_before_level(character)
    @ability_increases = {}
    @feat_skill_keys = []
    super(**attributes)
    self.feat_key ||= default_feat_key
  end

  # What was kept for that level, sent again to the form (its card, its points, its skills, its spells)
  def self.from_entry(character, level, entry)
    entry = entry.to_h
    new(character: character, level: level,
        feat_key: entry["key"] && CharacterSheets::FeatCards.value_of(entry["key"], entry["spell_list"]),
        ability_increases: entry["abilities"], feat_skill_keys: entry["skills"],
        feat_spells: { "by_list" => { entry["spell_list"] => entry.slice("spell_ability", "cantrips", "spell") } })
  end

  # The names of its fields in the form of the step, and the start of their ids
  def form_name
    "character[level_feats][#{level}]"
  end

  def dom_prefix
    "level_feat_#{level}"
  end

  def improvement
    character.ability_score_improvement
  end

  def ability_fields
    character.sheet_fields.select { |field| field["type"] == "ability" }
  end

  def score_of(field)
    character.computed_sheet_values[:scores].to_h[field["key"]]
  end

  # A feat of the creation that gives spells asks here its list and its ability only: its spells are picked at the
  # Spells step (decision of 28 November, as the origin feats), checked there (CharacterFeatSpellsValidator)
  def feat_spells_picked
    errors_found = character.feat_spells.errors_for(feat_spell_picks.to_h, spell_settings, known: known_spells)
    (errors_found - CharacterFeatSpellsValidator::PICK_ERRORS).each { |error| errors.add(:feat_spells, error) }
  end

  private

  def class_effects
    { "ability_score_improvement" => improvement }
  end

  def character_before_level(character)
    before = character.dup
    before.feats = Array(character.feats).reject { |entry| entry["level"].to_i >= level }
    before
  end
end
