# A player makes their character before joining the game (decision), in steps (CharacterStepsController).
# "Create my character" leads here: to the first step, or to the step reached by the draft.
# Only a player of the table whose character is not complete: the game master, anyone else, or an invitation not
# answered yet get a 404
module GameTables
  class CharactersController < ApplicationController
    def new
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      return redirect_to game_table_path(participation.game_table) unless participation.needs_character?

      redirect_to game_table_character_step_path(participation.game_table, resume_step_key(participation))
    end

    private

    def resume_step_key(participation)
      character = participation.character
      steps = CharacterCreationSteps.new(game_table: participation.game_table, sheet: character&.sheet,
                                         feats: character&.feats)
      steps.furthest_reached(character&.creation_step).key
    end
  end
end
