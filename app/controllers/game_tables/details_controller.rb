# The first step of the creation of a draft table, taken up again: name, description, cover, sheet template.
# Changing the template copies the new one into the table (at this milestone, there is nothing else to replace)
module GameTables
  class DetailsController < ApplicationController
    include DraftTableOfGameMaster
    include GameTableDetails

    before_action :set_available_sheet_templates

    def edit
    end

    def update
      @game_table.assign_attributes(game_table_details_params)
      @game_table.use_sheet_template(chosen_sheet_template)
      return render :edit, status: :unprocessable_content unless @game_table.save(context: :details)

      @game_table.reach_creation_step(GameTable.next_creation_step("details"))
      # For screen readers only: the next step shows on screen
      redirect_to edit_game_table_settings_path(@game_table), flash: { screen_reader_notice: t(".saved") }
    end
  end
end
