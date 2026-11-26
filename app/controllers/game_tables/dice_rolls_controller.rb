# A roll of dice from the panel « Dés » of the game room. Only someone accepted at the table rolls (the rule of the
# chat: an invitation still pending is not enough); anyone else gets a 404. The server rolls and writes the roll in
# the feed (DiceRollRecorder), sent live to the table, or to the game master alone for a hidden roll; the answer adds
# the line to the page of who rolled too (Turbo keeps one line per id). A roll the panel does not offer is refused
module GameTables
  class DiceRollsController < ApplicationController
    def create
      participation = current_user.participations.accepted.find_by!(game_table_id: params[:game_table_id])
      @chat_message = DiceRollRecorder.new(participation, roll_params).call
    rescue DiceRoller::InvalidRoll
      head :unprocessable_content
    end

    private

    def roll_params
      roll = params.require(:dice_roll).permit(:count, :sides, :bonus, :mode, :hidden)
      { count: roll[:count].to_i, sides: roll[:sides].to_i, bonus: roll[:bonus].to_i, mode_key: roll[:mode],
        hidden: ActiveModel::Type::Boolean.new.cast(roll[:hidden]) || false }
    end
  end
end
