# A map of a game master (« Mes cartes »), drawn in the map editor, to be copied into a table: a name, a grid of square
# cells (columns × rows) and its drawing (layout), checked by MapLayoutValidator. A table plays on its copy: changing
# the map later never touches a table
class MapTemplate < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # Same bounds as in the database: under 10 cells there is no room to move, over 60 the editor gets too small to draw
  GRID_SIZES = (10..60)
  # A new map: nothing drawn yet
  BLANK_LAYOUT = { "version" => MapLayoutValidator::CURRENT_VERSION, "floors" => {}, "edges" => {} }.freeze

  belongs_to :owner, class_name: "User", inverse_of: :map_templates

  attribute :layout, default: -> { BLANK_LAYOUT.deep_dup }

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  # The bounds given to the message: Rails would write the range as is (« 10..60 »)
  validates :columns, :rows, numericality: { only_integer: true, in: GRID_SIZES,
                                             minimum: GRID_SIZES.min, maximum: GRID_SIZES.max }
  validates_with MapLayoutValidator
end
