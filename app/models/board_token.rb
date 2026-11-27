class BoardToken < ApplicationRecord
  NAME_MAX_LENGTH = 60

  belongs_to :game_map
  belongs_to :character

  normalizes :name, with: ->(name) { name.strip.presence }

  validates :name, length: { maximum: NAME_MAX_LENGTH }
  validates :column, :row, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :cell_inside_the_grid
  validate :cell_free
  validate :cell_not_blocked, on: :create
  validate :creature_of_the_table

  before_create :take_placement
  before_save :take_number_when_first_shown

  def letter
    remaining = placement
    letters = +""
    while remaining.positive?
      remaining, remainder = (remaining - 1).divmod(26)
      letters.prepend(("A".ord + remainder).chr)
    end
    letters
  end

  def shown_number
    number unless name || number.nil? || number == 1
  end

  def displayed_name
    name || character.name
  end

  private

  def take_placement
    self.placement = game_map.count_token(character_id, "placed")
  end

  def take_number_when_first_shown
    return if hidden? || number

    self.number = game_map.count_token(character_id, "revealed")
  end

  def cell_not_blocked
    return unless game_map&.drawn? && column && row

    errors.add(:base, :cell_blocked) if game_map.passage.blocked_cells.include?([column, row])
  end

  def cell_free
    return unless game_map

    taken = game_map.board_tokens.where(column:, row:).where.not(id:).exists?
    errors.add(:base, :cell_taken) if taken
  end

  def cell_inside_the_grid
    return unless game_map && column && row
    return if column < game_map.columns.to_i && row < game_map.rows.to_i

    errors.add(:base, :outside_grid)
  end

  def creature_of_the_table
    return unless game_map && character
    return if character.game_table_id == game_map.game_table_id && character.kind.in?(Character::GAME_MASTER_KINDS)

    errors.add(:character, :not_a_creature_of_the_table)
  end
end
