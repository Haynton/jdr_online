# "Roll the hit dice" on the summary of a character: the server rolls the hit die of its class once a level after the
# first and keeps the results (Character#roll_hit_dice), when the table rolls them or leaves it to the player. One
# roll only (decision): anything else (rolled already, nothing to roll, another way) gets a 404, as anyone else than
# the player of a character not done yet. Back to the summary, where the hit points show the dice
module GameTables
  class HitDiceRollsController < ApplicationController
    def create
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      character = participation.character
      return head :not_found unless character&.draft? && character.may_roll_hit_dice?

      character.roll_hit_dice
      character.save!
      # For screen readers only: the hit points and their dice show on the summary
      results = character.hit_point_rolls["results"].to_sentence
      redirect_to game_table_character_step_path(participation.game_table, CharacterCreationSteps::SUMMARY),
                  flash: { screen_reader_notice: t(".rolled", results: results) }
    end
  end
end
