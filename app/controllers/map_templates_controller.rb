# The maps of a game master (« Mes cartes »): the list, a new map in one click, then its page, the map editor, where it
# is renamed, resized, drawn and deleted. Only the owner sees, changes or deletes a map: 404 for anyone else
class MapTemplatesController < ApplicationController
  before_action :set_own_map, only: %i[edit update destroy]

  def index
    @map_templates = current_user.map_templates.order(:name)
  end

  # « Créer une carte » opens the editor at once (Anthony's request): a map named « Nouvelle carte », of the default
  # size, renamed and resized in the bar of the editor. The page of the new map shows it: the message is for screen
  # readers only
  def create
    map_template = current_user.map_templates.create!(name: t(".default_name"))
    redirect_to edit_map_template_path(map_template),
                flash: { screen_reader_notice: t(".created", name: map_template.name) }
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

  def name_params
    params.expect(map_template: [:name])
  end
end
