module MapTemplates
  # The drawing of a map of « Mes cartes », saved by the map editor after each stroke (SavesMapLayout). Only on a map
  # of one's own (404 otherwise)
  class LayoutsController < ApplicationController
    include SavesMapLayout

    def update
      save_map_layout(current_user.map_templates.find(params[:map_template_id]))
    end
  end
end
