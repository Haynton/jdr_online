require "application_system_test_case"

# The chat of the game room, live: a message written by one person shows at once in the room of the others
# (GameTableChannel), with its line breaks (Shift + Enter; Enter sends), the field is emptied and keeps the focus. Two browsers, one per person
class GameRoomChatLiveTest < ApplicationSystemTestCase
  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
  end

  test "a message of the game master shows live in the room of the player" do
    using_session(:player) { open_room_as("joueur") }
    open_room_as("maitre")

    field = find("#game-room-chat-form textarea[name='chat_message[body]']")
    field.send_keys("Un bruit sourd résonne.", %i[shift enter], "La porte grince.")
    field.send_keys(:enter)

    assert_selector "#game-room-chat-feed li[data-own]", text: "Un bruit sourd résonne.\nLa porte grince."
    assert_equal "", find("#game-room-chat-form textarea[name='chat_message[body]']").value
    assert page.evaluate_script("document.activeElement.name === 'chat_message[body]'")

    using_session(:player) do
      assert_selector "#game-room-chat-feed li:not([data-own])", text: "Un bruit sourd résonne.\nLa porte grince."
    end
  end

  test "a message that follows one of the same author shortly after shows without its header again" do
    ChatMessage.post(@game_table, @player, "Bonsoir !")
    ChatMessage.post(@game_table, @player, "Je suis prêt.")
    ChatMessage.post(@game_table, @game_master, "Commençons.")

    open_room_as("maitre")

    lines = all("#game-room-chat-feed li")
    assert_equal [false, true, false], lines.map { |line| line.matches_css?("[data-continued]") }
    assert lines.last.matches_css?("[data-own]")
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end

  # The stream is subscribed once the room is open: the line sent after it reaches this browser
  def open_room_as(username)
    visit new_user_session_path
    fill_in "user_email", with: "#{username}@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "#side-nav"
    visit game_table_path(@game_table)
    assert_selector "turbo-cable-stream-source[connected]", visible: false
  end
end
