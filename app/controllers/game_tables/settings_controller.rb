# The second step of the creation of a draft table: the settings that depend on the template chosen at the first step.
# For now the starting level of the characters, asked only when the template has levels (GameTable#asks_starting_level?)
module GameTables
  class SettingsController < ApplicationController
    include DraftTableOfGameMaster

    def edit
    end

    # Continue saves the settings and opens the next step. Its message is for screen readers only: the next step shows
    def update
      @game_table.assign_attributes(settings_params)
      return render :edit, status: :unprocessable_content unless @game_table.save

      @game_table.reach_creation_step(GameTable.next_creation_step("settings"))
      redirect_to game_table_summary_path(@game_table), flash: { screen_reader_notice: t(".saved") }
    end

    private

    # Nothing sent by a template without settings: the table keeps what it has
    def settings_params
      params.fetch(:game_table, {}).permit(:starting_level, :players_choose_level)
    end
  end
end
