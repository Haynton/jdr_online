# The steps of the creation of a table (app/controllers/game_tables/) work on a draft of the current user.
# Only its game master reaches them: anyone else gets a 404, and so does a table whose creation is over
module DraftTableOfGameMaster
  extend ActiveSupport::Concern

  included do
    before_action :set_draft_table
  end

  private

  def set_draft_table
    @game_table = current_user.participations.game_master.find_by!(game_table_id: params[:game_table_id]).game_table
    raise ActiveRecord::RecordNotFound unless @game_table.draft?
  end
end
