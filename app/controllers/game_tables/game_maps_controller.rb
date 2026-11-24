# The maps of a table. « Ajouter une carte », in a window over the step Maps (GameTables::MapDialogHelper), lists the
# maps of « Mes cartes » of the game master: the one chosen is copied into the table (MapTemplates::TableCopier,
# Anthony's decision: the table plays on its copy), or « Créer une carte » draws a new one for the table alone. A map
# copied or drawn here changes in the map editor, on its own page (its name, its drawing, its picture); a map sent as
# an image before the editor, in the window (its name, its image, its grid). Saved in the window, the list behind is
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

    # Only a map of one's own (404 otherwise). Without a map to copy, a new map drawn for the table, opened in the
    # editor at once (like « Créer une carte » of « Mes cartes »)
    def create
      return create_drawn_map unless params.key?(:map_template_id)

      map_template = current_user.map_templates.find(params.expect(:map_template_id))
      MapTemplates::TableCopier.new(map_template, @game_table).call
      show_list
    end

    def edit
      render :editor if @game_map.drawn?
    end

    # An image left empty keeps the one the map has
    def update
      attributes = game_map_params
      @game_map.assign_attributes(attributes[:image].blank? ? attributes.except(:image) : attributes)
      return show_saved_map if @game_map.save

      render (@game_map.drawn? ? :editor : :edit), status: :unprocessable_content
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

    # Of the size and the empty drawing of a new map of « Mes cartes »
    def create_drawn_map
      blank_map = MapTemplate.new
      game_map = @game_table.game_maps.create!(name: t(".default_name"), columns: blank_map.columns,
                                               rows: blank_map.rows, layout: blank_map.layout)
      redirect_to edit_game_table_game_map_path(@game_table, game_map)
    end

    # Renamed in the editor, the page comes back to it (by morphing: the drawing stays where it was)
    def show_saved_map
      return redirect_to(edit_game_table_game_map_path(@game_table, @game_map)) if @game_map.drawn?

      show_list
    end

    # In the window: the list behind is drawn again, where it was. Opened directly: back to the list
    def show_list
      return render(turbo_stream: turbo_stream.refresh(request_id: nil)) if map_in_dialog?

      redirect_to edit_game_table_map_list_path(@game_table)
    end
  end
end
