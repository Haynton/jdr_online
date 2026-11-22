# "Roll the dice" of the abilities on the character sheet: the server rolls one score per ability, by the method of the
# template copied into the table (CharacterSheets::AbilityScoreRoller), and answers in JSON
# (ability_roll_controller.js). Only for a player of the table: anyone else gets a 404. Nothing is stored: the player
# places the results, or types their own
module GameTables
  class AbilityRollsController < ApplicationController
    def create
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      game_table = participation.game_table
      return head :not_found unless game_table.ability_roll_method

      results = CharacterSheets::AbilityScoreRoller.new(method: game_table.ability_roll_method,
                                                        count: game_table.ability_fields.size).call
      render json: { results: results.map(&:to_h) }
    end
  end
end
