# A player makes the choices of the level the game master gave their character (LevelUp), in the window of the game
# room (decision of 26 November): its hit points, its subclass, its ability improvement, its expertise, only what that
# level asks. Done, the room is refreshed and the chat says it. Only a player accepted at the table, whose complete
# character has a level waiting (a 404 otherwise)
module GameTables
  class LevelUpsController < ApplicationController
    include VariesOnTurboFrame

    before_action :set_level_up

    def new
    end

    def create
      @level_up.assign_attributes(level_up_params)
      return render(:new, status: :unprocessable_content) unless @level_up.save

      render turbo_stream: turbo_stream.refresh(request_id: nil)
    end

    private

    def set_level_up
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      @game_table = participation.game_table
      @character = participation.character
      raise ActiveRecord::RecordNotFound unless @character&.complete? && @character.level_up_to

      @level_up = LevelUp.new(character: @character)
    end

    def level_up_params
      params.fetch(:level_up, {})
            .permit(:hit_point_choice, :subclass, :feat_key, ability_increases: {}, class_choices: {}, feat_spells: {},
                                                             feat_spell_swaps: {}, expertise_keys: [], skill_keys: [],
                                                             feat_skill_keys: [], spellbook_keys: [])
    end
  end
end
