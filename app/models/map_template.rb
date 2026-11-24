# A map of a game master (« Mes cartes »), drawn in the map editor, to be copied into a table: a name, a grid of square
# cells (columns × rows) and its drawing (layout), checked by MapLayoutValidator. Or played on a picture of one's own
# (its layout says so, mode "picture", and how the picture sits under the grid), of the formats a browser shows, 10 MB
# at most, like the maps of a table (GameMap). A table plays on its copy: changing the map later never touches a table
class MapTemplate < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # Same bounds as in the database: under 10 cells there is no room to move, over 60 the editor gets too small to draw
  GRID_SIZES = (10..60)
  # A new map: nothing drawn yet
  BLANK_LAYOUT = {
    "version" => MapLayoutValidator::CURRENT_VERSION, "floors" => {}, "edges" => {}, "objects" => []
  }.freeze

  include PlayedOnPicture

  belongs_to :owner, class_name: "User", inverse_of: :map_templates
  has_one_attached :picture

  attribute :layout, default: -> { BLANK_LAYOUT.deep_dup }

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  # The bounds given to the message: Rails would write the range as is (« 10..60 »)
  validates :columns, :rows, numericality: { only_integer: true, in: GRID_SIZES,
                                             minimum: GRID_SIZES.min, maximum: GRID_SIZES.max }
  validates_with MapLayoutValidator
  validate :picture_is_an_image, if: -> { picture.attached? }

  # The picture laid under the grid: as wide as the grid, from its top left corner, fully seen
  def self.picture_settings_for(columns)
    { "cells_wide" => columns, "offset_x" => 0, "offset_y" => 0, "opacity" => 1 }
  end

  private

  def picture_is_an_image
    errors.add(:picture, :content_type) unless GameMap::IMAGE_CONTENT_TYPES.include?(picture.blob.content_type)
    return unless picture.blob.byte_size > GameMap::IMAGE_MAX_SIZE

    errors.add(:picture, :too_big, count: GameMap::IMAGE_MAX_SIZE / 1.megabyte)
  end
end
