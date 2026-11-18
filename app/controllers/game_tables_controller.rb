class GameTablesController < ApplicationController
  def index
    @tables = GameTable.all
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
