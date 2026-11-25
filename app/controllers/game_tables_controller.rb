class GameTablesController < ApplicationController
  include GameTableDetails

  before_action :set_available_sheet_templates, only: %i[new create]

  # "My tables": the page a user lands on after signing in. One card per table they run or play at,
  # newest first. The chosen table (?table=<id>) is shown large at the top, the newest one by default.
  # The invitations come first: the newest one stays at the top until the player answers it
  def index
    participations = current_user.participations.shown_in_my_tables
                                 .preload(game_table: { participations: { user: { avatar_attachment: :blob } } })
                                 .order(created_at: :desc)
    @participations = participations.partition(&:pending?).flatten
    @chosen_participation = chosen_participation
  end

  # First step of the creation: name, description, cover and sheet template
  def new
    @game_table = GameTable.new
  end

  # The new table is a draft until the last step of its creation: "My tables" shows it with "Resume the creation".
  # Its message is for screen readers only: on screen, the next step shows
  def create
    @game_table = GameTableCreator.new(user: current_user, attributes: game_table_details_params,
                                       sheet_template: chosen_sheet_template).call
    return render :new, status: :unprocessable_content unless @game_table.persisted?

    @game_table.reach_creation_step(GameTable.next_creation_step("details"))
    redirect_to edit_game_table_settings_path(@game_table), flash: { screen_reader_notice: t(".created") }
  end

  # Temporary page of a table. Only its participants reach it: anyone else gets a 404.
  # A player makes their character first (decision): until then, the page leads to it
  def show
    participation = current_user.participations.accepted.find_by!(game_table_id: params[:id])
    return redirect_to new_game_table_character_path(participation.game_table) if participation.needs_character?

    @game_table = participation.game_table
  end

  # Temporary settings page of a table. Only its game master reaches it: a player gets a 404 too
  # The settings of a table are the pages of its creation (decision): an old link to this address leads there
  def edit
    game_table = current_user.participations.game_master.find_by!(game_table_id: params[:id]).game_table
    redirect_to edit_game_table_details_path(game_table)
  end

  # Deleted by its game master only, a draft or a table ready (decision), from its page Informations: its players,
  # their characters, its NPCs and its own catalog entries go with it. Its message is for screen readers only, as for a
  # template deleted: the table is no longer in "My tables"
  def destroy
    game_table = current_user.participations.game_master.find_by!(game_table_id: params[:id]).game_table
    game_table.destroy!
    redirect_to game_tables_path, flash: { screen_reader_notice: t(".deleted", name: game_table.name) }
  end

  private

  # Only among the tables of the user: the id of another table falls back to the newest one
  def chosen_participation
    chosen_table_id = params[:table].to_i
    @participations.find { |participation| participation.game_table_id == chosen_table_id } || @participations.first
  end
end
