# A map of a table (step Maps of its creation): its name, its image, and the grid the board will snap the tokens to
# (the size of a cell, in pixels of the image, and whether it shows). The image is required, a picture of the formats
# a browser shows (PNG, JPEG, WebP), 10 MB at most: stored on the disk in development, by Cloudinary in production
class GameMap < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # Same bounds as in the database: a cell of 10 px is hardly seen, one of 500 px holds a whole room
  GRID_CELL_SIZES = (10..500)
  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  IMAGE_MAX_SIZE = 10.megabytes

  belongs_to :game_table
  has_one_attached :image

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :grid_cell_size, numericality: { only_integer: true, in: GRID_CELL_SIZES }
  validate :image_is_a_picture

  private

  def image_is_a_picture
    return errors.add(:image, :blank) unless image.attached?

    errors.add(:image, :content_type) unless IMAGE_CONTENT_TYPES.include?(image.blob.content_type)
    errors.add(:image, :too_big, count: IMAGE_MAX_SIZE / 1.megabyte) if image.blob.byte_size > IMAGE_MAX_SIZE
  end
end
