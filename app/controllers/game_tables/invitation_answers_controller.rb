# The invited player answers the invitation of a game master, from "My tables".
# Only their own invitation, to a table that is ready: anything else is a 404
module GameTables
  class InvitationAnswersController < ApplicationController
    before_action :set_invitation

    # The table becomes one of theirs and stays chosen at the top, now with "Join the game".
    # For screen readers only: on screen, the table shows it already
    def update
      @invitation.accepted!
      redirect_to game_tables_path(table: @invitation.game_table_id),
                  flash: { screen_reader_notice: t(".accepted", name: @invitation.game_table.name) }
    end

    # The game master may invite them again later. Declined from the window of the bell, the window stays
    def destroy
      @invitation.destroy
      return_path = turbo_frame_request_id == NotificationsHelper::FRAME ? notifications_path : game_tables_path
      redirect_to return_path, flash: { screen_reader_notice: t(".declined", name: @invitation.game_table.name) }
    end

    private

    def set_invitation
      @invitation = current_user.participations.invitations_to_ready_tables
                                .find_by!(game_table_id: params[:game_table_id])
    end
  end
end
