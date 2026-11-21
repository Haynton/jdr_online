# First step of the creation of a table: the table and the game master participation of its creator are saved
# together (both, or neither). The creator of a table is its game master; there is no creator column.
# Returns the table: persisted, or with its errors for the form
class GameTableCreator
  def initialize(user:, attributes:, sheet_template:)
    @user = user
    @attributes = attributes
    @sheet_template = sheet_template
  end

  def call
    game_table = GameTable.new(@attributes)
    game_table.use_sheet_template(@sheet_template)

    ActiveRecord::Base.transaction do
      game_table.save!(context: :details)
      game_table.participations.create!(user: @user, role: :game_master)
    end
    game_table
  rescue ActiveRecord::RecordInvalid
    game_table
  end
end
