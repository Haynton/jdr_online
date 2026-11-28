class BoardToken < ApplicationRecord
  NAME_MAX_LENGTH = 60

  belongs_to :game_map
  belongs_to :character

  normalizes :name, with: ->(name) { name.strip.presence }

  validates :name, length: { maximum: NAME_MAX_LENGTH }
  validates :hidden, inclusion: { in: [true, false] }
  validates :name, absence: true, if: -> { character&.pc? }
  validates :column, :row, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :cell_inside_the_grid
  validate :cell_free
  validate :cell_not_blocked, on: :create
  validate :character_of_the_table

  before_create :take_placement, unless: -> { character.pc? }
  before_create :keep_one_token_of_a_player_character
  before_save :take_number_when_first_shown, unless: -> { character.pc? }

  def self.hidden_at_first?(character)
    !character.pc?
  end

  def letter
    remaining = placement
    letters = +""
    while remaining.positive?
      remaining, remainder = (remaining - 1).divmod(26)
      letters.prepend(("A".ord + remainder).chr)
    end
    letters
  end

  def save_on_its_cell
    save
  rescue ActiveRecord::RecordNotUnique
    errors.add(:base, :cell_taken)
    false
  end

  def shown_number
    number unless name || number.nil? || number == 1
  end

  def displayed_name
    name || character.name
  end

  # The game master moves any token; a player the token of their own character, and those of its companions
  def movable_by?(participation)
    return true if participation.game_master?

    own_character = participation.character
    return false unless own_character&.complete?

    character_id == own_character.id || (character.companion? && character.owner_character_id == own_character.id)
  end

  # Where a player's token arrives: only where a way leads, step by step, without crossing a wall nor a blocked cell
  # (MapPassage#path); on a cell held by another token (a hidden enemy they cannot see), on the last free cell of that
  # way instead (decision of 27 November: a refusal would let them probe for hidden creatures). nil when no way leads
  def arrival_for_a_player(column, row)
    start = [self.column, self.row]
    way = way_for_a_player(start, [column, row])
    return unless way

    taken = game_map.board_tokens.where.not(id:).pluck(:column, :row).to_set
    way.reverse.find { |cell| cell == start || taken.exclude?(cell) }
  end

  private

  # The cheapest way on a drawn map; straight there on a map without a drawing (nothing stops a token on it)
  def way_for_a_player(start, arrival)
    passage = game_map.passage
    passage ? passage.path(start, arrival) : [start, arrival]
  end

  def take_placement
    self.placement = game_map.take_token_placement
  end

  def keep_one_token_of_a_player_character
    return unless character.pc?

    game_map.lock!
    return unless game_map.board_tokens.exists?(character:)

    errors.add(:character, :already_on_the_map)
    throw :abort
  end

  def take_number_when_first_shown
    return if hidden? || number

    self.number = game_map.take_token_number(character_id)
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

  def character_of_the_table
    return unless game_map && character
    return if character.game_table_id == game_map.game_table_id && character.placeable_on_the_board?

    errors.add(:character, :not_a_character_of_the_table)
  end
end
