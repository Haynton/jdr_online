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
  has_many :board_tokens, -> { order(:id) }, dependent: :delete_all, inverse_of: :game_map
  has_one_attached :image

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :grid_cell_size, numericality: { only_integer: true, in: GRID_CELL_SIZES }
  # The bounds given to the message, like a map of « Mes cartes »
  validates :columns, :rows, numericality: { only_integer: true, in: MapTemplate::GRID_SIZES,
                                             minimum: MapTemplate::GRID_SIZES.min,
                                             maximum: MapTemplate::GRID_SIZES.max }, if: :drawn?
  validates_with MapLayoutValidator, if: :drawn?
  validate :image_is_a_picture

  after_update_commit :drop_board_tokens_outside_the_grid, if: -> { saved_change_to_columns? || saved_change_to_rows? }

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

  # For the board: the cells no token stands on, the sides no token crosses (MapPassage). Nothing on a map sent as an
  # image before the editor
  def passage
    MapPassage.new(self) if drawn?
  end

  # For the board: the tokens put in the editor, where the game begins (Anthony's decision: the board starts from
  # them). [{ character:, column:, row:, number:, hidden: }], number counting the tokens of the same character on this
  # map (« Gobelin 2 »), in the order they were put; hidden from the players unless the game master shows it
  def placed_tokens
    tokens = layout.to_h.fetch("tokens", [])
    characters = game_table.npcs.where(id: tokens.pluck("character_id")).index_by(&:id)
    numbers = Hash.new(0)
    tokens.map do |token|
      character = characters.fetch(token["character_id"])
      { character:, column: token["column"], row: token["row"], number: numbers[character.id] += 1,
        hidden: token.fetch("hidden", true) }
    end
  end

  def tokens_copied?
    tokens_copied_at.present?
  end

  def numbered_board_tokens
    tokens = board_tokens.includes(:character).to_a
    numbers = tokens.group_by(&:character_id).values.flat_map { |band| numbers_by_revelation(band) }.to_h
    tokens.map { |token| [token, numbers.fetch(token.id)] }
  end

  # A character of the table deleted: its tokens leave the maps (unchecked: only a list is shortened)
  def take_away_tokens_of(character)
    tokens = layout.to_h.fetch("tokens", [])
    kept_tokens = tokens.reject { |token| token["character_id"] == character.id }
    update_columns(layout: layout.merge("tokens" => kept_tokens)) if kept_tokens.size < tokens.size
  end

  private

  def numbers_by_revelation(band)
    revealed, never_shown = band.partition(&:revealed_at)
    ordered = revealed.sort_by { |token| [token.revealed_at, token.id] } + never_shown.sort_by(&:id)
    ordered.each_with_index.map { |token, index| [token.id, index + 1] }
  end

  def drop_board_tokens_outside_the_grid
    outside = board_tokens.where(column: columns..).or(board_tokens.where(row: rows..))
    return if outside.delete_all.zero?

    BoardTokensSender.new(game_table).call if game_table.board_game_map_id == id
  end

  # Required for an image alone. A copy needs none: a map of « Mes cartes » may be played on a picture not sent yet
  def image_is_a_picture
    return errors.add(:image, :blank) if !image.attached? && !drawn?
    return unless image.attached?

    errors.add(:image, :content_type) unless IMAGE_CONTENT_TYPES.include?(image.blob.content_type)
    errors.add(:image, :too_big, count: IMAGE_MAX_SIZE / 1.megabyte) if image.blob.byte_size > IMAGE_MAX_SIZE
  end
end
