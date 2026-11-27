# The hit dice a player's character spends to heal (decision of 26 November: whenever the player wants, the game master
# judges; the rules say during a short rest): one per level, of the die of its class, read in what the template
# declares for its hit points (the field of the rule hit_points_by_level: the class it reads, the ability it adds).
# The server rolls the die, adds the modifier and gives back that many hit points; a long rest gives back every die
module CharacterHitDice
  extend ActiveSupport::Concern

  # What a die spent did: its roll, the modifier added, the hit points given back
  HitDieSpent = Data.define(:sides, :roll, :modifier, :healed)

  def hit_dice_total
    hit_die_sides ? spell_choices.level : 0
  end

  def hit_dice_left
    hit_dice_total - hit_dice_used.to_i.clamp(0, hit_dice_total)
  end

  def hit_die_sides
    field = hit_points_rule_field
    return unless pc? && field

    reader = CharacterSheets::SheetReader.new(fields: sheet_fields, sheet: sheet, level_thresholds: [], modifiers: {})
    reader.class_effects(field["class_from"])["hit_die"]
  end

  # nil when none is left or the character has no hit points to give back
  def spend_hit_die(random: Random.new)
    sides = hit_die_sides
    return unless sides && hit_dice_left.positive? && hit_points

    roll = DiceRolls::Roller.new(count: 1, sides: sides, random: random).call.total
    modifier = computed_sheet_values[:modifiers][hit_points_rule_field["based_on"]].to_i
    healed = [roll + modifier, 0].max
    change_hit_points(healed)
    self.hit_dice_used = hit_dice_used.to_i + 1
    HitDieSpent.new(sides:, roll:, modifier:, healed:)
  end

  def give_back_hit_dice
    self.hit_dice_used = 0
  end

  private

  def hit_points_rule_field
    sheet_fields.find { |field| field["type"] == "computed" && field["rule"] == "hit_points_by_level" }
  end
end
