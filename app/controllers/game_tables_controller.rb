class GameTablesController < ApplicationController
  # "My tables": the page a user lands on after signing in, with the tables they play at or run
  def index
    @game_tables = current_user.game_tables
  end

  # Temporary page: says that creating a table is coming. The form arrives in its own branch
  def new
  end
end
