# What the level a player's character reaches asks (LevelUp): the ways to gain its hit points, the list asked from
# that level (the subclass), the ability improvement and the expertise its class gives then. Each read in what the
# template declares: the rule of the hit points (its class list and its ability), the effects of the class
module LevelUpChoices
  extend ActiveSupport::Concern

  HIT_POINT_CHOICES = %w[average roll].freeze

  delegate :game_table, to: :character

  # The way of the table, or both when it leaves it to the player (average first); none without a hit die to gain
  def hit_point_choices
    return [] unless hit_die

    return HIT_POINT_CHOICES if game_table.players_choose?(CharacterHitPoints::RULE)

    rolls = character.hit_point_method_in_use.then { |method| method && HitPointMethods.find(method["type"]) }
    [rolls&.rolls_dice? ? "roll" : "average"]
  end

  # The hit die of its class, nil for a template without the rule of the hit points
  def hit_die
    hit_point_field && reader.class_effects(hit_point_field["class_from"])["hit_die"]
  end

  # The points the average gives: half the die plus one, plus the modifier the rule reads (Constitution), at least 1
  def average_hit_points
    modifier = character.computed_sheet_values[:modifiers].to_h[hit_point_field["based_on"]].to_i
    [(hit_die / 2) + 1 + modifier, 1].max
  end

  # The list that depends on another and is asked from this level, still empty (the subclass at level 3)
  def subclass_field
    @subclass_field ||= character.sheet_fields.find do |field|
      field["type"] == "choice" && field["from_level"] && character.sheet[field["key"]].blank? &&
        FieldTypes.of(field).asked_on?(field, sheet_at_level)
    end
  end

  def subclass_options
    FieldTypes.of(subclass_field).sheet_list_choices(subclass_field, sheet_at_level)
  end

  # { "points" => 2, "max_per_ability" => 2 } when its class improves the abilities at this level, nil otherwise
  def improvement
    declared = class_effects["ability_score_improvement"]
    declared if declared.to_h["levels"].to_a.include?(level)
  end

  def ability_fields
    character.sheet_fields.select { |field| field["type"] == "ability" }
  end

  # The score now, with the bonus of the background: the window shows it, the maximum is checked against it
  def score_of(field)
    scores[field["key"]]
  end

  # The skills whose proficiency counts twice from this level (its class: the rogue at 6, the bard at 9)
  def expertise_count
    expertise_entries.sum { |entry| entry["count"] }
  end

  # The skills it is proficient in, without expertise yet, among those its class names when it names some
  def expertise_candidates
    allowed = expertise_entries.flat_map { |entry| Array(entry["from"]) }
    keys = character.skill_choices.skill_keys.select { |key| allowed.empty? || allowed.include?(key) }
    character.sheet_fields.select { |field| keys.include?(field["key"]) && proficient_only?(field["key"]) }
  end

  # The groups of choices of the class with options to pick at this level (invocations, metamagic, a land), read on
  # the character as it will be (its subclass picked in the same window counts)
  def class_choice_groups_to_pick
    @class_choice_groups_to_pick ||= future_character.class_choice_groups.groups.select do |group|
      group.allowed_count > Array(character.class_choices.to_h[group.key]).size
    end
  end

  # The skills the subclass picked in this window offers to choose (the College of Lore: 3), 0 otherwise
  def skill_count
    return 0 unless subclass_field && subclass.present?

    subclass_field.dig("effects", subclass, "skill_choices", "count").to_i
  end

  # The skills it may pick: those the subclass offers, not proficient yet
  def skill_candidates
    offered = subclass_field.dig("effects", subclass, "skill_choices", "from").to_a
    character.sheet_fields.select do |field|
      offered.include?(field["key"]) && !FieldTypes::Bonus.proficient?(character.sheet[field["key"]])
    end
  end

  # The character as it will be: the new level, the subclass picked, the choices made in the window
  def future_character
    future = character.dup
    picked_subclass = subclass_field && subclass.present? ? { subclass_field["key"] => subclass } : {}
    future.sheet = sheet_at_level.merge(picked_subclass)
    future.class_choices = character.class_choices.to_h.merge(class_choices.to_h)
    future
  end

  # The class list read by the rule of the hit points (its class_from), nil without that rule
  def hit_point_field
    @hit_point_field ||= character.sheet_fields.find { |field| field["rule"] == ComputedRules::HitPointsByLevel::KEY }
  end

  def level_field
    character.sheet_fields.find { |field| field["from_table"] == "starting_level" }
  end

  private

  def reader
    @reader ||= CharacterSheets::SheetReader.new(fields: character.sheet_fields, sheet: sheet_at_level,
                                                 level_thresholds: [], modifiers: {})
  end

  def class_effects
    hit_point_field ? reader.class_effects(hit_point_field["class_from"]) : {}
  end

  def sheet_at_level
    @sheet_at_level ||= level_field ? character.sheet.merge(level_field["key"] => level) : character.sheet
  end

  def scores
    @scores ||= character.computed_sheet_values[:scores].to_h
  end

  def expertise_entries
    class_effects["expertise_choices"].to_a.select { |entry| entry.is_a?(Hash) && entry["level"] == level }
  end

  def proficient_only?(key)
    value = character.sheet[key]
    FieldTypes::Bonus.proficient?(value) && !FieldTypes::Bonus.expertise?(value)
  end
end
