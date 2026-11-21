# The first step of the creation of a draft table, taken up again: name, description, cover, sheet template.
# Changing the template copies the new one into the table (at this milestone, there is nothing else to replace)
module GameTables
  class DetailsController < ApplicationController
    include GameTableDetails

    before_action :set_draft_table
    before_action :set_available_sheet_templates

    def edit
    end

    def update
      @game_table.assign_attributes(game_table_details_params)
      @game_table.use_sheet_template(chosen_sheet_template)
      return render :edit, status: :unprocessable_content unless @game_table.save(context: :details)

      # For screen readers only: on screen, the table shows large with its new details
      redirect_to game_tables_path(table: @game_table.id), flash: { screen_reader_notice: t(".saved") }
    end

    private

    # Only the game master of a draft reaches its creation steps: anyone else gets a 404,
    # and so does a table whose creation is over
    def set_draft_table
      @game_table = current_user.participations.game_master.find_by!(game_table_id: params[:game_table_id]).game_table
      raise ActiveRecord::RecordNotFound unless @game_table.draft?
    end
  end
end
