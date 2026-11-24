# The maps of a table, in a window over the step Maps (GameTables::MapDialogHelper). « Ajouter une carte » lists the
# maps of « Mes cartes » of the game master: the one chosen is copied into the table (MapTemplates::TableCopier,
# Anthony's decision: the table plays on its copy). A map copied changes its name here (its drawing in the editor);
# a map sent as an image before the editor, its name, its image and its grid. Saved in the window, the list behind is
# refreshed and the window closes; refused, the errors stay in it
module GameTables
  class GameMapsController < ApplicationController
    include TableOfGameMaster
    include MapDialogHelper
    include VariesOnTurboFrame

    before_action :set_game_map, only: %i[edit update destroy]

    def new
      @map_templates = current_user.map_templates.with_attached_picture.order(updated_at: :desc)
    end

    # Only a map of one's own (404 otherwise)
    def create
      map_template = current_user.map_templates.find(params.expect(:map_template_id))
      MapTemplates::TableCopier.new(map_template, @game_table).call
      show_list
    end

    def edit
    end

    # An image left empty keeps the one the map has
    def update
      attributes = game_map_params
      @game_map.assign_attributes(attributes[:image].blank? ? attributes.except(:image) : attributes)
      return show_list if @game_map.save

      render :edit, status: :unprocessable_content
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

    # A map copied keeps its grid and its drawing here: only its name
    def game_map_params
      permitted = @game_map.drawn? ? %i[name] : %i[name image grid_cell_size grid_visible]
      params.fetch(:game_map, {}).permit(*permitted)
    end

    # In the window: the list behind is drawn again, where it was. Opened directly: back to the list
    def show_list
      return render(turbo_stream: turbo_stream.refresh(request_id: nil)) if map_in_dialog?

      redirect_to edit_game_table_map_list_path(@game_table)
    end
  end
end
