# The fourth step of a table: its NPCs and enemies (decision: an empty list at first). Each one is a character of the
# table of kind npc or monster, added from the bestiary of its catalog (copied: Catalogs::CreatureCopier) or from
# nothing, and changed in its window (GameTables::NpcsController). Everything is saved as it is done: Continue only
# opens the next step, and reaches it on a draft
module GameTables
  class CastsController < ApplicationController
    include TableOfGameMaster

    def edit
      @npcs = @game_table.npcs
    end

    def update
      @game_table.reach_creation_step(GameTable.next_creation_step("npcs"))
      # For screen readers only: the next step shows
      redirect_to game_table_summary_path(@game_table), flash: { screen_reader_notice: t(".saved") }
    end
  end
end
