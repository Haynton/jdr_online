# A line of the feed that only the game master reads (a hidden roll of dice): never sent to the players, never read
# in their feed
class AddGameMasterOnlyToChatMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_messages, :game_master_only, :boolean, default: false, null: false
  end
end
