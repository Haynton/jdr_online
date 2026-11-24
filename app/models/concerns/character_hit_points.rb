# How a character gets the hit points of the levels after the first (HitPointMethods): the way of its table, or, when
# the table leaves it to the player, the one they took (the first way of the template, the average, until they roll).
# Rolled once on the summary (decision), with the die of its class: the roll holds while the class and the level stay,
# and a roll the table imposes is required to finish the character
module CharacterHitPoints
  extend ActiveSupport::Concern

  RULE = "hit_point_method".freeze

  included do
    validate :hit_dice_rolled, if: -> { pc? && complete? && status_changed? }
  end

  def hit_point_method_in_use
    table = game_table
    return table.rule_method_of(RULE, table.rule_choice(RULE)) unless table.players_choose?(RULE)

    table.rule_method_of(RULE, hit_point_method) || table.rule_methods(RULE).first
  end

  # The hit die of the class and how many to roll (one a level after the first), nil while nothing is to roll: no
  # class yet, level 1, or a template without the rule of the hit points
  def hit_dice_to_roll
    field = sheet_fields.find { |candidate| candidate["rule"] == ComputedRules::HitPointsByLevel::KEY }
    return unless field

    reader = CharacterSheets::SheetReader.new(fields: sheet_fields, sheet: sheet, level_thresholds: [], modifiers: {})
    sides = reader.class_effects(field["class_from"])["hit_die"]
    count = reader.typed_level(field["level_from"]) - 1
    { sides: sides, count: count } if sides && count.positive?
  end

  # The hit dice rolled, while they still hold (the same die, the same number of levels), nil otherwise: the average
  def kept_hit_point_rolls
    dice = hit_dice_to_roll
    results = hit_point_rolls.to_h["results"]
    return unless dice && rolling_hit_dice? && hit_point_rolls["sides"] == dice[:sides] && results&.size == dice[:count]

    results
  end

  # What the rule of the hit points reads (CharacterSheets::Calculator): the rolls kept, the average (nil), or nothing
  # known while a roll the table imposes is still to make
  def hit_point_rolls_for_rules
    return HitPointMethods::Roll::NOT_ROLLED if hit_dice_roll_due?

    kept_hit_point_rolls
  end

  # The player may roll: dice to roll, not rolled yet, and a table that rolls or leaves it to them
  def may_roll_hit_dice?
    hit_dice_to_roll.present? && kept_hit_point_rolls.nil? &&
      (game_table.players_choose?(RULE) || rolling_hit_dice?)
  end

  # One roll of the hit die a level after the first (the server rolls, never the browser); under the player's choice,
  # rolling takes the way of the roll
  def roll_hit_dice(random: Random.new)
    dice = hit_dice_to_roll
    self.hit_point_method = HitPointMethods::Roll::KEY if game_table.players_choose?(RULE)
    results = Array.new(dice[:count]) { random.rand(1..dice[:sides]) }
    self.hit_point_rolls = { "sides" => dice[:sides], "results" => results }
  end

  private

  def rolling_hit_dice?
    method = hit_point_method_in_use
    method.present? && HitPointMethods.find(method["type"])&.rolls_dice?
  end

  # A roll the table imposes, not made yet
  def hit_dice_roll_due?
    !game_table.players_choose?(RULE) && rolling_hit_dice? && hit_dice_to_roll.present? && kept_hit_point_rolls.nil?
  end

  # A roll the table imposes is made before the character is done
  def hit_dice_rolled
    errors.add(:hit_point_rolls, :not_rolled) if hit_dice_roll_due?
  end
end
