class GameTablesController < ApplicationController
  # "My tables": the page a user lands on after signing in
  def index
    # Always empty for now: becomes current_user.tables once the Table model exists
    @tables = []
  end

  # Temporary page: says that creating a table is coming. The form arrives with the Table model
  def new
  end

  def create
    @game_table = GameTable.new(game_table_params)

    GameTable.transaction do
      @game_table.save!

      @game_table.participations.create!(
        user: current_user
      )
    end

    redirect_to @game_table
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end
end
