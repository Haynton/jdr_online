# One map of a table, in a window over the step Maps (GameTables::MapDialogHelper): its name, its image, its grid.
# Saved in the window, the list behind is refreshed and the window closes; refused, the errors stay in it (an image
# chosen is to be chosen again: a browser never fills a file field back)
module GameTables
  class GameMapsController < ApplicationController
    include TableOfGameMaster
    include MapDialogHelper
    include VariesOnTurboFrame

    before_action :set_game_map, only: %i[edit update destroy]

    def new
      @game_map = @game_table.game_maps.build
    end

    def create
      @game_map = @game_table.game_maps.build
      save_game_map(:new)
    end

    def edit
    end

    def update
      save_game_map(:edit)
    end

    def destroy
      @game_map.destroy!
      show_list
    end

    private

    # Only the maps of the table
    def set_game_map
      @game_map = @game_table.game_maps.find(params[:id])
    end

    # An image left empty while changing a map keeps the one it has
    def save_game_map(form_action)
      attributes = game_map_params
      @game_map.assign_attributes(attributes[:image].blank? ? attributes.except(:image) : attributes)
      return show_list if @game_map.save

      render form_action, status: :unprocessable_content
    end

    def game_map_params
      params.fetch(:game_map, {}).permit(:name, :image, :grid_cell_size, :grid_visible)
    end

    # In the window: the list behind is drawn again, where it was. Opened directly: back to the list
    def show_list
      return render(turbo_stream: turbo_stream.refresh(request_id: nil)) if map_in_dialog?

      redirect_to edit_game_table_map_list_path(@game_table)
    end
  end
end
