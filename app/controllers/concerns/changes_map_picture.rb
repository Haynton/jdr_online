# The picture of a map played on a picture of one's own (the tab Image of the map editor), for a map of « Mes cartes »
# or a map copied into a table: sent, it replaces the one before and the map switches to the mode "picture"
# (PlayedOnPicture); taken away, the map has none (its settings stay in its layout, for the next one). Back to the
# editor each time; a refused picture says why in a bubble (nothing else on the page does)
module ChangesMapPicture
  extend ActiveSupport::Concern

  private

  def attach_map_picture(map, editor_path)
    map.use_picture(params.expect(:picture))
    return redirect_to(editor_path) if map.save

    redirect_to editor_path, alert: map.errors.full_messages.to_sentence
  end

  def remove_map_picture(map, editor_path)
    map.picture.purge
    redirect_to editor_path
  end
end
