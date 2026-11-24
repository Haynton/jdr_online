module MapTemplates
  # The drawing of a map, saved by the map editor after each stroke (map_editor_controller.js), in the background:
  # the layout comes as a JSON text, checked by the model (MapLayoutValidator), with the size of the grid when the
  # game master changed it (columns and rows: what went out of the grid is already taken out of the layout). The
  # answer says nothing on success; refused, it gives the messages. Only on a map of one's own (404 otherwise)
  class LayoutsController < ApplicationController
    def update
      map_template = current_user.map_templates.find(params[:map_template_id])
      return head(:no_content) if map_template.update(layout: sent_layout, **sent_size)

      render json: { errors: map_template.errors.full_messages }, status: :unprocessable_content
    end

    private

    def sent_size
      params.permit(:columns, :rows).to_h.symbolize_keys
    end

    # Not a hash of the parameters: a drawing holds hundreds of keys of its own ("3,4"). A text that is not JSON gives
    # nil, refused by the validator like any layout of the wrong form
    def sent_layout
      JSON.parse(params.expect(:layout))
    rescue JSON::ParserError
      nil
    end
  end
end
