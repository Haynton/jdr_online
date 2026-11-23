# A new invitation link for a draft table, asked for from the summary: the old one stops working
# (shared by mistake, sent to the wrong person)
module GameTables
  class InviteTokensController < ApplicationController
    include TableOfGameMaster

    def update
      @game_table.regenerate_invite_token
      # The new link shows in its field: the message is for screen readers only
      redirect_to game_table_summary_path(@game_table), flash: { screen_reader_notice: t(".regenerated") }
    end
  end
end
