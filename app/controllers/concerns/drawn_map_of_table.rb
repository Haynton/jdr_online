# The editor of a map copied into a table works on a map of the table of the game master (TableOfGameMaster), and only
# on a copy of a map of « Mes cartes » (a map sent as an image before the editor has no drawing): 404 otherwise
module DrawnMapOfTable
  extend ActiveSupport::Concern

  included do
    include TableOfGameMaster

    before_action :set_drawn_map
  end

  private

  def set_drawn_map
    @game_map = @game_table.game_maps.where.not(layout: nil).find(params[:game_map_id] || params[:id])
  end
end
