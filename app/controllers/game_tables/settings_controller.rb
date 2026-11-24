# The second step of a table: the settings that depend on the template chosen at the first step: the starting level
# of the characters, asked only when the template has levels (GameTable#asks_starting_level?), and the ways to play
# the rules the template offers (TableRules: the scores of the abilities, the hit points of the next levels).
# On a draft, Continue opens the next step; on a table ready (its "Game settings"), Save shows the same page again
module GameTables
  class SettingsController < ApplicationController
    include TableOfGameMaster

    def edit
    end

    # On a draft, its message is for screen readers only: the next step shows. On a table ready, it floats: nothing
    # else says the settings were saved
    def update
      @game_table.assign_attributes(settings_params)
      return render :edit, status: :unprocessable_content unless @game_table.save
      return redirect_to edit_game_table_settings_path(@game_table), notice: t(".saved") unless @game_table.draft?

      @game_table.reach_creation_step(GameTable.next_creation_step("settings"))
      redirect_to edit_game_table_catalog_path(@game_table), flash: { screen_reader_notice: t(".saved") }
    end

    private

    # Nothing sent by a template without settings: the table keeps what it has
    def settings_params
      params.fetch(:game_table, {}).permit(:starting_level, :players_choose_level, :ability_method_choice,
                                           :hit_point_method_choice)
    end
  end
end
