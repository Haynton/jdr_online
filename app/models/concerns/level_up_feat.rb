# The feat a player's character takes at a level that improves its abilities (decision of 27 November, SRD 5.2.1): the
# Ability Score Improvement by default, or another feat it may take (CharacterSheets::Feats: origin, general, fighting
# style, and an epic boon at an epic level, 19), with what that feat asks: points to share on the abilities (the
# improvement, the grappler, the epic boons: ability_increase), skills (skilled: skill_picks). Part of LevelUp
module LevelUpFeat
  extend ActiveSupport::Concern
  include LevelUpFeatSpells

  DEFAULT_FEAT = "ability-score-improvement".freeze

  included do
    # The card picked: the key of the feat, and its list after a ~ for a feat that gives spells
    # (CharacterSheets::FeatCards)
    attr_accessor :feat_key
    attr_reader :ability_increases, :feat_skill_keys

    validate :feat_offered, if: :feat_level?
    validate :ability_increases_allowed, if: -> { feat_level? && increase_settings }
    validate :feat_skills_picked, if: -> { feat_level? && feat_skill_count.positive? }
  end

  def ability_increases=(increases)
    @ability_increases = increases.to_h.transform_values(&:to_i).select { |_key, points| points.positive? }
  end

  def feat_skill_keys=(keys)
    @feat_skill_keys = Array(keys).compact_blank.uniq
  end

  # The level improves its abilities (the effect ability_score_improvement of its class): a feat is taken
  def feat_level?
    improvement.present?
  end

  # Only the improvement when the table turns the feats at the levels off (GameTable#level_feats)
  def offered_feats
    @offered_feats ||= begin
      offered = feat_list.offered(level: level, epic: epic_level?)
      character.game_table.level_feats ? offered : offered.select { |candidate| candidate.key == DEFAULT_FEAT }
    end
  end

  def feat(key = feat_key)
    base_key = CharacterSheets::FeatCards.split(key).first
    offered_feats.find { |candidate| candidate.key == base_key }
  end

  # What a feat lets share on the abilities ({ "points" => 2, "max_per_ability" => 2, "maximum" => 20 }), nil for none
  def increase_settings(for_feat = feat)
    for_feat&.effects&.dig("ability_increase")
  end

  # The abilities a feat may raise: those it names, every one otherwise
  def increase_fields(for_feat = feat)
    named = increase_settings(for_feat).to_h["abilities"]
    named ? ability_fields.select { |field| named.include?(field["key"]) } : ability_fields
  end

  def feat_skill_count(for_feat = feat)
    for_feat&.effects&.dig("skill_picks", "count").to_i
  end

  # Any skill it is not proficient in yet
  def feat_skill_candidates
    keys = character.skill_choices.skill_keys
    character.sheet_fields.select do |field|
      keys.include?(field["key"]) && !FieldTypes::Bonus.proficient?(character.sheet[field["key"]])
    end
  end

  # What is kept for the feat taken: { "key", "level", "abilities", "skills" }, nil when the level gives none
  def feat_entry
    return unless feat_level? && feat

    entry = { "key" => feat.key, "level" => level }
    entry["abilities"] = ability_increases if increase_settings && ability_increases.any?
    entry["skills"] = feat_skill_keys if feat_skill_count.positive?
    spell_settings ? entry.merge(feat_spell_picks.to_h) : entry
  end

  def feat_list
    @feat_list ||= character.feat_list
  end

  private

  def epic_level?
    class_effects.dig("ability_score_improvement", "epic_levels").to_a.include?(level)
  end

  def default_feat_key
    offered_feats.find { |candidate| candidate.key == DEFAULT_FEAT }&.key || offered_feats.first&.key
  end

  def feat_offered
    errors.add(:feat_key, :inclusion) unless feat
  end

  def ability_increases_allowed
    settings = increase_settings
    return errors.add(:ability_increases, :not_shared, points: settings["points"]) unless increases_shared?(settings)

    over = increase_fields.find { |field| raised_score(field) > settings["maximum"].to_i }
    errors.add(:ability_increases, :above_maximum, ability: over["label"], maximum: settings["maximum"]) if over
  end

  # Every point on an ability the feat may raise, at most so many on one, all of them shared
  def increases_shared?(settings)
    keys = increase_fields.pluck("key")
    ability_increases.values.sum == settings["points"] &&
      ability_increases.all? { |key, points| keys.include?(key) && points <= settings["max_per_ability"] }
  end

  def raised_score(field)
    score_of(field).to_i + ability_increases[field["key"]].to_i
  end

  def feat_skills_picked
    return if feat_skill_keys.size == feat_skill_count && (feat_skill_keys - feat_skill_candidates.pluck("key")).empty?

    errors.add(:feat_skill_keys, :not_picked, count: feat_skill_count)
  end
end
