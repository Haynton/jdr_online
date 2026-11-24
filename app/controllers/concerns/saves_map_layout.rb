# The drawing of a map saved by the map editor after each stroke (map_editor_controller.js), in the background, for a
# map of « Mes cartes » or a map copied into a table: the layout comes as a JSON text, checked by the model
# (MapLayoutValidator), with the size of the grid when the game master changed it (columns and rows: what went out of
# the grid is already taken out of the layout). The answer says nothing on success; refused, it gives the messages
module SavesMapLayout
  extend ActiveSupport::Concern

  private

  def save_map_layout(map)
    return head(:no_content) if map.update(layout: sent_layout, **sent_size)

    render json: { errors: map.errors.full_messages }, status: :unprocessable_content
  end

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
