# What the chat of the game room shows of a line of its feed (ChatMessage)
module GameRoomChatHelper
  # The text of each event, written once (a key per event, never built from its name)
  CHAT_EVENT_TEXTS = { "item_given" => "game_rooms.chat.events.item_given" }.freeze

  def chat_event_text(line)
    t(CHAT_EVENT_TEXTS.fetch(line.event_key), **line.event_params.symbolize_keys)
  end

  # The name of the author, kept on the line: the line stays when the account is deleted
  def chat_author_name(line)
    line.author_name.presence || t("game_rooms.chat.former_player")
  end
end
