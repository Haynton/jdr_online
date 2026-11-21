class GameTablesController < ApplicationController
  include GameTableDetails

  before_action :set_available_sheet_templates, only: %i[new create]

  # "My tables": the page a user lands on after signing in. One card per table they run or play at,
  # newest first. The chosen table (?table=<id>) is shown large at the top, the newest one by default
  def index
    @participations = current_user.participations
                                  .includes(game_table: { participations: :user })
                                  .order(created_at: :desc)
    @chosen_participation = chosen_participation
  end

  # First step of the creation: name, description, cover and sheet template
  def new
    @game_table = GameTable.new
  end

  # The new table is a draft: "My tables" shows it with "Resume the creation" until its last step.
  # Its message is for screen readers only: on screen, the table itself shows large, marked as a draft
  def create
    @game_table = GameTableCreator.new(user: current_user, attributes: game_table_details_params,
                                       sheet_template: chosen_sheet_template).call
    return render :new, status: :unprocessable_content unless @game_table.persisted?

    redirect_to game_tables_path(table: @game_table.id), flash: { screen_reader_notice: t(".created") }
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
