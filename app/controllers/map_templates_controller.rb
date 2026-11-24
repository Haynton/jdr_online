# The maps of a game master (« Mes cartes »): the list, a new map (its name and the size of its grid), then its page,
# where it is renamed, drawn (the map editor) and deleted. Only the owner sees, changes or deletes a map: 404 for anyone
# else. The size of the grid is chosen at the creation only: the cells drawn outside a smaller grid would be lost
class MapTemplatesController < ApplicationController
  before_action :set_own_map, only: %i[edit update destroy]

  def index
    @map_templates = current_user.map_templates.order(:name)
  end

  # Not built from current_user.map_templates: the unsaved map would stay in the list of the user
  def new
    @map_template = MapTemplate.new
  end

  # « Créer une carte » opens the editor at once (Anthony's request): a map named « Nouvelle carte », of the default
  # size, renamed and resized in the bar of the editor. A name or a size sent (the form of the page new) are taken.
  # The page of the new map shows it: the message is for screen readers only
  def create
    @map_template = current_user.map_templates.new(name: t(".default_name"), **creation_params)
    return render(:new, status: :unprocessable_content) unless @map_template.save

    redirect_to edit_map_template_path(@map_template),
                flash: { screen_reader_notice: t(".created", name: @map_template.name) }
  end

  def edit
  end

  # The field already shows what was saved: the message is for screen readers only
  def update
    if @map_template.update(name_params)
      return redirect_to(edit_map_template_path(@map_template), flash: { screen_reader_notice: t(".renamed") })
    end

    render :edit, status: :unprocessable_content
  end

  # The list no longer shows it: the message is for screen readers only
  def destroy
    @map_template.destroy!
    redirect_to map_templates_path, flash: { screen_reader_notice: t(".deleted", name: @map_template.name) }
  end

  private

  def set_own_map
    @map_template = current_user.map_templates.find(params[:id])
  end

  def creation_params
    params.fetch(:map_template, {}).permit(:name, :columns, :rows).to_h.symbolize_keys
  end

  def name_params
    params.expect(map_template: [:name])
  end
end
