# What changes on a player's character during the game, saved (decision of 26 November): its hit points, its temporary
# hit points and its switches granted in play (the inspiration), changed by the game master from the quick sheet of
# any player, or by a player on their own panel « Ma fiche »; a long rest, by the game master only (CharacterVitals).
# Anyone else gets a 404. The new values go to the whole table at once (GameTableChannel): the hit points and the
# temporary ones, the bar, the ring of the portrait, the switches (game_tables/character_vitals/_streams)
module GameTables
  class CharacterVitalsController < ApplicationController
    before_action :set_character

    def update
      apply_changes
      save_and_share
    end

    def long_rest
      raise ActiveRecord::RecordNotFound unless @participation.game_master?

      @character.take_long_rest
      save_and_share
    end

    private

    def set_character
      @participation = current_user.participations.accepted.find_by!(game_table_id: params[:game_table_id])
      @game_table = @participation.game_table
      @character = @game_table.characters.pc.find(params[:id])
      return if @participation.game_master? || @character.participation_id == @participation.id

      raise ActiveRecord::RecordNotFound
    end

    def apply_changes
      @character.change_hit_points(params[:hit_points_delta].to_i) if params[:hit_points_delta]
      if params[:temporary_hit_points_delta]
        @character.change_temporary_hit_points(params[:temporary_hit_points_delta].to_i)
      end
      @character.switch(params[:switch], params[:switched_on] == "true") if params[:switch]
    end

    def save_and_share
      return head(:unprocessable_content) unless @character.save

      streams = render_to_string(partial: "game_tables/character_vitals/streams", formats: [:turbo_stream],
                                 locals: { character: @character })
      Turbo::StreamsChannel.broadcast_stream_to(@game_table, content: streams)
      render turbo_stream: streams
    end
  end
end
