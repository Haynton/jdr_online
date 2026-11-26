# What the chat of the game room shows of a line of its feed (ChatMessage), and its field
module GameRoomChatHelper
  # The text of each event, written once (a key per event, never built from its name)
  CHAT_EVENT_TEXTS = {
    "item_given" => "game_rooms.chat.events.item_given", "spells_changed" => "game_rooms.chat.events.spells_changed",
    "dice_rolled" => "game_rooms.chat.events.dice_rolled",
    "dice_rolled_by_game_master" => "game_rooms.chat.events.dice_rolled_by_game_master"
  }.freeze

  # A message in a bubble, rectangular with rounded corners (decision): the others on surface-raised, the reader's own
  # in gold (primary-soft) with a fine gold contour inside, like the game master badge (without it, the dark gold
  # barely stood out from the chat). Only ink in a bubble: muted would fall under 4.5 on them
  BUBBLE_CLASSES = %w[
    max-w-[85%] rounded-xl bg-surface-raised px-3.5 py-2 text-sm break-words whitespace-pre-wrap text-ink
    group-data-own:bg-primary-soft group-data-own:ring-1 group-data-own:ring-primary-soft-ink/50
    group-data-own:ring-inset
  ].join(" ").freeze

  # An event stands out from the messages (decision): the whole width, on the page color, framed, in ink
  EVENT_CLASSES = %w[
    flex items-start gap-2 rounded-lg border border-line bg-page px-3 py-2 text-xs leading-5 text-ink
  ].join(" ").freeze

  # The number of unread lines on the folded chat, drawn like the count of the bell (side_nav_count): a gold round
  UNREAD_BADGE_CLASSES = %w[
    flex h-5 min-w-5 items-center justify-center rounded-full bg-brass px-1.5 text-[11px] font-bold text-page
    tabular-nums
  ].join(" ").freeze

  # Over the bottom of the feed, while the reader is further up and new lines came
  NEW_MESSAGES_BUTTON_CLASSES = %w[
    absolute bottom-2 left-1/2 flex -translate-x-1/2 items-center gap-1 rounded-full border border-line bg-surface
    px-3 py-1 text-xs font-semibold whitespace-nowrap text-ink shadow-md hover:bg-surface-raised
  ].join(" ").freeze

  # The look of the other fields, without their fixed height (the text area grows with its text, up to 128 px)
  FIELD_CLASSES = (
    (SimpleFormFieldClasses::INPUT.split - %w[h-10 py-1.5]) +
    %w[min-h-10 max-h-32 min-w-0 flex-1 resize-none py-[9px] leading-5]
  ).join(" ").freeze

  # A list among the values (the dice of a roll) reads « 7, 15 »
  def chat_event_text(line)
    values = line.event_params.transform_values { |value| value.is_a?(Array) ? value.join(", ") : value }
    t(CHAT_EVENT_TEXTS.fetch(line.event_key), **values.symbolize_keys)
  end

  # The name of the author, kept on the line: the line stays when the account is deleted
  def chat_author_name(line)
    line.author_name.presence || t("game_rooms.chat.former_player")
  end

  def chat_field_described_by(refused_message)
    ["game-room-chat-hint", ("game-room-chat-error" if refused_message)].compact.join(" ")
  end
end
