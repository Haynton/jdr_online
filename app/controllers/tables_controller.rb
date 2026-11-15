class TablesController < ApplicationController
  # "My tables": the page a user lands on after signing in
  def index
    # Always empty for now: becomes current_user.tables once the Table model exists
    @tables = []
  end

  # Temporary page: says that creating a table is coming. The form arrives with the Table model
  def new
  end
end
