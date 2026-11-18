class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  # The home page is for visitors: a signed in user goes to their tables
  def home
    redirect_to game_tables_path if user_signed_in?
  end
end
