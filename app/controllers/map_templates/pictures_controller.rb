module MapTemplates
  # The picture of a map played on a picture of one's own (the tab Image of the map editor): sent, it replaces the one
  # before and the map switches to the mode "picture" (MapTemplate#use_picture); taken away, the map has none (its
  # settings stay in its layout, for the next one). Back to the editor each time; a refused picture says why in a
  # bubble (nothing else on the page does). Only on a map of one's own (404 otherwise)
  class PicturesController < ApplicationController
    before_action :set_own_map

    def create
      @map_template.use_picture(params.expect(map_template: [:picture])[:picture])
      return redirect_to edit_map_template_path(@map_template) if @map_template.save

      redirect_to edit_map_template_path(@map_template), alert: @map_template.errors.full_messages.to_sentence
    end

    def destroy
      @map_template.picture.purge
      redirect_to edit_map_template_path(@map_template)
    end

    private

    def set_own_map
      @map_template = current_user.map_templates.find(params[:map_template_id])
    end
  end
end
