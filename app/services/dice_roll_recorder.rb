# A roll of dice asked from the panel « Dés » of the game room: rolled by the server (DiceRoller), then written in the
# feed of the table (ChatMessage) under the name of who rolled (the character of a player, else their username; « Le
# MJ » for the game master). A mode (advantage) is one the template declares (TemplateCopy#dice_rolls), on the die it
# applies to. Only the game master rolls hidden: the line then goes to them alone. Anything the panel does not offer
# raises DiceRoller::InvalidRoll
class DiceRollRecorder
  # asked: what the panel sends (count, sides, bonus, mode_key, hidden)
  def initialize(participation, asked, random: Random.new)
    @participation = participation
    @game_table = participation.game_table
    @roll = asked.slice(:count, :sides, :bonus)
    @mode_key = asked[:mode_key].presence
    @hidden = asked[:hidden] && participation.game_master?
    @random = random
  end

  def call
    mode = declared_mode
    result = DiceRoller.new(**@roll, mode:, random: @random).call
    ChatMessage.record_event(@game_table, event_key, game_master_only: @hidden,
                                                     **roller, notation: notation(result, mode),
                                                     dice: result.dice, total: result.total)
  end

  private

  def declared_mode
    return if @mode_key.nil?

    dice_rolls = @game_table.dice_rolls
    mode = Array(dice_rolls["modes"]).find { |candidate| candidate["key"] == @mode_key }
    raise DiceRoller::InvalidRoll, "unknown mode: #{@mode_key}" unless mode
    raise DiceRoller::InvalidRoll, "no mode on a d#{@roll[:sides]}" unless dice_rolls["modes_on_sides"] == @roll[:sides]

    mode
  end

  # The label of the mode is written by the template, in the words of the game: « 1d20+5 (Avantage) »
  def notation(result, mode)
    mode ? "#{result.notation} (#{mode['label']})" : result.notation
  end

  def event_key
    @participation.game_master? ? :dice_rolled_by_game_master : :dice_rolled
  end

  def roller
    return {} if @participation.game_master?

    { roller: @participation.character&.name.presence || @participation.user.username }
  end
end
