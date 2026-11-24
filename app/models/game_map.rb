# A map of a table (step Maps of its creation). Either a copy of a map of « Mes cartes » (map_template, emptied if
# that one is deleted: the table keeps its copy), with the size of its grid and its drawing (layout, checked by
# MapLayoutValidator like a map of « Mes cartes »), played on a drawing or on its picture; or, sent before the editor
# existed, an image and the size of its cells in pixels of the image, shown or not. An image is a picture of the
# formats a browser shows (PNG, JPEG, WebP), 10 MB at most: stored on the disk in development, by Cloudinary in
# production
class GameMap < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # Same bounds as in the database: a cell of 10 px is hardly seen, one of 500 px holds a whole room
  GRID_CELL_SIZES = (10..500)
  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  IMAGE_MAX_SIZE = 10.megabytes

  include PlayedOnPicture

  belongs_to :game_table
  belongs_to :map_template, optional: true
  has_one_attached :image

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :grid_cell_size, numericality: { only_integer: true, in: GRID_CELL_SIZES }
  # The bounds given to the message, like a map of « Mes cartes »
  validates :columns, :rows, numericality: { only_integer: true, in: MapTemplate::GRID_SIZES,
                                             minimum: MapTemplate::GRID_SIZES.min,
                                             maximum: MapTemplate::GRID_SIZES.max }, if: :drawn?
  validates_with MapLayoutValidator, if: :drawn?
  validate :image_is_a_picture

  # A copy of a map of « Mes cartes », drawn in the editor (or played on its picture), rather than an image alone
  def drawn?
    !layout.nil?
  end

  # The map editor reads and sends the picture of a map under this name (MapTemplate#picture): here, its image
  def picture
    image
  end

  def picture=(file)
    self.image = file
  end

  # Played on its picture: the drawing says so (MapTemplate, mode "picture")
  def on_picture?
    drawn? && layout["mode"] == "picture"
  end

  private

  # Required for an image alone. A copy needs none: a map of « Mes cartes » may be played on a picture not sent yet
  def image_is_a_picture
    return errors.add(:image, :blank) if !image.attached? && !drawn?
    return unless image.attached?

    errors.add(:image, :content_type) unless IMAGE_CONTENT_TYPES.include?(image.blob.content_type)
    errors.add(:image, :too_big, count: IMAGE_MAX_SIZE / 1.megabyte) if image.blob.byte_size > IMAGE_MAX_SIZE
  end
end
