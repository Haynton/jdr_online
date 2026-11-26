# A roll of dice from the panel « Dés » of the game room: dice chosen in the panel (DiceRolls::Recorder), or the
# initiative of a character (DiceRolls::InitiativeRecorder, its own button). Only someone accepted at the table rolls
# (the rule of the chat: an invitation still pending is not enough); anyone else gets a 404. The server rolls and
# writes the roll in the feed, sent live to the table, or to the game master alone for a hidden roll; the answer adds
# the line to the page of who rolled too (Turbo keeps one line per id) and shows the roll in their panel; without
# JavaScript, back to the room, the panel open. A roll the panel does not offer is refused
module GameTables
  class DiceRollsController < ApplicationController
    def create
      participation = current_user.participations.accepted.find_by!(game_table_id: params[:game_table_id])
      recorder = params.dig(:dice_roll, :initiative).present? ? DiceRolls::InitiativeRecorder : DiceRolls::Recorder
      @chat_message = recorder.new(participation, roll_params).call
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to game_table_path(participation.game_table, anchor: "game-room-panel-dice") }
      end
    rescue DiceRolls::Roller::InvalidRoll
      head :unprocessable_content
    end

    private

    def roll_params
      roll = params.require(:dice_roll).permit(:count, :sides, :bonus, :mode, :hidden, :character_id)
      { count: roll[:count].to_i, sides: roll[:sides].to_i, bonus: roll[:bonus].to_i, mode_key: roll[:mode],
        hidden: ActiveModel::Type::Boolean.new.cast(roll[:hidden]) || false, character_id: roll[:character_id] }
    end
  end
end
