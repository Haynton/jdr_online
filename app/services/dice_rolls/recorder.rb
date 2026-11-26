module DiceRolls
  # A roll of dice asked from the panel « Dés » of the game room: rolled by the server (Roller), then written in the
  # feed of the table (ChatMessage) under the name of who rolled (the character of a player, else their username;
  # « Le MJ » for the game master). Only the game master rolls hidden: the line then goes to them alone. Anything the
  # panel does not offer raises Roller::InvalidRoll
  class Recorder
    include Modes

    # asked: what the panel sends (count, sides, bonus, mode_key, hidden)
    def initialize(participation, asked, random: Random.new)
      @participation = participation
      @game_table = participation.game_table
      @roll = asked.slice(:count, :sides, :bonus)
      @mode_key = asked[:mode_key]
      @hidden = asked[:hidden] && participation.game_master?
      @random = random
    end

    def call
      mode = declared_mode(@game_table, @mode_key, @roll[:sides])
      result = Roller.new(**@roll, mode:, random: @random).call
      ChatMessage.record_event(@game_table, event_key, game_master_only: @hidden,
                                                       **roller, notation: notation(result, mode),
                                                       dice: result.dice, total: result.total)
    end

    private

    def event_key
      @participation.game_master? ? :dice_rolled_by_game_master : :dice_rolled
    end

    def roller
      return {} if @participation.game_master?

      { roller: @participation.character&.name.presence || @participation.user.username }
    end
  end
end
