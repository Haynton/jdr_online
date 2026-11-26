# Rolls dice for the game room: `count` dice of `sides` sides, plus a bonus. The server rolls, never the browser
# (rule of the project). A mode, declared by the template (character_fields.dice_rolls.modes: advantage,
# disadvantage), replaces a single die by `dice` dice and keeps the highest or the lowest of them
class DiceRoller
  class InvalidRoll < StandardError; end

  SIDES = [4, 6, 8, 10, 12, 20, 100].freeze
  COUNTS = 1..20
  BONUSES = -50..50
  KEPT_DIE = { "highest" => :max, "lowest" => :min }.freeze

  Result = Data.define(:count, :sides, :bonus, :mode_key, :dice, :kept, :total)

  # random: given by the tests, to know the dice in advance
  def initialize(count:, sides:, bonus: 0, mode: nil, random: Random.new)
    @count = count
    @sides = sides
    @bonus = bonus
    @mode = mode
    @random = random
  end

  def call
    check_roll
    dice = Array.new(rolled_dice_count) { @random.rand(1..@sides) }
    kept = kept_dice(dice)
    Result.new(count: @count, sides: @sides, bonus: @bonus, mode_key: @mode&.fetch("key"), dice:, kept:,
               total: kept.sum + @bonus)
  end

  private

  def check_roll
    raise InvalidRoll, "unknown die: d#{@sides}" unless SIDES.include?(@sides)
    raise InvalidRoll, "count out of range: #{@count}" unless COUNTS.cover?(@count)
    raise InvalidRoll, "bonus out of range: #{@bonus}" unless BONUSES.cover?(@bonus)
    raise InvalidRoll, "a mode rolls a single die" if @mode && @count != 1
  end

  def rolled_dice_count
    @mode ? @mode.fetch("dice") : @count
  end

  def kept_dice(dice)
    return dice unless @mode

    [dice.public_send(KEPT_DIE.fetch(@mode.fetch("keep")))]
  end
end
