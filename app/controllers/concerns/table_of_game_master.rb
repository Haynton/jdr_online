# The steps of the creation of a table (app/controllers/game_tables/) work on a table of the current user as its game
# master: a draft being created, or a table ready, whose "Game settings" open the same pages (decision). Anyone else
# gets a 404. What may not change once the table is ready (its sheet template) is refused by each step
module TableOfGameMaster
  extend ActiveSupport::Concern

  included do
    before_action :set_table_of_game_master
  end

  private

  def set_table_of_game_master
    @game_table = current_user.participations.game_master.find_by!(game_table_id: params[:game_table_id]).game_table
  end
end
