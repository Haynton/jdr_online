module MapTemplates
  # The picture of a map of « Mes cartes » played on a picture of one's own (ChangesMapPicture). Only on a map of one's
  # own (404 otherwise)
  class PicturesController < ApplicationController
    include ChangesMapPicture

    before_action :set_own_map

    def create
      attach_map_picture(@map_template, edit_map_template_path(@map_template))
    end

    def destroy
      remove_map_picture(@map_template, edit_map_template_path(@map_template))
    end

    private

    def set_own_map
      @map_template = current_user.map_templates.find(params[:map_template_id])
    end
  end
end
