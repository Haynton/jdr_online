# The feed of the game room (decision of 26 November: one table for what everyone reads, in its order): the messages
# typed at the table and the events the server writes (an item given; later the dice, the turns, the answers of the
# AI). A message keeps its text; an event its key and its values, translated when it is shown. The author is kept by
# name (author_name): the message stays when its account is deleted (user_id emptied)
class CreateChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_messages do |t|
      t.references :game_table, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :author_name, limit: 60
      t.string :kind, null: false, default: "message"
      t.text :body
      t.string :event_key
      t.jsonb :event_params, null: false, default: {}
      t.timestamps

      t.check_constraint "kind IN ('message', 'event')", name: "chat_messages_kind_check"
      t.check_constraint "kind <> 'message' OR body IS NOT NULL", name: "chat_messages_message_body_check"
      t.check_constraint "kind <> 'event' OR event_key IS NOT NULL", name: "chat_messages_event_key_check"
    end

    # The feed of a table, read from its latest line
    add_index :chat_messages, %i[game_table_id created_at]
  end
end
