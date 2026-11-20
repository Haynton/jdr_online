class GameTablesController < ApplicationController
  # "My tables": the page a user lands on after signing in. One card per table they run or play at,
  # newest first. The chosen table (?table=<id>) is shown large at the top, the newest one by default
  def index
    @participations = current_user.participations
                                  .includes(game_table: { participations: :user })
                                  .order(created_at: :desc)
    @chosen_participation = chosen_participation
  end

  # Temporary page: says that creating a table is coming. The form arrives in its own branch
  def new
  end

  # Temporary page of a table. Only its participants reach it: anyone else gets a 404
  def show
    @game_table = current_user.game_tables.find(params[:id])
  end

  # Temporary settings page of a table. Only its game master reaches it: a player gets a 404 too
  def edit
    @game_table = current_user.participations.game_master.find_by!(game_table_id: params[:id]).game_table
  end

  private

  # Only among the tables of the user: the id of another table falls back to the newest one
  def chosen_participation
    chosen_table_id = params[:table].to_i
    @participations.find { |participation| participation.game_table_id == chosen_table_id } || @participations.first
  end
end
