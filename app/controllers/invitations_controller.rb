# The invitation link a game master sends to the players (/invitations/:token). Anyone with the link sees who
# invites them to which table, with the top bar of the visitors or their navigation (application layout):
# a visitor signs up or in first, and Devise brings them back here (stored location).
# Opening the link changes nothing: "Join the table" (join) makes the user a player, then they make their character.
# A link that was regenerated, or a table still in draft, shows "This link no longer works"
class InvitationsController < ApplicationController
  skip_before_action :authenticate_user!, only: :show
  before_action :set_game_table
  before_action :redirect_if_already_at_table

  def show
    store_location_for(:user, request.fullpath) unless user_signed_in?
  end

  # An invitation by username to the same table, not answered yet, is accepted by the same click
  def join
    participation = @game_table.participations.find_or_initialize_by(user: current_user)
    participation.update!(role: :player, status: :accepted)
    redirect_to new_game_table_character_path(@game_table),
                flash: { screen_reader_notice: t(".joined", name: @game_table.name) }
  end

  private

  def set_game_table
    @game_table = GameTable.find_by(invite_token: params[:token])
    render :invalid, status: :not_found unless @game_table&.joinable?
  end

  def redirect_if_already_at_table
    return unless user_signed_in? && @game_table.participations.accepted.exists?(user: current_user)

    redirect_to game_tables_path(table: @game_table.id)
  end
end
