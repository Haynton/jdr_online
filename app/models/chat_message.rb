# A line of the feed of a game room (decision of 26 November: one table for what the table reads, in its order). A
# message is typed by someone at the table; an event is written by the server when something happens (an item given),
# kept as a key and its values and translated when it is shown, so that each reader sees it in their language. The
# feed is only read and written through feed_of and record_event: if the AI calls get their own table one day
# (ai_requests), nothing else changes. Each new line is sent live to the table (GameTableChannel); a line for the
# game master only (a hidden roll of dice) goes to the stream of the game master, and is never read by a player
class ChatMessage < ApplicationRecord
  KINDS = %w[message event].freeze
  BODY_MAX_LENGTH = 1000
  FEED_SIZE = 50
  EVENT_KEYS = %w[
    item_given money_given spells_changed dice_rolled dice_rolled_by_game_master initiative_rolled
    death_save_success death_save_failure death_save_critical_failure death_save_revived death_save_stable
    death_save_dead death_save_hit resource_used resource_pool_used spell_slot_spent hit_die_spent
    weapon_masteries_changed level_granted level_reached level_reached_rolled
  ].freeze
  FEED_TARGET = "game-room-chat-feed".freeze

  belongs_to :game_table
  belongs_to :user, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :body, presence: true, length: { maximum: BODY_MAX_LENGTH }, if: :message?
  validates :event_key, inclusion: { in: EVENT_KEYS }, if: :event?

  normalizes :body, with: lambda(&:strip)

  after_create_commit :send_to_table

  # The last lines of the feed of a table, the oldest first (the order in which they are read)
  def self.feed_of(game_table, game_master: false)
    lines = game_table.chat_messages
    lines = lines.where(game_master_only: false) unless game_master
    lines.order(created_at: :desc, id: :desc).limit(FEED_SIZE).includes(:user).reverse
  end

  def self.post(game_table, user, body)
    game_table.chat_messages.create(kind: "message", user: user, author_name: user.username, body: body)
  end

  # The initiatives rolled at the table, the oldest first: [id of the character, total] (CombatStrip)
  def self.initiative_rolls_of(game_table)
    game_table.chat_messages.where(event_key: "initiative_rolled").order(:created_at, :id).pluck(:event_params)
              .filter_map { |values| values.values_at("character_id", "total") if values["character_id"] }
  end

  def self.record_event(game_table, event_key, game_master_only: false, **event_params)
    game_table.chat_messages.create!(kind: "event", event_key: event_key.to_s, event_params: event_params,
                                     game_master_only: game_master_only)
  end

  def message?
    kind == "message"
  end

  def event?
    kind == "event"
  end

  private

  def send_to_table
    Turbo::StreamsChannel.broadcast_append_to(*audience, target: FEED_TARGET,
                                                         partial: "game_rooms/chat_line", locals: { line: self })
  end

  def audience
    game_master_only? ? [game_table, GameTableChannel::GAME_MASTER_AUDIENCE] : [game_table]
  end
end
