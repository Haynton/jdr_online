# "Roll the dice" of the abilities on the character sheet: the server rolls one score per ability, by the method of the
# template copied into the table (CharacterSheets::AbilityScoreRoller), and answers in JSON
# (ability_roll_controller.js). Only for a player of the table: anyone else gets a 404. The roll is kept on the
# character being made (ability_rolls): the server checks the scores against it when the table turns the scores typed
# by hand off, and gives it back instead of rolling again when the table turns the rolls again off
module GameTables
  class AbilityRollsController < ApplicationController
    def create
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      game_table = participation.game_table
      return head :not_found unless game_table.ability_roll_method

      character = participation.character_draft
      return head :not_found if character.complete?

      roll_once_more(character, game_table) unless kept_roll?(character, game_table)
      render json: { results: character.ability_rolls, final: !game_table.ability_rerolls }
    end

    private

    def kept_roll?(character, game_table)
      !game_table.ability_rerolls && character.ability_rolls.present?
    end

    def roll_once_more(character, game_table)
      results = CharacterSheets::AbilityScoreRoller.new(method: game_table.ability_roll_method,
                                                        count: game_table.ability_fields.size).call
      character.ability_rolls = results.map { |result| result.to_h.stringify_keys }
      character.save!(validate: false)
    end
  end
end
