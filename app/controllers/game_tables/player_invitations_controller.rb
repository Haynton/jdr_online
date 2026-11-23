# The game master invites players by their username from the summary of the creation, or takes an invitation back.
# An invited player stays pending until they accept (their side comes with joining a table)
module GameTables
  class PlayerInvitationsController < ApplicationController
    include TableOfGameMaster

    def create
      @player_invitation = PlayerInvitation.new(game_table: @game_table, username: invitation_params[:username])
      return render_summary_with_error unless @player_invitation.save

      # For screen readers only: on screen, the player shows in the list, marked as pending
      redirect_to game_table_summary_path(@game_table),
                  flash: { screen_reader_notice: t(".invited", username: @player_invitation.invited_username) }
    end

    # Pending or accepted, any player of the draft: the game master is never in this list
    def destroy
      participation = @game_table.participations.player.find(params[:id])
      participation.destroy
      redirect_to game_table_summary_path(@game_table),
                  flash: { screen_reader_notice: t(".removed", username: participation.user.username) }
    end

    private

    def invitation_params
      params.expect(player_invitation: [:username])
    end

    # The summary again, its field showing why the invitation was refused
    def render_summary_with_error
      @game_table = GameTable.includes(participations: :user).find(@game_table.id)
      render "game_tables/summaries/show", status: :unprocessable_content
    end
  end
end
