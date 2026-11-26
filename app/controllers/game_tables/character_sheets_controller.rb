# The sheet of a character from the game room (its abilities, combat, spells, inventory), read only, in the window of
# the room (game_rooms/_sheet_dialog); opened directly or without JavaScript, a page. Checked by the server: someone
# at the table (accepted), and then the game master sees any character of its players, a player only their own.
# Anything else is a 404
module GameTables
  class CharacterSheetsController < ApplicationController
    include VariesOnTurboFrame

    def show
      participation = current_user.participations.accepted.find_by!(game_table_id: params[:game_table_id])
      @game_table = participation.game_table
      @character = sheet_shown_to(participation)
    end

    private

    def sheet_shown_to(participation)
      return @game_table.characters.pc.find(params[:id]) if participation.game_master?

      own_character = participation.character
      raise ActiveRecord::RecordNotFound unless own_character&.id == params[:id].to_i

      own_character
    end
  end
end
