# Rolls the scores of the abilities of a new character by the method of the template (ability_roll): for each
# ability, `dice` dice of `sides` sides, keeping the `keep_highest` best (4d6, keeping the 3 best). The server rolls,
# never the browser (rule of the project). The results are an aid, not a check (decision): the player places them,
# rolls again or types their own scores, so nothing is stored
class AbilityScoreRoller
  Result = Struct.new(:total, :dice, :kept, keyword_init: true)

  # random: given by the tests, to know the dice in advance
  def initialize(method:, count:, random: Random.new)
    @dice_count = method.fetch("dice")
    @sides = method.fetch("sides")
    @kept_count = method.fetch("keep_highest", @dice_count)
    @count = count
    @random = random
  end

  # The best result first, as a player lines them up before placing them
  def call
    Array.new(@count) { roll_one_score }.sort_by { |result| -result.total }
  end

  private

  def roll_one_score
    dice = Array.new(@dice_count) { @random.rand(1..@sides) }
    kept = dice.max(@kept_count)
    Result.new(total: kept.sum, dice: dice, kept: kept)
  end
end
