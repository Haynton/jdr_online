# The first step of a table: name, description, cover, sheet template. Taken up again while the table is a draft
# (Continue: the next step), and from "Game settings" once it is ready (Save: the same page again).
# Changing the template of a draft copies the new one into the table. Once the table is ready, its template no longer
# changes (decision: the characters are made with it); a template sent anyway is ignored
module GameTables
  class DetailsController < ApplicationController
    include TableOfGameMaster
    include GameTableDetails

    before_action :set_available_sheet_templates

    def edit
    end

    def update
      @game_table.assign_attributes(game_table_details_params)
      @game_table.use_sheet_template(chosen_sheet_template) if @game_table.draft?
      return render :edit, status: :unprocessable_content unless save_details

      return redirect_to edit_game_table_details_path(@game_table), notice: t(".saved") unless @game_table.draft?

      @game_table.reach_creation_step(GameTable.next_creation_step("details"))
      # For screen readers only: the next step shows
      redirect_to edit_game_table_settings_path(@game_table), flash: { screen_reader_notice: t(".saved") }
    end

    private

    # The template is asked on a draft only: a ready table whose template was deleted since keeps its copy
    def save_details
      @game_table.draft? ? @game_table.save(context: :details) : @game_table.save
    end
  end
end
