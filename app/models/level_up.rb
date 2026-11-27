# A player's character reaching the level the game master gave it (characters.level_up_to, decision of 26 November),
# in a window of the game room: only the choices that level asks. Its hit points, by the average or a roll of the hit
# die (the way of the table, or the player's when the table leaves it to them); its subclass when the level reaches
# it; the ability improvement of its class (ChoiceEffects::AbilityScoreImprovement); the expertise its class gives at
# that level. The new spells and weapon masteries are picked afterwards, in « Changer mes sorts » and « Changer mes
# maîtrises ». A form object, its errors under each choice; CharacterSheets::LevelUpApplier makes the change
class LevelUp
  include ActiveModel::Model
  include LevelUpChoices

  attr_reader :character, :level, :ability_increases, :expertise_keys, :class_choices, :skill_keys
  attr_accessor :hit_point_choice, :subclass

  validate :hit_point_choice_offered
  validate :subclass_offered, if: :subclass_field
  validate :ability_increases_allowed, if: :improvement
  validate :expertise_allowed, if: -> { expertise_count.positive? }
  validate :class_choices_picked, if: -> { class_choice_groups_to_pick.any? }
  validate :skills_picked, if: -> { skill_count.positive? }

  def initialize(character:, **attributes)
    @character = character
    @level = character.level_up_to
    @ability_increases = {}
    @expertise_keys = []
    @class_choices = {}
    @skill_keys = []
    super(**attributes)
    self.hit_point_choice ||= hit_point_choices.first
  end

  def ability_increases=(increases)
    @ability_increases = increases.to_h.transform_values(&:to_i).select { |_key, points| points.positive? }
  end

  def expertise_keys=(keys)
    @expertise_keys = Array(keys).compact_blank.uniq
  end

  # The options ticked by group (a hidden empty value lets every box be unticked)
  def class_choices=(picks)
    @class_choices = picks.to_h.to_h { |group, keys| [group.to_s, Array(keys).compact_blank] }
  end

  def skill_keys=(keys)
    @skill_keys = Array(keys).compact_blank.uniq
  end

  def save
    return false unless valid?

    CharacterSheets::LevelUpApplier.new(self).call
  end

  private

  def hit_point_choice_offered
    return if hit_point_choices.empty? || hit_point_choices.include?(hit_point_choice)

    errors.add(:hit_point_choice, :inclusion)
  end

  def subclass_offered
    errors.add(:subclass, :inclusion) unless subclass_options.map(&:last).include?(subclass)
  end

  def ability_increases_allowed
    return errors.add(:ability_increases, :not_shared, points: improvement["points"]) unless increases_shared?

    over = ability_fields.find { |field| field["max"] && raised_score(field) > field["max"] }
    errors.add(:ability_increases, :above_maximum, ability: over["label"], maximum: over["max"]) if over
  end

  # Every point on an ability of the sheet, at most so many on one, all of them shared
  def increases_shared?
    keys = ability_fields.pluck("key")
    ability_increases.values.sum == improvement["points"] &&
      ability_increases.all? { |key, points| keys.include?(key) && points <= improvement["max_per_ability"] }
  end

  def raised_score(field)
    score_of(field).to_i + ability_increases[field["key"]].to_i
  end

  # Every group with new options gets as many as it gives at this level, each one the character may take
  def class_choices_picked
    future = future_character
    CharacterClassChoicesValidator.new.validate(future)
    future.errors.full_messages_for(:class_choices).each { |message| errors.add(:class_choices, message) }
    class_choice_groups_to_pick.each do |group|
      next if Array(class_choices[group.key]).size == group.allowed_count

      errors.add(:class_choices, :not_picked, group: group.label, count: group.allowed_count)
    end
  end

  def skills_picked
    return if skill_keys.size == skill_count && (skill_keys - skill_candidates.pluck("key")).empty?

    errors.add(:skill_keys, :not_picked, count: skill_count)
  end

  def expertise_allowed
    candidates = expertise_candidates.pluck("key")
    return if expertise_keys.size == expertise_count && (expertise_keys - candidates).empty?

    errors.add(:expertise_keys, :not_picked, count: expertise_count)
  end
end
