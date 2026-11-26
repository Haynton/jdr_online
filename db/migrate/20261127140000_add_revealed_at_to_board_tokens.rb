class AddRevealedAtToBoardTokens < ActiveRecord::Migration[8.1]
  def up
    add_column :board_tokens, :revealed_at, :datetime
    execute "UPDATE board_tokens SET revealed_at = created_at WHERE hidden = FALSE"
  end

  def down
    remove_column :board_tokens, :revealed_at
  end
end
