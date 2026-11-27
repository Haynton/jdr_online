class AddNameToBoardTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :board_tokens, :name, :string, limit: 60
  end
end
