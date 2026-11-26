require "test_helper"
require "turbo/broadcastable/test_helper"

# The feed of a game room: messages typed at the table and events written by the server, read and written through
# ChatMessage.feed_of, .post and .record_event, each new line sent live to the table
class ChatMessageTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup do
    @user = User.create!(email: "aria@example.com", username: "aria", password: TEST_PASSWORD)
    @game_table = GameTable.create!(name: "La Crypte")
  end

  test "a message keeps its author by name and its text without the spaces around it" do
    message = ChatMessage.post(@game_table, @user, "  Bonsoir !  ")

    assert message.persisted?
    assert_equal ["message", "aria", "Bonsoir !"], [message.kind, message.author_name, message.body]
  end

  test "a message must have a text, of 1000 characters at most" do
    assert ChatMessage.post(@game_table, @user, "   ").errors.of_kind?(:body, :blank)
    assert ChatMessage.post(@game_table, @user, "a" * 1001).errors.of_kind?(:body, :too_long)
  end

  test "an event keeps its key and its values, and only a known key" do
    event = ChatMessage.record_event(@game_table, :item_given, item: "Dague", character: "Aria", count: 2)

    assert_equal ["event", "item_given"], [event.kind, event.event_key]
    assert_equal({ "item" => "Dague", "character" => "Aria", "count" => 2 }, event.event_params)
    assert_raises(ActiveRecord::RecordInvalid) { ChatMessage.record_event(@game_table, :dragon_slain) }
  end

  test "the feed of a table is its last 50 lines, the oldest first, and only its own" do
    other_table = GameTable.create!(name: "Ailleurs")
    ChatMessage.post(other_table, @user, "Pas ici")
    55.times { |index| ChatMessage.post(@game_table, @user, "Message #{index}") }

    feed = ChatMessage.feed_of(@game_table)

    assert_equal ChatMessage::FEED_SIZE, feed.size
    assert_equal ["Message 5", "Message 54"], [feed.first.body, feed.last.body]
  end

  test "each new line is sent live to the table" do
    assert_turbo_stream_broadcasts(@game_table, count: 1) do
      ChatMessage.post(@game_table, @user, "Bonsoir !")
    end
  end

  test "the line stays when the account of its author is deleted" do
    message = ChatMessage.post(@game_table, @user, "Bonsoir !")

    @user.destroy

    assert_nil message.reload.user_id
    assert_equal "aria", message.author_name
  end
end
