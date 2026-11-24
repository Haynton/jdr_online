# A map the map editor changes, of « Mes cartes » (MapTemplate) or copied into a table (GameMap), played on a picture
# of one's own: the layout switched to the mode "picture", the picture laid as wide as the grid the first time (its
# settings are kept when it is replaced). The map gives its picture under the name picture
module PlayedOnPicture
  extend ActiveSupport::Concern

  def use_picture(file)
    self.picture = file
    self.layout = layout.to_h.merge("mode" => "picture",
                                    "picture" => layout.to_h["picture"] || MapTemplate.picture_settings_for(columns))
  end
end
