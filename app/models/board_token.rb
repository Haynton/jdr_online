class BoardToken < ApplicationRecord
  belongs_to :game_map
  belongs_to :character

  validates :column, :row, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :cell_inside_the_grid
  validate :cell_free
  validate :creature_of_the_table

  private

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
