# The game master gives the next level to a player's character, from its quick sheet in the game room (decision of
# 26 November): one level at a time, never beyond the last (Character#grant_level). The player then makes the choices
# of that level (GameTables::LevelUpsController). Written in the chat; the room of the whole table is refreshed, so
# that the player sees the level waiting. Only the game master of the table, for a complete character of a player
# (a 404 otherwise)
module GameTables
  class LevelGrantsController < ApplicationController
    include TableOfGameMaster

    def create
      character = @game_table.characters.pc.complete.find(params[:character_id])
      return head(:unprocessable_content) unless character.grant_level

      character.save!
      ChatMessage.record_event(@game_table, :level_granted, character: character.name, level: character.level_up_to)
      Turbo::StreamsChannel.broadcast_refresh_to(@game_table)
      render turbo_stream: turbo_stream.refresh(request_id: nil)
    end
  end
end
