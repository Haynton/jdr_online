# A new invitation link for a draft table, asked for from the summary: the old one stops working
# (shared by mistake, sent to the wrong person)
module GameTables
  class InviteTokensController < ApplicationController
    include DraftTableOfGameMaster

    def update
      @game_table.regenerate_invite_token
      redirect_to game_table_summary_path(@game_table), notice: t(".regenerated")
    end
  end
end
