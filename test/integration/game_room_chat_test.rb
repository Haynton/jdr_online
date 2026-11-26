require "test_helper"

# The chat of the game room: its feed (the last lines of the table), the field to write, the messages sent by someone
# accepted at the table only, and the events the server writes in it (an item given)
class GameRoomChatTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
  end

  test "the room shows the feed of the table, its live stream and the field to write" do
    ChatMessage.post(@game_table, @player, "Bonsoir à tous")
    sign_in @game_master

    get game_table_path(@game_table)

    assert_select "#game-room-chat-feed[role=log] li", text: /Bonsoir à tous/
    assert_select "#game-room-chat-body turbo-cable-stream-source[channel=GameTableChannel]"
    assert_select "form#game-room-chat-form[action=?] textarea[name='chat_message[body]'][maxlength='1000']",
                  game_table_chat_messages_path(@game_table)
  end

  test "a player writes to the table: the line is saved and added to the page" do
    sign_in @player

    assert_difference("@game_table.chat_messages.count", 1) do
      post game_table_chat_messages_path(@game_table), params: { chat_message: { body: "J'ouvre la porte." } },
                                                       as: :turbo_stream
    end
    assert_response :ok
    assert_select "turbo-stream[action=append][target=game-room-chat-feed]", text: /J'ouvre la porte\./
    assert_select "turbo-stream[action=replace][target=game-room-chat-form] textarea[name='chat_message[body]']", text: ""
    assert_equal "joueur", @game_table.chat_messages.last.author_name
  end

  test "an empty message is refused, with its error under the field" do
    sign_in @player

    post game_table_chat_messages_path(@game_table), params: { chat_message: { body: "   " } }, as: :turbo_stream

    assert_response :unprocessable_content
    assert_select "turbo-stream[action=append]", count: 0
    assert_select "turbo-stream[target=game-room-chat-form] textarea[aria-invalid=true]"
    assert_equal 0, @game_table.chat_messages.count
  end

  test "someone who is not accepted at the table cannot write" do
    stranger = create_user("inconnu")
    invited = create_user("invite")
    @game_table.participations.create!(user: invited, role: :player, status: :pending)

    [stranger, invited].each do |user|
      sign_in user
      post game_table_chat_messages_path(@game_table), params: { chat_message: { body: "Coucou" } }, as: :turbo_stream
      assert_response :not_found
    end
    assert_equal 0, @game_table.chat_messages.count
  end

  test "an item given is written in the feed, in the language of the reader" do
    sign_in @game_master
    post game_table_item_gift_path(@game_table), params: { key: "dagger", character_id: @character.id, quantity: 3 }

    event = @game_table.chat_messages.last
    assert_equal ["event", "item_given"], [event.kind, event.event_key]

    get game_table_path(@game_table)
    assert_select "#game-room-chat-feed li", text: "Le MJ a donné 3 × « Dague » à Aria."
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end
end
