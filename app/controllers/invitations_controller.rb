# The invitation link a game master sends to the players (/invitations/:token).
# Temporary page: joining a table (sign up or sign in if needed, then the character sheet) comes in its own branch
class InvitationsController < ApplicationController
  def show
    @game_table = GameTable.find_by!(invite_token: params[:token])
  end
end
