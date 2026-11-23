# The last step of the creation: the table, the later steps, the invitation link and the invited players.
# On a draft, its two buttons finish the creation: the table is ready, players may join it. The game master then goes
# back to "My tables" or joins the game (decision: finishing the creation does not force them into the game).
# On a table ready, reached from its "Game settings", "Confirm the changes" leads back to "My tables": each step saved
# its own changes already
module GameTables
  class SummariesController < ApplicationController
    include TableOfGameMaster

    # The invited players with their user, for their avatars and usernames: no query per player
    def show
      @game_table = GameTable.includes(participations: :user).find(@game_table.id)
      @player_invitation = PlayerInvitation.new(game_table: @game_table)
    end

    def update
      # For screen readers only: "My tables" shows the table as changed
      unless @game_table.draft?
        return redirect_to game_tables_path(table: @game_table.id), flash: { screen_reader_notice: t(".confirmed") }
      end

      @game_table.finish_creation!
      flash[:screen_reader_notice] = t(".finished")
      redirect_to joining_the_game? ? game_table_path(@game_table) : game_tables_path(table: @game_table.id)
    end

    private

    # Set by the "Finish and join the game" button
    def joining_the_game?
      params[:join_game].present?
    end
  end
end
